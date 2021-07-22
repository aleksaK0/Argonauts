import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

def osago_notification(mydb, query_dict, response_dict):
    try:
        mydb.connect()
        mycursor = mydb.cursor()

        for i in range(1, 10):
            mycursor.execute("SELECT n.*, t.nick AS tnick, u.nick, u.uid, date_sub(date_add(t.osago_date, interval 1 year), interval 1 day) as date_exp "
                             "FROM notification AS n "
                             "LEFT JOIN (transport AS t, user AS u) "
                             "ON (n.tid = t.tid AND t.uid = u.uid) "
                             "WHERE n.type = 'D' AND n.mode = 2 AND (prev_sent IS NULL OR prev_sent < current_date()) "
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

        response_dict['osago_notification'] = {'sent': 1}
    except Exception as error:
        # logger = logging.getLogger('ftpuploader')
        # logger.error('Error: ' + str(error))
        response_dict['osago_notification'] = {'server_error': 1}
    finally:
        mydb.close()

    return response_dict