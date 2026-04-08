import imaplib
import email
from ..models import EmailMessage # Tu modelo de DB

def get_inbox_from_imap(user: str, password: str) -> list:
    """Extrae correos crudos del servidor local."""
    M = imaplib.IMAP4('127.0.0.1')
    M.login(user, password)
    M.select("INBOX")
    
    typ, data = M.search(None, "ALL")
    messages = []

    for num in data[0].split():
        typ, msg_data = M.fetch(num, "(RFC822)")
        msg = email.message_from_bytes(msg_data[0][1])
        
        body = ""
        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() == "text/plain":
                    body = part.get_payload(decode=True).decode(errors="ignore")
                    break
        else:
            body = msg.get_payload(decode=True).decode(errors="ignore")

        messages.append({
            "uid": num.decode(), # Usar el UID de IMAP es mejor que el subject
            "from": msg.get("From"),
            "subject": msg.get("Subject"),
            "body": body,
            "date": msg.get("Date")
        })
    M.logout()
    return messages

def sync_emails_with_db(user_obj, password):
    raw_emails = get_inbox_from_imap(user_obj.username, password)
    
    for mail in raw_emails:
        # INCLUYE EL USERNAME PARA HACERLO ÚNICO POR USUARIO
        identifier = f"{user_obj.username}-{mail['subject']}-{mail['date']}"
        
        # O mejor aún, filtra por user Y message_id_hash en el get_or_create
        EmailMessage.objects.get_or_create(
            message_id_hash=identifier,
            user=user_obj, # <--- Ahora es único para este usuario
            defaults={
                'sender': mail['from'],
                'recipient': f"{user_obj.username}@lan.local",
                'subject': mail['subject'],
                'body': mail['body'],
                'unread': True
            }
        )