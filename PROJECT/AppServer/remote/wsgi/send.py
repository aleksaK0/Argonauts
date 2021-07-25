import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

def diag_notification(mydb, query_dict, response_dict):
    try:
        sent_emails = []
        mydb.connect()
        mycursor = mydb.cursor()

        for i in range(1, 10):

            mycursor.execute("SELECT n.*, t.nick AS tnick, u.nick, u.uid, date_sub(date_add(t.osago_date, interval 1 year), interval 1 day) as date_exp "
                             "FROM notification AS n "
                             "LEFT JOIN (transport AS t, user AS u) "
                             "ON (n.tid = t.tid AND t.uid = u.uid) "
                             "WHERE n.type = 'D' AND n.mode = 1 AND date <= current_date() AND (prev_sent IS NULL OR prev_sent < current_date()) "
                             "LIMIT 1")

            columns = [desc[0] for desc in mycursor.description]
            notif = [dict(zip(columns, row)) for row in mycursor.fetchall()]

            if notif == []:
                break

            mycursor.execute("SELECT email FROM email AS e WHERE e.uid = %d AND e.send = 1" % (notif[0]['uid']))
            emails = [row[0] for row in mycursor.fetchall()]

            if emails == []:
                mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))
                mydb.commit()
                continue

            sent_emails.append(emails)

            mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))

            s = smtplib.SMTP('smtp.mail.ru', 587)
            s.starttls()
            s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
            msg = MIMEMultipart()

            message_template = """
                            <html lang="ru">
                            <head>
                            </head>
                            <body>
                            <div style="font-size: 1em">
                            Здравствуйте, """ + notif[0]['nick'] + """!
                            <br>
                            <br>
                            Уведомление: <b>""" + notif[0]['notification'] + """</b>
                            <br>
                            Истекает: """ + str(notif[0]['date_exp']) + """
                            <br>
                            Для транспортного средства: """ + notif[0]['tnick'] + """
                            </div>
                            <br>
                            <br>
                            <font color="#696969" style="font-size: 1em">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                            </body>
                            </html>
                            """

            message = message_template  # .substitute(PERSON_NAME=name.title())

            msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
            msg['To'] = ', '.join(emails)
            msg['BCC'] = 'sent@argonauts.online'
            msg['Subject'] = 'Уведомление от Argonauts'

            msg.attach(MIMEText(message, 'html'))
            s.send_message(msg)

            del msg

            mydb.commit()

        response_dict['diag_notification'] = {'sent_emails': sent_emails}
    except Exception as error:
        response_dict['diag_notification'] = {'server_error': 1, 'err_code': str(error)}
    finally:
        mydb.close()

    return response_dict

def osago_notification(mydb, query_dict, response_dict):
    try:
        sent_emails = []
        mydb.connect()
        mycursor = mydb.cursor()

        for i in range(1, 10):
            mycursor.execute("SELECT n.*, t.nick AS tnick, u.nick, u.uid, date_sub(date_add(t.osago_date, interval 1 year), interval 1 day) as date_exp "
                             "FROM notification AS n "
                             "LEFT JOIN (transport AS t, user AS u) "
                             "ON (n.tid = t.tid AND t.uid = u.uid) "
                             "WHERE n.type = 'D' AND n.mode = 2 AND date <= current_date() AND (prev_sent IS NULL OR prev_sent < current_date()) "
                             "LIMIT 1")

            columns = [desc[0] for desc in mycursor.description]
            notif = [dict(zip(columns, row)) for row in mycursor.fetchall()]

            if notif == []:
                break

            mycursor.execute("SELECT email FROM email AS e WHERE e.uid = %d AND e.send = 1" % (notif[0]['uid']))
            emails = [row[0] for row in mycursor.fetchall()]

            if emails == []:
                mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))
                mydb.commit()
                continue

            sent_emails.append(emails)

            mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))

            s = smtplib.SMTP('smtp.mail.ru', 587)
            s.starttls()
            s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
            msg = MIMEMultipart()

            message_template = """
                            <html lang="ru">
                            <head>
                            </head>
                            <body>
                            <div style="font-size: 1em">
                            Здравствуйте, """ + notif[0]['nick'] + """!
                            <br>
                            <br>
                            Уведомление: <b>""" + notif[0]['notification'] + """</b>
                            <br>
                            Истекает: """ + str(notif[0]['date_exp']) + """
                            <br>
                            Для транспортного средства: """ + notif[0]['tnick'] + """
                            </div>
                            <br>
                            <br>
                            <font color="#696969" style="font-size: 1em">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                            </body>
                            </html>
                            """

            message = message_template  # .substitute(PERSON_NAME=name.title())

            msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
            msg['To'] = ', '.join(emails)
            msg['BCC'] = 'sent@argonauts.online'
            msg['Subject'] = 'Уведомление от Argonauts'

            msg.attach(MIMEText(message, 'html'))
            s.send_message(msg)

            del msg

            mydb.commit()

        response_dict['osago_notification'] = {'sent_emails': sent_emails}
    except Exception as error:
        response_dict['osago_notification'] = {'server_error': 1, 'err_code': str(error)}
    finally:
        mydb.close()

    return response_dict

