#!/usr/bin/env python3

from cgi import parse_qs
import os
import sys
import mysql.connector
import json
import socket
from datetime import datetime

path = os.path.dirname(__file__)
if path not in sys.path:
   sys.path.insert(0, path)

argo_home = ""

from send import *
# from send_statistics import statistics_year

# import send_statistics
# from importlib import reload
# reload(send_statistics)

# argo_user = os.getenv('ARGO_USER')
# argo_pass = os.getenv('ARGO_PASS')
# argo_base = os.getenv('ARGO_BASE')

# argodb = mysql.connector.connect(
#   host="localhost",
#   user=argo_user,
#   password=argo_pass,
#   database=argo_base
# )
# argodb = mysql.connector.connect(
#   host="localhost",
#   user='argouser',
#   password='argopassword',
#   database='argodb'
# )

def get_db_timestamp(mydb, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    mycursor.execute('SELECT DATE_FORMAT(current_timestamp(6), \'%Y-%m-%d-%H.%i.%s.%f\') AS ts_mysql')
    myresult = mycursor.fetchall()
    response_dict['db.timestamp'] = myresult[0][0]
    mydb.commit()
    mydb.close()


def list_db_tables(mydb, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    mycursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = %s", ('argodb',))
    response_dict['db.tables'] = [row[0] for row in mycursor.fetchall()]
    mydb.commit()
    mydb.close()

def dump_date(thing):
    if isinstance(thing, datetime):
        return thing.isoformat()
    return str(thing)

# def send_notification(response_dict):
#     token_hex = '67833776a59441dbe80af454c153b2bc84345babe2baa7960140001d08e104c2'
#
#     async def run():
#         apns_cert_client = APNs(
#             client_cert='/etc/ssl/Certificates.pem',
#             use_sandbox=True,
#         )
#         # apns_key_client = APNs(
#         #     key='AuthKey_8J93N9S525.p8',
#         #     key_id='8J93N9S525',
#         #     team_id='8FRM8M93L5',
#         #     topic='site.aleksa.forFun',  # Bundle ID
#         #     use_sandbox=True,
#         # )
#         request = NotificationRequest(
#             device_token=token_hex,
#             message={
#                 "aps": {"alert": "Hello from forFun"
#                     , "sound": "default"
#                     , "badge": "1"
#                 }
#             },
#             # notification_id=str(uuid4()),  # optional
#             # time_to_live=3,                # optional
#             # push_type=PushType.ALERT,      # optional
#         )
#         await apns_cert_client.send_notification(request)
#         # await apns_key_client.send_notification(request)
#
#     loop = asyncio.get_event_loop()
#     loop.run_until_complete(run())
#
#
#
#     response_dict['wnotification'] = 'Sent'
#     return response_dict

def is_email_exists(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]
        mydb.connect()
        mycursor = mydb.cursor()
        mycursor.execute("SELECT uid FROM email WHERE email = '%s'" % (email))
        res = mycursor.fetchall()
        if res == []:
            response_dict['user'] = {'no' : 'no'}
        else:
            uid = res[0][0]
            response_dict['user'] = {'uid' : uid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['user'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def add_user(mydb, query_dict, response_dict):
    try:
        nick = query_dict['nick'][0]
        email = query_dict['email'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("INSERT INTO user (nick) VALUE ('%s')" % nick)
        mycursor.execute("SELECT LAST_INSERT_ID()")

        uid = mycursor.fetchone()[0]
        mycursor.execute("INSERT INTO email (uid, email, send) VALUES (%s, '%s', 0)" % (uid, email))

        mydb.commit()
        response_dict['new_user'] = {'email': email, 'nick': nick, 'uid': uid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['new_user'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_tid_tnick(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT nick, tid FROM transport WHERE uid = (SELECT uid FROM email WHERE email = '%s') ORDER BY nick" % (email))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['tid_nick'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['tid_nick'] = [{'server_error' : 1, 'err_code' : err_code}]
    finally:
        mydb.close()

    return response_dict

def get_transp(mydb, query_dict, response_dict):
    try:
        tid = int(query_dict['tid'][0])

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT * FROM transport WHERE tid = %d" % (tid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_transp'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_transp'] = [{'server_error' : 1, 'err_code' : err_code}]
    finally:
        mydb.close()

    return response_dict

def update_transp_info(mydb, query_dict, response_dict):
    try:
        tid = int(query_dict['tid'][0])
        resp = {'tid': tid}

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("UPDATE transport SET nick = '%s' WHERE tid = %d" % (query_dict['nick'][0], tid))
        resp['nick'] = query_dict['nick'][0]

        if 'producted' in query_dict:
            mycursor.execute("UPDATE transport SET producted = %s WHERE tid = %d" % (query_dict['producted'][0], tid))
            resp['producted'] = query_dict['producted'][0]
        else:
            mycursor.execute("UPDATE transport SET producted = NULL")
        if 'diag_date' in query_dict:
            mycursor.execute("UPDATE transport SET diag_date = '%s' WHERE tid = %d" % (query_dict['diag_date'][0], tid))
            mycursor.execute("DELETE FROM notification WHERE mode = 1 AND tid = %s" % (tid))
            resp['diag_date'] = query_dict['diag_date'][0]
        if 'osago_date' in query_dict:
            mycursor.execute("UPDATE transport SET osago_date = '%s' WHERE tid = %d" % (query_dict['osago_date'][0], tid))
            mycursor.execute("DELETE FROM notification WHERE mode = 2 AND tid = %s" % (tid))
            resp['osago_date'] = query_dict['osago_date'][0]

        mydb.commit()
        response_dict['update_transp_info'] = resp
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['update_transp_info'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def add_transp(mydb, query_dict, response_dict):
    email = query_dict['email'][0]
    nick = query_dict['nick'][0]

    mydb.connect()
    mycursor = mydb.cursor()

    try:
        mycursor.execute("INSERT INTO transport (uid, nick) SELECT uid, '%s' from email WHERE email = '%s'" % (nick, email))
        mycursor.execute("SELECT LAST_INSERT_ID()")

        tid = mycursor.fetchone()[0]

        resp = {'tid': tid, 'nick' : nick, 'email' : email}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_transp'] = {'server_error': 1, 'err_code': err_code}
        mydb.close()
        return response_dict

    try:
        now = datetime.now()
        date_string = now.strftime('%Y-%m-%d %H:%M:%S')

        total_fuel = 0
        mycursor.execute("UPDATE transport SET total_fuel = %s WHERE tid = %d" % (total_fuel, tid))
        mycursor.execute("UPDATE transport SET fuel_date = '%s' WHERE tid = %d" % (date_string, tid))

        if 'producted' in query_dict:
            mycursor.execute("UPDATE transport SET producted = %s WHERE tid = %d" % (query_dict['producted'][0], tid))
            resp['producted'] = query_dict['producted'][0]
        if 'mileage' in query_dict:
            mycursor.execute("UPDATE transport SET mileage = %s WHERE tid = %d" % (query_dict['mileage'][0], tid))
            try:
                mycursor.execute("INSERT INTO mileage (tid, date, mileage) VALUES (%s, '%s', %s)" % (tid, date_string, query_dict['mileage'][0]))
            except mysql.connector.Error as error:
                err_code = int(str(error).split()[0])
                resp['mileage'] = {'server_error' : 1, 'err_code' : err_code}
            resp['mileage'] = {'mileage' : query_dict['mileage'][0]}
        if 'eng_hour' in query_dict:
            mycursor.execute("UPDATE transport SET eng_hour = %s WHERE tid = %d" % (query_dict['eng_hour'][0], tid))
            try:
                mycursor.execute("INSERT INTO eng_hour (tid, date, eng_hour) VALUES (%s, '%s', %s)" % (tid, date_string, query_dict['eng_hour'][0]))
            except mysql.connector.Error as error:
                err_code = int(str(error).split()[0])
                resp['eng_hour'] = {'server_error' : 1, 'err_code' : err_code}
            resp['eng_hour'] = query_dict['eng_hour'][0]
        if 'diag_date' in query_dict:
            mycursor.execute("UPDATE transport SET diag_date = '%s' WHERE tid = %d" % (query_dict['diag_date'][0], tid))
            diag_date = query_dict['diag_date'][0]
            resp['diag_date'] = diag_date
        if 'osago_date' in query_dict:
            mycursor.execute("UPDATE transport SET osago_date = '%s' WHERE tid = %d" % (query_dict['osago_date'][0], tid))
            osago_date = query_dict['osago_date'][0]
            resp['osago_date'] = osago_date
        mydb.commit()
        response_dict['add_transp'] = resp
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_transp'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def delete_transp(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM transport WHERE tid = %s" % (tid))
        mydb.commit()
        response_dict['delete_transp'] = {'deleted_transp' : tid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_transp'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

def get_user_info(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT e.*, u.nick FROM email AS e LEFT JOIN user AS u ON e.uid = u.uid WHERE e.email = '%s'" % (email))

        columns = [desc[0] for desc in mycursor.description]
        response_dict['get_user_info'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_user_info'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def update_user_info(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]
        nick = query_dict['nick'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("UPDATE user SET nick = '%s' WHERE uid = (SELECT uid FROM email WHERE email = '%s')" % (nick, email))

        mydb.commit()

        response_dict['update_user_info'] = {'nick': nick}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['update_user_info'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_email(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]

        mydb.connect()
        mycursor = mydb.cursor()
        mycursor.execute("SELECT * FROM email WHERE uid = (SELECT uid FROM email WHERE email = '%s')" % (email))

        columns = [desc[0] for desc in mycursor.description]
        response_dict['get_email'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_email'] = [{'server_error' : 1, 'err_code' : err_code}]
    finally:
        mydb.close()

    return response_dict

def add_email(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]
        new_email = query_dict['new_email'][0]
        send = '0'
        resp = dict()

        mydb.connect()
        mycursor = mydb.cursor()


        mycursor.execute("INSERT INTO email(uid, email, send) SELECT uid, '%s', %s FROM email WHERE email = '%s'" % (new_email, send, email))

        mycursor.execute("SELECT LAST_INSERT_ID()")
        eid = mycursor.fetchone()[0]

        resp['eid'] = eid
        resp['email'] = email
        resp['new_email'] = new_email
        resp['send'] = 0

        mydb.commit()

        response_dict['add_email'] = resp
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_email'] = {'server_error' : 1, 'err_code' : err_code}
    finally:
        mydb.close()

    return response_dict

def delete_email(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM email WHERE email = '%s'" % (email))

        mydb.commit()
        response_dict['delete_email'] = {'deleted_email': email}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_email'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def change_email_send(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]
        send = query_dict['send'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("UPDATE email SET send = %s WHERE email = '%s'" % (send, email))

        mydb.commit()

        response_dict['change_email_send'] = {'done' : 'a'}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['change_email_send'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict
















def get_mileage(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT * FROM mileage WHERE tid = %s ORDER BY date DESC" % (tid))

        columns = [desc[0] for desc in mycursor.description]
        response_dict['get_mileage'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_mileage'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def add_mileage(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]
        date = query_dict['date'][0]
        mileage = query_dict['mileage'][0]

        mydb.connect()
        mycursor = mydb.cursor()
        mycursor.execute("INSERT INTO mileage (tid, date, mileage) SELECT %s, '%s', %s FROM DUAL WHERE NOT EXISTS (SELECT * FROM mileage WHERE tid = %s AND ('%s' > date AND %s < mileage OR '%s' < date AND %s > mileage OR '%s' = date AND %s = mileage))" % (tid, date, mileage, tid, date, mileage, date, mileage, date, mileage))
        affected_rows = mycursor.rowcount

        if affected_rows == 0:
            response_dict['add_mileage'] = {'row' : affected_rows}
        else:
            mycursor.execute("SELECT LAST_INSERT_ID()")
            mid = mycursor.fetchone()[0]
            mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))
            mydb.commit()
            response_dict['add_mileage'] = {'row': affected_rows, 'mid': mid, 'mileage': int(mileage)}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_mileage'] = {'server_error' : 1, 'err_code' : err_code, 'row' : 0}
    finally:
        mydb.close()

    return response_dict

def delete_mileage(mydb, query_dict, response_dict):
    try:
        mid = query_dict['mid'][0]
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM mileage WHERE mid = %s" % (mid))
        mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))

        mydb.commit()
        response_dict['delete_mileage'] = {'deleted_mid': mid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_mileage'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_eng_hour(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT * FROM eng_hour WHERE tid = %s ORDER BY date DESC" % (tid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_eng_hour'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_eng_hour'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def add_eng_hour(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]
        date = query_dict['date'][0]
        eng_hour = query_dict['eng_hour'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("INSERT INTO eng_hour (tid, date, eng_hour) SELECT %s, '%s', %s FROM DUAL WHERE NOT EXISTS (SELECT * FROM eng_hour WHERE tid = %s AND ('%s' > date AND %s < eng_hour OR '%s' < date AND %s > eng_hour OR '%s' = date AND %s = eng_hour))" % (tid, date, eng_hour, tid, date, eng_hour, date, eng_hour, date, eng_hour))
        affected_rows = mycursor.rowcount

        if affected_rows == 0:
            response_dict['add_eng_hour'] = {'row' : affected_rows}
        else:
            mycursor.execute("SELECT LAST_INSERT_ID()")
            ehid = mycursor.fetchone()[0]
            mycursor.execute("UPDATE transport SET eng_hour = (SELECT MAX(eng_hour) FROM eng_hour WHERE tid = %s) WHERE tid = %s" % (tid, tid))
            mydb.commit()
            response_dict['add_eng_hour'] = {'row': affected_rows, 'ehid': ehid, 'eng_hour': int(eng_hour)}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_eng_hour'] = {'server_error' : 1, 'err_code' : err_code, 'row' : 0}
    finally:
        mydb.close()

    return response_dict

def delete_eng_hour(mydb, query_dict, response_dict):
    try:
        ehid = query_dict['ehid'][0]
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM eng_hour WHERE ehid = %s" % (ehid))
        mycursor.execute("UPDATE transport SET eng_hour = (SELECT MAX(eng_hour) FROM eng_hour WHERE tid = %s) WHERE tid = %s" % (tid, tid))

        mydb.commit()
        response_dict['delete_eng_hour'] = {'deleted_ehid': ehid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_eng_hour'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_fuel(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT f.*, m.mileage FROM fuel AS f LEFT JOIN mileage as m ON f.date = m.date WHERE f.tid = %s ORDER BY date DESC" % (tid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_fuel'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_fuel'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def add_fuel(mydb, query_dict, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    resp = dict()
    global fid

    try:
        tid = query_dict['tid'][0]
        date = query_dict['date'][0]
        mileage = query_dict['mileage'][0]
        fuel = query_dict['fuel'][0]

        mycursor.execute("INSERT INTO mileage (tid, date, mileage) SELECT %s, '%s', %s FROM DUAL WHERE NOT EXISTS (SELECT * FROM mileage WHERE tid = %s AND ('%s' > date AND %s < mileage OR '%s' < date AND %s > mileage OR '%s' = date AND %s = mileage))" % (tid, date, mileage, tid, date, mileage, date, mileage, date, mileage))
        affected_rows = mycursor.rowcount


        if affected_rows == 0:
            response_dict['add_fuel'] = {'row': affected_rows, 'mileage_inserted' : 0}
        else:
            print(tid, date, fuel)
            mycursor.execute("INSERT INTO fuel (tid, date, fuel) VALUES (%s, '%s', %s)" % (tid, date, fuel))
            affected_rows = mycursor.rowcount

            if affected_rows == 0:
                response_dict['add_fuel'] = {'row' : affected_rows}
            else:
                mycursor.execute("SELECT LAST_INSERT_ID()")
                fid = mycursor.fetchone()[0]

                mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))
                mycursor.execute("UPDATE transport AS t SET total_fuel = (SELECT SUM(fuel) FROM fuel WHERE tid = %s AND date >= t.fuel_date ) WHERE tid = %s" % (tid, tid))

                resp['fid'] = fid
                resp['date'] = date
                resp['mileage'] = int(mileage)
                resp['fuel'] = float(fuel)
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_fuel'] = {'server_error': 1, 'err_code': err_code}
        mydb.close()
        return response_dict

    try:
        if 'fill_brand' in query_dict:
            mycursor.execute("UPDATE fuel SET fill_brand = '%s' WHERE fid = %s" % (query_dict['fill_brand'][0], fid))
            resp['fill_brand'] = query_dict['fill_brand'][0]
        if 'fuel_brand' in query_dict:
            mycursor.execute("UPDATE fuel SET fuel_brand = '%s' WHERE fid = %s" % (query_dict['fuel_brand'][0], fid))
            resp['fuel_brand'] = query_dict['fuel_brand'][0]
        if 'fuel_cost' in query_dict:
            mycursor.execute("UPDATE fuel SET fuel_cost = %s WHERE fid = %s" % (query_dict['fuel_cost'][0], fid))
            resp['fuel_cost'] = float(query_dict['fuel_cost'][0])
        mydb.commit()
        response_dict['add_fuel'] = resp
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_fuel'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def delete_fuel(mydb, query_dict, response_dict):
    try:
        fid = query_dict['fid'][0]
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM mileage WHERE tid = %s AND date = (SELECT date FROM fuel WHERE fid = %s)" % (tid, fid))
        mycursor.execute("DELETE FROM fuel WHERE fid = %s" % (fid))
        mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))
        mycursor.execute("UPDATE transport AS t SET total_fuel = (SELECT SUM(fuel) FROM fuel WHERE tid = %s AND date >= t.fuel_date ) WHERE tid = %s" % (tid, tid))

        mydb.commit()
        response_dict['delete_fuel'] = {'deleted_fid': fid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_fuel'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_service(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT s.*, m.mileage FROM service AS s LEFT JOIN mileage as m ON s.date = m.date WHERE s.tid = %s ORDER BY date DESC" % (tid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_service'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_service'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def add_service(mydb, query_dict, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    resp = dict()

    try:
        tid = query_dict['tid'][0]
        date = query_dict['date'][0]
        ser_type = query_dict['ser_type'][0]
        mileage = query_dict['mileage'][0]

        mycursor.execute("INSERT INTO mileage (tid, date, mileage) SELECT %s, '%s', %s FROM DUAL WHERE NOT EXISTS (SELECT * FROM mileage WHERE tid = %s AND ('%s' > date AND %s < mileage OR '%s' < date AND %s > mileage OR '%s' = date AND %s = mileage))" % (tid, date, mileage, tid, date, mileage, date, mileage, date, mileage))
        affected_rows = mycursor.rowcount

        if affected_rows == 0:
            response_dict['add_service'] = {'row': affected_rows, 'mileage_inserted': 0}
        else:
            mycursor.execute("INSERT INTO service (tid, date, ser_type) VALUES (%s, '%s', '%s')" % (tid, date, ser_type))
            affected_rows = mycursor.rowcount

            if affected_rows == 0:
                response_dict['add_service'] = {'row': affected_rows, 'service_inserted': 0}
            else:
                mycursor.execute("SELECT LAST_INSERT_ID()")
                sid = mycursor.fetchone()[0]
                mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))

                resp['sid'] = sid
                resp['date'] = date
                resp['ser_type'] = ser_type
                resp['mileage'] = int(mileage)
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_service'] = {'server_error': 1, 'err_code': err_code}
        mydb.close()
        return response_dict
    try:
        if 'mat_cost' in query_dict:
            mycursor.execute("UPDATE service SET mat_cost = %s WHERE sid = %s" % (query_dict['mat_cost'][0], sid))
            resp['mat_cost'] = float(query_dict['mat_cost'][0])
        if 'wrk_cost' in query_dict:
            mycursor.execute("UPDATE service SET wrk_cost = %s WHERE sid = %s" % (query_dict['wrk_cost'][0], sid))
            resp['wrk_cost'] = float(query_dict['wrk_cost'][0])
        mydb.commit()
        response_dict['add_service'] = resp
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_service'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def delete_service(mydb, query_dict, response_dict):
    try:
        sid = query_dict['sid'][0]
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM mileage WHERE tid = %s AND date = (SELECT date FROM service WHERE sid = %s)" % (tid, sid))
        mycursor.execute("DELETE FROM service WHERE sid = %s" % (sid))
        mycursor.execute("UPDATE transport SET mileage = (SELECT MAX(mileage) FROM mileage WHERE tid = %s) WHERE tid = %s" % (tid, tid))

        mydb.commit()
        response_dict['delete_service'] = {'deleted_sid': sid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_service'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_service_info(mydb, query_dict, response_dict):
    try:
        sid = query_dict['sid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT s.*, m.mileage "
                         "FROM service AS s "
                         "LEFT JOIN mileage AS m "
                         "ON s.date = m.date AND s.tid = m.tid "
                         "WHERE sid = %s" % (sid))

        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_service_info'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_service_info'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def get_material(mydb, query_dict, response_dict):
    try:
        sid = query_dict['sid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT * FROM material WHERE sid = %s" % (sid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_material'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_material'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def add_material(mydb, query_dict, response_dict):
    mydb.connect()
    mycursor = mydb.cursor()
    resp = dict()
    try:
        sid = query_dict['sid'][0]
        mat_info = query_dict['mat_info'][0]
        wrk_type = query_dict['wrk_type'][0]

        resp['mat_info'] = mat_info
        resp['wrk_type'] = wrk_type

        mycursor.execute("INSERT INTO material (sid, mat_info, wrk_type) VALUES (%s, '%s', '%s')" % (sid, mat_info, wrk_type))
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_material'] = {'server_error': 1, 'err_code': err_code}
        mydb.close()
        return response_dict

    try:
        mycursor.execute("SELECT LAST_INSERT_ID()")
        maid = mycursor.fetchone()[0]
        resp['maid'] = maid
        if 'mat_cost' in query_dict:
            mycursor.execute("UPDATE material SET mat_cost = %s WHERE maid = %s" % (query_dict['mat_cost'][0], maid))
            resp['mat_cost'] = float(query_dict['mat_cost'][0])
        if 'wrk_cost' in query_dict:
            mycursor.execute("UPDATE material SET wrk_cost = %s WHERE maid = %s" % (query_dict['wrk_cost'][0], maid))
            resp['wrk_cost'] = float(query_dict['wrk_cost'][0])
        mydb.commit()
        response_dict['add_material'] = resp
    except mysql.connector.Error as error:
        print(error)
        err_code = int(str(error).split()[0])
        response_dict['add_material'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def delete_material(mydb, query_dict, response_dict):
    try:
        maid = query_dict['maid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM material WHERE maid = %s" % (maid))

        mydb.commit()
        response_dict['delete_material'] = {'deleted_maid': maid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_material'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_notification(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("SELECT * FROM notification WHERE tid = %s" % (tid))
        columns = [desc[0] for desc in mycursor.description]

        response_dict['get_notification'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_notification'] = [{'server_error': 1, 'err_code': err_code}]
    finally:
        mydb.close()

    return response_dict

def add_notification(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]
        type = query_dict['type'][0]
        mode = query_dict['mode'][0]
        notification = query_dict['notification'][0]
        resp = dict()

        resp['tid'] = int(tid)
        resp['type'] = type
        resp['mode'] = int(mode)
        resp['notification'] = notification

        if 'date' in query_dict:
            date = query_dict['date'][0]

            mydb.connect()
            mycursor = mydb.cursor()

            mycursor.execute("INSERT INTO notification (tid, type, mode, date, notification) VALUES (%s, '%s', %s, '%s', '%s')" % (tid, type, mode, date, notification))
            resp['date'] = date
        elif 'value2' in query_dict:
            value1 = query_dict['value1'][0]
            value2 = query_dict['value2'][0]

            mydb.connect()
            mycursor = mydb.cursor()

            mycursor.execute("INSERT INTO notification (tid, type, mode, value1, value2, notification) VALUES (%s, '%s', %s, %s, %s, '%s')" % (tid, type, mode, value1, value2, notification))
            resp['value1'] = int(value1)
            resp['value2'] = int(value2)
        else:
            value1 = query_dict['value1'][0]

            mydb.connect()
            mycursor = mydb.cursor()

            mycursor.execute("INSERT INTO notification (tid, type, mode, value1, notification) VALUES (%s, '%s', %s, %s, '%s')" % (tid, type, mode, value1, notification))
            resp['value1'] = int(value1)

        mycursor.execute("SELECT LAST_INSERT_ID()")
        nid = mycursor.fetchone()[0]
        mydb.commit()
        resp['nid'] = nid
        response_dict['add_notification'] = resp
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['add_notification'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def delete_notification(mydb, query_dict, response_dict):
    try:
        nid = query_dict['nid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("DELETE FROM notification WHERE nid = %s" % (nid))

        mydb.commit()
        response_dict['delete_notification'] = {'deleted_nid': nid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['delete_notification'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def discard_fuel(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]
        now = datetime.now()
        date_string = now.strftime('%Y-%m-%d')

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute("UPDATE transport SET total_fuel = '0.0', fuel_date = '%s' WHERE tid = %s" % (date_string, tid))

        mydb.commit()
        response_dict['discard_fuel'] = {'tid' : tid}
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['discard_fuel'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_statistics_month(mydb, query_dict, response_dict):
    global argo_home
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        f = open(argo_home + '/wsgi/select_stat_by_month.sql')
        line = f.read().replace('121', tid)

        mycursor.execute(line)

        columns = [desc[0] for desc in mycursor.description]
        response_dict['get_statistics_month'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_statistics_month'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def get_statistics_year(mydb, query_dict, response_dict):
    global argo_home
    try:
        tid = query_dict['tid'][0]

        mydb.connect()
        mycursor = mydb.cursor()

        f = open(argo_home + '/wsgi/select_stat_by_year.sql')
        line = f.read().replace('121', tid)

        mycursor.execute(line)

        columns = [desc[0] for desc in mycursor.description]
        response_dict['get_statistics_year'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['get_statistics_year'] = {'server_error': 1, 'err_code': err_code}
    finally:
        mydb.close()

    return response_dict

def send_statistics_year(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        f = open(query_dict['argo_home'] + '/wsgi/select_stat_by_year.sql')
        line = f.read().replace('121', tid)

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute(line)

        columns = [desc[0] for desc in mycursor.description]
        values = [dict(zip(columns, row)) for row in mycursor.fetchall()]

        mycursor.execute("SELECT email from email WHERE uid = (SELECT uid FROM transport WHERE tid = %s) AND send = 1" % (tid))
        emails = [row[0] for row in mycursor.fetchall()]

        if emails != []:
            txt = """
                  <html lang="ru">
                  <head>
                  </head>
                  <body>
                  <h1>Статистика по годам</h1>
                  <div>
                  """
            for el in values:
                txt += """
                       <h2>Год: """ + el['mo'] +  """</h2>
                       <h3>Топливо</h3>
                       Кол-во заправок: """ + str(el['fuel_cnt']) + """
                       <br>
                       Средняя заправка: """ + str(el['fuel_avg']) + """
                       <br>
                       Сум. заправка: """ + str(el['fuel_sum']) + """
                       <br>
                       Мин. заправка: """ + str(el['fuel_min']) + """
                       <br>
                       Макс. заправка: """ + str(el['fuel_max']) + """
                       <br>
                       <h3>Пробег</h3>
                       Кол-во записей: """ + str(el['mileage_cnt']) + """
                       <br>
                       Средний пробег: """ + str(el['mileage_avg']) + """
                       <br>
                       Сум. пробег: """ + str(el['mileage_sum']) + """
                       <br>
                       Мин. пробег: """ + str(el['mileage_min']) + """
                       <br>
                       Макс. пробег: """ + str(el['mileage_max']) + """
                       <br>
                       <h3>Расход</h3>
                       На 100 км: """ + str(el['fm_sum']) + """
                       <br>
                       <br>
                       """
            txt += """
                   </div>
                   <br>
                   <font color="#696969">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                   </body>
                   </html>
                   """

            s = smtplib.SMTP('smtp.mail.ru', 587)
            s.starttls()
            s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
            msg = MIMEMultipart()

            message_template = txt
            message = message_template  # .substitute(PERSON_NAME=name.title())

            msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
            msg['To'] = ', '.join(emails)
            msg['BCC'] = 'sent@argonauts.online'
            msg['Subject'] = 'Уведомление от Argonauts'

            msg.attach(MIMEText(message, 'html'))
            s.send_message(msg)

            del msg

            response_dict['send_statistics_year'] = values
        else:
            response_dict['send_statistics_year'] = [{'empty_emails' : 1}]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['send_statistics_year'] = [{'server_error': 1, 'err_code': err_code}]
    except Exception as error:
        response_dict['send_statistics_year'] = [{'server_error': 1, 'err_message': str(error)}]
    finally:
        mydb.close()

    return response_dict


def send_statistics_month(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        f = open(query_dict['argo_home'] + '/wsgi/select_stat_by_month.sql')
        line = f.read().replace('121', tid)

        mydb.connect()
        mycursor = mydb.cursor()

        mycursor.execute(line)

        columns = [desc[0] for desc in mycursor.description]
        values = [dict(zip(columns, row)) for row in mycursor.fetchall()]

        mycursor.execute("SELECT email from email WHERE uid = (SELECT uid FROM transport WHERE tid = %s) AND send = 1" % (tid))
        emails = [row[0] for row in mycursor.fetchall()]

        if emails != []:
            txt = """
                  <html lang="ru">
                  <head>
                  </head>
                  <body>
                  <h1>Статистика по месяцам</h1>
                  <div>
                  """
            for el in values:
                txt += """
                       <h2>Месяц: """ + el['mo'] + """</h2>
                       <h3>Топливо</h3>
                       Кол-во заправок: """ + str(el['fuel_cnt']) + """
                       <br>
                       Средняя заправка: """ + str(el['fuel_avg']) + """
                       <br>
                       Сум. заправка: """ + str(el['fuel_sum']) + """
                       <br>
                       Мин. заправка: """ + str(el['fuel_min']) + """
                       <br>
                       Макс. заправка: """ + str(el['fuel_max']) + """
                       <br>
                       <h3>Пробег</h3>
                       Кол-во записей: """ + str(el['mileage_cnt']) + """
                       <br>
                       Средний пробег: """ + str(el['mileage_avg']) + """
                       <br>
                       Сум. пробег: """ + str(el['mileage_sum']) + """
                       <br>
                       Мин. пробег: """ + str(el['mileage_min']) + """
                       <br>
                       Макс. пробег: """ + str(el['mileage_max']) + """
                       <br>
                       <h3>Расход</h3>
                       На 100 км: """ + str(el['fm_sum']) + """
                       <br>
                       <br>
                       """
            txt += """
                   </div>
                   <br>
                   <font color="#696969">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                   </body>
                   </html>
                   """

            s = smtplib.SMTP('smtp.mail.ru', 587)
            s.starttls()
            s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
            msg = MIMEMultipart()

            message_template = txt
            message = message_template  # .substitute(PERSON_NAME=name.title())

            msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
            msg['To'] = ', '.join(emails)
            msg['BCC'] = 'sent@argonauts.online'
            msg['Subject'] = 'Уведомление от Argonauts'

            msg.attach(MIMEText(message, 'html'))
            s.send_message(msg)

            del msg

            response_dict['send_statistics_month'] = values
        else:
            response_dict['send_statistics_month'] = [{'empty_emails': 1}]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['send_statistics_month'] = [{'server_error': 1, 'err_code': err_code}]
    except Exception as error:
        response_dict['send_statistics_month'] = [{'server_error': 1, 'err_message': str(error)}]
    finally:
        mydb.close()

    return response_dict























def application(environ, start_response):
    global argo_home
    argo_user = environ['ARGO_USER']
    argo_pass = environ['ARGO_PASS']
    argo_base = environ['ARGO_BASE']
    argo_home = environ['ARGO_HOME']
    argodb = mysql.connector.connect(
        host="localhost",
        user=argo_user,
        password=argo_pass,
        database=argo_base
    )
    # argodb = mysql.connector.connect(
    #   host="localhost",
    #   user='argouser',
    #   password='argopassword',
    #   database='argodb'
    # )
    query_dict = parse_qs(environ['QUERY_STRING'])
    query_dict['argo_home'] = argo_home

    response_dict = {'proto_ver': '1.0.0'
        , 'sys.version': sys.version
        , 'query_dict': str(query_dict)
        , 'hostname': socket.gethostname()
        , 'cwd': os.getcwd()
                     }

    get_db_timestamp(argodb, response_dict)
    list_db_tables(argodb, response_dict)

    request_mission = query_dict.get('mission', [''])[0]



    # notification
    if request_mission == 'date_notification':
        date_notification(argodb, query_dict, response_dict)

    # elif request_mission == 'fuel_pred_notification':
        # send.fuel_pred_notification(argodb, query_dict, response_dict)
    # elif request_mission == 'fuel_post_notification':
    #     fuel_post_notification(argodb, query_dict, response_dict)
    # elif request_mission == 'mileage_pred_notification':
    #     mileage_pred_notification(argodb, query_dict, response_dict)
    # elif request_mission == 'mileage_post_notification':
    #     mileage_post_notification(argodb, query_dict, response_dict)
    # elif request_mission == 'enghour_pred_notification':
    #     enghour_pred_notification(argodb, query_dict, response_dict)
    # elif request_mission == 'enghour_post_notification':
    #     enghour_post_notification(argodb, query_dict, response_dict)
    # elif request_mission == 'diag_notification':
    #     diag_notification(argodb, query_dict, response_dict)
    # elif request_mission == 'osago_notification':
    #     osago_notification(argodb, query_dict, response_dict)

    elif request_mission == 'connect_device_code':
        connect_device_code(argodb, query_dict, response_dict)
    elif request_mission == 'is_email_exists':
        is_email_exists(argodb, query_dict, response_dict)
    elif request_mission == 'add_user':
        add_user(argodb, query_dict, response_dict)
    # transport
    elif request_mission == 'add_transp':
        add_transp(argodb, query_dict, response_dict)
    elif request_mission == 'get_tid_tnick':
        get_tid_tnick(argodb, query_dict, response_dict)
    elif request_mission == 'get_transp':
        get_transp(argodb, query_dict, response_dict)
    elif request_mission == 'update_transp_info':
        update_transp_info(argodb, query_dict, response_dict)
    elif request_mission == 'delete_transp':
        delete_transp(argodb, query_dict, response_dict)
    elif request_mission == 'discard_fuel':
        discard_fuel(argodb, query_dict, response_dict)
    # user
    elif request_mission == 'get_user_info':
        get_user_info(argodb, query_dict, response_dict)
    elif request_mission == 'update_user_info':
        update_user_info(argodb, query_dict, response_dict)
    # email
    elif request_mission == 'get_email':
        get_email(argodb, query_dict, response_dict)
    elif request_mission == 'add_email':
        add_email(argodb, query_dict, response_dict)
    elif request_mission == 'delete_email':
        delete_email(argodb, query_dict, response_dict)
    elif request_mission == 'change_email_send':
        change_email_send(argodb, query_dict, response_dict)
    # mileage
    elif request_mission == 'get_mileage':
        get_mileage(argodb, query_dict, response_dict)
    elif request_mission == 'add_mileage':
        add_mileage(argodb, query_dict, response_dict)
    elif request_mission == 'delete_mileage':
        delete_mileage(argodb, query_dict, response_dict)
    # eng_hour
    elif request_mission == 'get_eng_hour':
        get_eng_hour(argodb, query_dict, response_dict)
    elif request_mission == 'add_eng_hour':
        add_eng_hour(argodb, query_dict, response_dict)
    elif request_mission == 'delete_eng_hour':
        delete_eng_hour(argodb, query_dict, response_dict)
    # fuel
    elif request_mission == 'get_fuel':
        get_fuel(argodb, query_dict, response_dict)
    elif request_mission == 'add_fuel':
        add_fuel(argodb, query_dict, response_dict)
    elif request_mission == 'delete_fuel':
        delete_fuel(argodb, query_dict, response_dict)
    #service
    elif request_mission == 'get_service':
        get_service(argodb, query_dict, response_dict)
    elif request_mission == 'add_service':
        add_service(argodb, query_dict, response_dict)
    elif request_mission == 'delete_service':
        delete_service(argodb, query_dict, response_dict)
    elif request_mission == 'get_service_info':
        get_service_info(argodb, query_dict, response_dict)
    # material
    elif request_mission == 'get_material':
        get_material(argodb, query_dict, response_dict)
    elif request_mission == 'add_material':
        add_material(argodb, query_dict, response_dict)
    elif request_mission == 'delete_material':
        delete_material(argodb, query_dict, response_dict)
    # notification
    elif request_mission == 'get_notification':
        get_notification(argodb, query_dict, response_dict)
    elif request_mission == 'add_notification':
        add_notification(argodb, query_dict, response_dict)
    elif request_mission == 'delete_notification':
        delete_notification(argodb, query_dict, response_dict)
    # statistics
    elif request_mission == 'get_statistics_month':
        get_statistics_month(argodb, query_dict, response_dict)
    elif request_mission == 'get_statistics_year':
        get_statistics_year(argodb, query_dict, response_dict)
    elif request_mission == 'send_statistics_year':
        send_statistics_year(argodb, query_dict, response_dict)
    elif request_mission == 'send_statistics_month':
        send_statistics_month(argodb, query_dict, response_dict)


    response_status = '200 OK'
    response_json = bytes(json.dumps(response_dict, default=dump_date, indent=2, ensure_ascii=False, sort_keys=True), encoding='utf-8')
    response_headers = [('Content-type', 'text/plain; charset=utf-8'), ('Content-Length', str(len(response_json))),
                        ('Cache-Control', 'no-cache, no-store, must-revalidate'), ('Pragma', 'no-cache'), ('Expires', '0'),
                        ('Date', datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S.%f'))
                        ]
    start_response(response_status, response_headers)

    # time.sleep(2)
    return [response_json]
