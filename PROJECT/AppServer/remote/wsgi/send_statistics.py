import mysql.connector

def statistics_year(mydb, query_dict, response_dict):
    try:
        tid = query_dict['tid'][0]

        f = open(query_dict['argo_home'] + '/wsgi/select_stat_by_year.sql')
        line = f.read().replace('121', tid)

        mydb.connect()
        mycursor = mydb.cursor()

        # r = 10 / 0

        # mycursor.execute('skjfhglsjhglsjhglsdfjghsldfghl')

        mycursor.execute(line)

        columns = [desc[0] for desc in mycursor.description]
        response_dict['statistics_year'] = [dict(zip(columns, row)) for row in mycursor.fetchall()]
    except mysql.connector.Error as error:
        err_code = int(str(error).split()[0])
        response_dict['statistics_year'] = {'server_error': 1, 'err_code': err_code}
    except Exception as error:
        response_dict['statistics_year'] = {'server_error': 1, 'err_message': str(error)}
    finally:
        mydb.close()

    return response_dict

            # mycursor.execute("SELECT email FROM email AS e WHERE e.uid = %d AND e.send = 1" % (notif[0]['uid']))
            # emails = [row[0] for row in mycursor.fetchall()]

            # if emails == []:
            #     mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))
            #     mydb.commit()
            #     continue
            #
            # sent_emails.append(emails)
            #
            # mycursor.execute("UPDATE notification SET prev_sent = current_date() WHERE nid = %s" % (notif[0]['nid']))

    #         s = smtplib.SMTP('smtp.mail.ru', 587)
    #         s.starttls()
    #         s.login('noreply@argonauts.online', 'YexVc31P#up~0~DuAhC2xIwysK*kcaXO')
    #         msg = MIMEMultipart()
    #
    #         message_template = """
    #                         <html lang="ru">
    #                         <head>
    #                         </head>
    #                         <body>
    #                         <div style="font-size: 1em">
    #                         Здравствуйте, """ + notif[0]['nick'] + """!
    #                         <br>
    #                         <br>
    #                         Уведомление: <b>""" + notif[0]['notification'] + """</b>
    #                         <br>
    #                         Истекает: """ + str(notif[0]['date_exp']) + """
    #                         <br>
    #                         Для транспортного средства: """ + notif[0]['tnick'] + """
    #                         </div>
    #                         <br>
    #                         <br>
    #                         <font color="#696969" style="font-size: 1em">Данное уведомление сформировано и отправлено автоматически и не требует ответа.<font>
    #                         </body>
    #                         </html>
    #                         """
    #
    #         message = message_template  # .substitute(PERSON_NAME=name.title())
    #
    #         msg['From'] = 'Argonauts.Online <noreply@argonauts.online>'
    #         msg['To'] = ', '.join(emails)
    #         msg['BCC'] = 'sent@argonauts.online'
    #         msg['Subject'] = 'Уведомление от Argonauts'
    #
    #         msg.attach(MIMEText(message, 'html'))
    #         s.send_message(msg)
    #
    #         del msg
    #
    #         mydb.commit()
    #
    #     response_dict['diag_notification'] = {'sent_emails': sent_emails}
    # except Exception as error:
    #     response_dict['diag_notification'] = {'server_error': 1, 'err_code': str(error)}
    # finally:
    #     mydb.close()
    #
    # return response_dict
    #