def fuel_pred_notification(mydb, query_dict, response_dict):
    try:
        sent_emails = []
        mydb.connect()
        mycursor = mydb.cursor()

        for i in range(1, 10):
            mycursor.execute("SELECT n.*, t.nick AS tnick, u.nick, u.uid, t.total_fuel "
                             "FROM notification AS n "
                             "LEFT JOIN (transport AS t, user AS u) "
                             "ON (n.tid = t.tid AND t.uid = u.uid) "
                             "WHERE n.type = 'F' AND (t.total_fuel >= n.value2 AND t.total_fuel < n.value1) AND prev_sent IS NULL "
                             "LIMIT 1")

            columns = [desc[0] for desc in mycursor.description]
            notif = [dict(zip(columns, row)) for row in mycursor.fetchall()]

            if notif == []:
                break

            mycursor.execute("SELECT email FROM email AS e WHERE e.uid = %d AND e.send = 1" % (notif[0]['uid']))
            emails = [row[0] for row in mycursor.fetchall()]

            if emails == []:
                mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))
                mydb.commit()
                continue

            sent_emails.append(emails)

            mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))

            s = smtplib.SMTP('smtp.mail.ru', 587)
            s.starttls()
            s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
            msg = MIMEMultipart()

            message_template = """
                            <html lang="ru">
                            <head>
                            </head>
                            <body>
                            <div style="font-size: 1em">
                            Здравствуйте, """ + notif[0]['nick'] + """!
                            <br>
                            <br>
                            Приближающееся уведомление: <b>""" + notif[0]['notification'] + """</b>
                            <br>
                            Суммарный расход топлива: """ + str(notif[0]['total_fuel']) + """
                            <br>
                            Для транспортного средства: """ + notif[0]['tnick'] + """
                            </div>
                            <br>
                            <br>
                            <font color="#696969" style="font-size: 1em">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                            </body>
                            </html>
                            """

            message = message_template  # .substitute(PERSON_NAME=name.title())

            msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
            msg['To'] = ', '.join(emails)
            msg['BCC'] = 'sent@argonauts.online'
            msg['Subject'] = 'Уведомление от Argonauts'

            msg.attach(MIMEText(message, 'html'))
            s.send_message(msg)

            del msg

            mydb.commit()

        response_dict['fuel_pred_notification'] = {'sent_emails': sent_emails}
    except Exception as error:
        response_dict['fuel_pred_notification'] = {'server_error': 1, 'err_code': str(error)}
    finally:
        mydb.close()

    return response_dict

