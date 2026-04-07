import imaplib
import email
from typing import List, Dict

import imaplib
import email

def get_inbox(user: str, password: str) -> list:
    M = imaplib.IMAP4('127.0.0.1')
    M.login(user, password)
    M.select("INBOX")

    typ, data = M.search(None, "ALL")
    messages = []

    for num in data[0].split():
        typ, msg_data = M.fetch(num, "(RFC822)")
        raw_msg = msg_data[0][1]
        msg = email.message_from_bytes(raw_msg)

        # Manejar mensajes con varias partes
        body = ""
        if msg.is_multipart():
            for part in msg.walk():
                ctype = part.get_content_type()
                cdispo = str(part.get("Content-Disposition"))
                if ctype == "text/plain" and "attachment" not in cdispo:
                    body = part.get_payload(decode=True).decode(errors="ignore")
                    break
        else:
            body = msg.get_payload(decode=True).decode(errors="ignore")

        messages.append({
            "from": msg.get("From"),
            "subject": msg.get("Subject"),
            "body": body
        })

    M.logout()
    return messages