def fuel_post_notification(mydb, query_dict, response_dict):
    try:
        sent_emails = []
        mydb.connect()
        mycursor = mydb.cursor()

        for i in range(1, 10):
            mycursor.execute("SELECT n.*, t.nick AS tnick, u.nick, u.uid, t.total_fuel "
                             "FROM notification AS n "
                             "LEFT JOIN (transport AS t, user AS u) "
                             "ON (n.tid = t.tid AND t.uid = u.uid) "
                             "WHERE n.type = 'F' AND t.total_fuel >= n.value1 AND prev_sent < current_date() "
                             "LIMIT 1")

            columns = [desc[0] for desc in mycursor.description]
            notif = [dict(zip(columns, row)) for row in mycursor.fetchall()]

            if notif == []:
                break

            mycursor.execute("SELECT email FROM email AS e WHERE e.uid = %d AND e.send = 1" % (notif[0]['uid']))
            emails = [row[0] for row in mycursor.fetchall()]

            if emails == []:
                mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))
                mydb.commit()
                continue

            sent_emails.append(emails)

            mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))

            s = smtplib.SMTP('smtp.mail.ru', 587)
            s.starttls()
            s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
            msg = MIMEMultipart()

            message_template = """
                            <html lang="ru">
                            <head>
                            </head>
                            <body>
                            <div style="font-size: 1em">
                            Здравствуйте, """ + notif[0]['nick'] + """!
                            <br>
                            <br>
                            Уведомление: <b>""" + notif[0]['notification'] + """</b>
                            <br>
                            Суммарный расход топлива: """ + str(notif[0]['total_fuel']) + """
                            <br>
                            Для транспортного средства: """ + notif[0]['tnick'] + """
                            </div>
                            <br>
                            <br>
                            <font color="#696969" style="font-size: 1em">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                            </body>
                            </html>
                            """

            message = message_template  # .substitute(PERSON_NAME=name.title())

            msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
            msg['To'] = ', '.join(emails)
            msg['BCC'] = 'sent@argonauts.online'
            msg['Subject'] = 'Уведомление от Argonauts'

            msg.attach(MIMEText(message, 'html'))
            s.send_message(msg)

            del msg

            mydb.commit()

        response_dict['fuel_post_notification'] = {'sent_emails': sent_emails}
    except Exception as error:
        response_dict['fuel_post_notification'] = {'server_error': 1, 'err_code': str(error)}
    finally:
        mydb.close()

    return response_dict

def mileage_pred_notification(mydb, query_dict, response_dict):
    try:
        sent_emails = []
        mydb.connect()
        mycursor = mydb.cursor()

        for i in range(1, 10):
            mycursor.execute("SELECT n.*, t.nick AS tnick, u.nick, u.uid, t.mileage "
                             "FROM notification AS n "
                             "LEFT JOIN (transport AS t, user AS u) "
                             "ON (n.tid = t.tid AND t.uid = u.uid) "
                             "WHERE n.type = 'M' AND (t.mileage >= n.value2 AND t.mileage < n.value1) AND prev_sent IS NULL "
                             "LIMIT 1")

            columns = [desc[0] for desc in mycursor.description]
            notif = [dict(zip(columns, row)) for row in mycursor.fetchall()]

            if notif == []:
                break

            mycursor.execute("SELECT email FROM email AS e WHERE e.uid = %d AND e.send = 1" % (notif[0]['uid']))
            emails = [row[0] for row in mycursor.fetchall()]

            if emails == []:
                mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))
                mydb.commit()
                continue

            sent_emails.append(emails)

            mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))

            s = smtplib.SMTP('smtp.mail.ru', 587)
            s.starttls()
            s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
            msg = MIMEMultipart()

            message_template = """
                            <html lang="ru">
                            <head>
                            </head>
                            <body>
                            <div style="font-size: 1em">
                            Здравствуйте, """ + notif[0]['nick'] + """!
                            <br>
                            <br>
                            Приближающееся уведомление: <b>""" + notif[0]['notification'] + """</b>
                            <br>
                            Пробег: """ + str(notif[0]['mileage']) + """
                            <br>
                            Для транспортного средства: """ + notif[0]['tnick'] + """
                            </div>
                            <br>
                            <br>
                            <font color="#696969" style="font-size: 1em">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                            </body>
                            </html>
                            """

            message = message_template  # .substitute(PERSON_NAME=name.title())

            msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
            msg['To'] = ', '.join(emails)
            msg['BCC'] = 'sent@argonauts.online'
            msg['Subject'] = 'Уведомление от Argonauts'

            msg.attach(MIMEText(message, 'html'))
            s.send_message(msg)

            del msg

            mydb.commit()

        response_dict['mileage_pred_notification'] = {'sent_emails': sent_emails}
    except Exception as error:
        response_dict['mileage_pred_notification'] = {'server_error': 1, 'err_code': str(error)}
    finally:
        mydb.close()

    return response_dict

def mileage_post_notification(mydb, query_dict, response_dict):
    try:
        sent_emails = []
        mydb.connect()
        mycursor = mydb.cursor()

        for i in range(1, 10):
            mycursor.execute("SELECT n.*, t.nick AS tnick, u.nick, u.uid, t.mileage "
                             "FROM notification AS n "
                             "LEFT JOIN (transport AS t, user AS u) "
                             "ON (n.tid = t.tid AND t.uid = u.uid) "
                             "WHERE n.type = 'M' AND t.mileage >= n.value1 AND prev_sent < current_date() "
                             "LIMIT 1")

            columns = [desc[0] for desc in mycursor.description]
            notif = [dict(zip(columns, row)) for row in mycursor.fetchall()]

            if notif == []:
                break

            mycursor.execute("SELECT email FROM email AS e WHERE e.uid = %d AND e.send = 1" % (notif[0]['uid']))
            emails = [row[0] for row in mycursor.fetchall()]

            if emails == []:
                mycursor.execute(
                    "UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))
                mydb.commit()
                continue

            sent_emails.append(emails)

            mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))

            s = smtplib.SMTP('smtp.mail.ru', 587)
            s.starttls()
            s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
            msg = MIMEMultipart()

            message_template = """
                            <html lang="ru">
                            <head>
                            </head>
                            <body>
                            <div style="font-size: 1em">
                            Здравствуйте, """ + notif[0]['nick'] + """!
                            <br>
                            <br>
                            Уведомление: <b>""" + notif[0]['notification'] + """</b>
                            <br>
                            Пробег: """ + str(notif[0]['mileage']) + """
                            <br>
                            Для транспортного средства: """ + notif[0]['tnick'] + """
                            </div>
                            <br>
                            <br>
                            <font color="#696969" style="font-size: 1em">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                            </body>
                            </html>
                            """

            message = message_template  # .substitute(PERSON_NAME=name.title())

            msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
            msg['To'] = ', '.join(emails)
            msg['BCC'] = 'sent@argonauts.online'
            msg['Subject'] = 'Уведомление от Argonauts'

            msg.attach(MIMEText(message, 'html'))
            s.send_message(msg)

            del msg

            mydb.commit()

        response_dict['mileage_post_notification'] = {'sent_emails': sent_emails}
    except Exception as error:
        response_dict['mileage_post_notification'] = {'server_error': 1, 'err_code': str(error)}
    finally:
        mydb.close()

    return response_dict

def enghour_pred_notification(mydb, query_dict, response_dict):
    try:
        sent_emails = []
        mydb.connect()
        mycursor = mydb.cursor()

        for i in range(1, 10):
            mycursor.execute("SELECT n.*, t.nick AS tnick, u.nick, u.uid, t.eng_hour "
                             "FROM notification AS n "
                             "LEFT JOIN (transport AS t, user AS u) "
                             "ON (n.tid = t.tid AND t.uid = u.uid) "
                             "WHERE n.type = 'H' AND (t.eng_hour >= n.value2 AND t.eng_hour < n.value1) AND prev_sent IS NULL "
                             "LIMIT 1")

            columns = [desc[0] for desc in mycursor.description]
            notif = [dict(zip(columns, row)) for row in mycursor.fetchall()]

            if notif == []:
                break

            mycursor.execute("SELECT email FROM email AS e WHERE e.uid = %d AND e.send = 1" % (notif[0]['uid']))
            emails = [row[0] for row in mycursor.fetchall()]

            if emails == []:
                mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))
                mydb.commit()
                continue

            sent_emails.append(emails)

            mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))

            s = smtplib.SMTP('smtp.mail.ru', 587)
            s.starttls()
            s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
            msg = MIMEMultipart()

            message_template = """
                            <html lang="ru">
                            <head>
                            </head>
                            <body>
                            <div style="font-size: 1em">
                            Здравствуйте, """ + notif[0]['nick'] + """!
                            <br>
                            <br>
                            Приближающееся уведомление: <b>""" + notif[0]['notification'] + """</b>
                            <br>
                            Моточасы: """ + str(notif[0]['eng_hour']) + """
                            <br>
                            Для транспортного средства: """ + notif[0]['tnick'] + """
                            </div>
                            <br>
                            <br>
                            <font color="#696969" style="font-size: 1em">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                            </body>
                            </html>
                            """

            message = message_template  # .substitute(PERSON_NAME=name.title())

            msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
            msg['To'] = ', '.join(emails)
            msg['BCC'] = 'sent@argonauts.online'
            msg['Subject'] = 'Уведомление от Argonauts'

            msg.attach(MIMEText(message, 'html'))
            s.send_message(msg)

            del msg

            mydb.commit()

        response_dict['enghour_pred_notification'] = {'sent_emails': sent_emails}
    except Exception as error:
        response_dict['enghour_pred_notification'] = {'server_error': 1, 'err_code': str(error)}
    finally:
        mydb.close()

    return response_dict

def enghour_post_notification(mydb, query_dict, response_dict):
    try:
        sent_emails = []
        mydb.connect()
        mycursor = mydb.cursor()

        for i in range(1, 10):
            mycursor.execute("SELECT n.*, t.nick AS tnick, u.nick, u.uid, t.eng_hour "
                             "FROM notification AS n "
                             "LEFT JOIN (transport AS t, user AS u) "
                             "ON (n.tid = t.tid AND t.uid = u.uid) "
                             "WHERE n.type = 'H' AND t.eng_hour >= n.value1 AND prev_sent < current_date() "
                             "LIMIT 1")

            columns = [desc[0] for desc in mycursor.description]
            notif = [dict(zip(columns, row)) for row in mycursor.fetchall()]

            if notif == []:
                break

            mycursor.execute("SELECT email FROM email AS e WHERE e.uid = %d AND e.send = 1" % (notif[0]['uid']))
            emails = [row[0] for row in mycursor.fetchall()]

            if emails == []:
                mycursor.execute(
                    "UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))
                mydb.commit()
                continue

            sent_emails.append(emails)

            mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))

            s = smtplib.SMTP('smtp.mail.ru', 587)
            s.starttls()
            s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
            msg = MIMEMultipart()

            message_template = """
                            <html lang="ru">
                            <head>
                            </head>
                            <body>
                            <div style="font-size: 1em">
                            Здравствуйте, """ + notif[0]['nick'] + """!
                            <br>
                            <br>
                            Уведомление: <b>""" + notif[0]['notification'] + """</b>
                            <br>
                            Моточасы: """ + str(notif[0]['eng_hour']) + """
                            <br>
                            Для транспортного средства: """ + notif[0]['tnick'] + """
                            </div>
                            <br>
                            <br>
                            <font color="#696969" style="font-size: 1em">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                            </body>
                            </html>
                            """

            message = message_template  # .substitute(PERSON_NAME=name.title())

            msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
            msg['To'] = ', '.join(emails)
            msg['BCC'] = 'sent@argonauts.online'
            msg['Subject'] = 'Уведомление от Argonauts'

            msg.attach(MIMEText(message, 'html'))
            s.send_message(msg)

            del msg

            mydb.commit()
        response_dict['enghour_post_notification'] = {'sent_emails': sent_emails}
    except Exception as error:
        response_dict['enghour_post_notification'] = {'server_error': 1, 'err_code': str(error)}
    finally:
        mydb.close()

    return response_dict

def date_notification(mydb, query_dict, response_dict):
    try:
        sent_emails = []
        mydb.connect()
        mycursor = mydb.cursor()

        for i in range(1, 10):
            mycursor.execute("SELECT n.*, t.nick AS tnick, u.nick, u.uid "
                             "FROM notification AS n "
                             "LEFT JOIN (transport AS t, user AS u) "
                             "ON (n.tid = t.tid AND t.uid = u.uid) "
                             "WHERE type = 'T' AND date <= current_date() AND (prev_sent < current_date() OR prev_sent IS NULL) "
                             "LIMIT 1")

            columns = [desc[0] for desc in mycursor.description]
            notif = [dict(zip(columns, row)) for row in mycursor.fetchall()]

            if notif == []:
                break

            mycursor.execute("SELECT email FROM email AS e WHERE e.uid = %d AND e.send = 1" % (notif[0]['uid']))
            emails = [row[0] for row in mycursor.fetchall()]

            if emails == []:
                mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))
                mydb.commit()
                continue

            sent_emails.append(emails)

            mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))

            s = smtplib.SMTP('smtp.mail.ru', 587)
            s.starttls()
            s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
            msg = MIMEMultipart()

            message_template = """
                            <html lang="ru">
                            <head>
                            </head>
                            <body>
                            <div style="font-size: 1em">
                            Здравствуйте, """ + notif[0]['nick'] + """!
                            <br>
                            <br>
                            Уведомление: <b>""" + notif[0]['notification'] + """</b>
                            <br>
                            На время: """ + str(notif[0]['date']) + """
                            <br>
                            Для транспортного средства: """ + notif[0]['tnick'] + """
                            </div>
                            <br>
                            <br>
                            <font color="#696969" style="font-size: 1em">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                            </body>
                            </html>
                            """

            message = message_template  # .substitute(PERSON_NAME=name.title())

            msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
            msg['To'] = ', '.join(emails)
            msg['BCC'] = 'sent@argonauts.online'
            msg['Subject'] = 'Уведомление от Argonauts'

            msg.attach(MIMEText(message, 'html'))
            s.send_message(msg)

            del msg

            mydb.commit()

        response_dict['date_notification'] = {'sent_emails' : sent_emails}
    except Exception as error:
        response_dict['date_notification'] = {'server_error': 1, 'err_code': str(error)}
    finally:
        mydb.close()

    return response_dict


def connect_device_code(mydb, query_dict, response_dict):
    try:
        email = query_dict['email'][0]
        code = query_dict['code'][0]
        s = smtplib.SMTP('smtp.mail.ru', 587)
        s.starttls()
        s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
        msg = MIMEMultipart()

        message_template = """
                        <html lang="ru">
                        <head>
                        </head>
                        <body>
                        <div style="font-size: 1.2em">Здравствуйте!</div>
                        <br>
                        <div style="font-size: 1.2em">Код подтверждения: <b>""" + code + """</b>
                        </div>
                        <br>
                        <br>
                        <font color="#696969" style="font-size: 1em">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
                        </body>
                        </html>
                        """

        message = message_template  # .substitute(PERSON_NAME=name.title())

        msg['From'] = 'noreply@argonauts.online'
        msg['To'] = email
        msg['BCC'] = 'sent@argonauts.online'
        msg['Subject'] = 'Код подтверждения'

        msg.attach(MIMEText(message, 'html'))
        s.send_message(msg)

        del msg

        response_dict['connect_device_code'] = {'email': email, 'code': code}
    except:
        response_dict['connect_device_code'] = {'server_error': 1}

    return response_dict