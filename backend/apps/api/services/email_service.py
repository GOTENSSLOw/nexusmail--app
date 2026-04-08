import imaplib
import email
from ..models import EmailMessage

def get_inbox_from_imap(user: str, password: str) -> list:
    """Extrae correos crudos del servidor local."""
    try:
        M = imaplib.IMAP4('127.0.0.1')
        M.login(user, password)
        M.select("INBOX")
        
        # Usamos SEARCH ALL para traer todo el buzón
        typ, data = M.search(None, "ALL")
        messages = []

        for num in data[0].split():
            typ, msg_data = M.fetch(num, "(RFC822)")
            if typ != 'OK': continue
            
            msg = email.message_from_bytes(msg_data[0][1])
            
            # Extraer cuerpo del mensaje
            body = ""
            if msg.is_multipart():
                for part in msg.walk():
                    if part.get_content_type() == "text/plain":
                        payload = part.get_payload(decode=True)
                        if payload:
                            body = payload.decode(errors="ignore")
                        break
            else:
                payload = msg.get_payload(decode=True)
                if payload:
                    body = payload.decode(errors="ignore")

            messages.append({
                "uid": num.decode(), 
                "from": msg.get("From", "Desconocido"),
                "subject": msg.get("Subject", "(Sin Asunto)"),
                "body": body,
                "date": msg.get("Date", "")
            })
        
        M.logout()
        return messages
    except Exception as e:
        print(f"Error IMAP: {e}")
        return []

def sync_emails_with_db(user_obj, password):
    """Orquestador: Trae de IMAP y guarda en Django evitando duplicados."""
    raw_emails = get_inbox_from_imap(user_obj.username, password)
    
    for mail in raw_emails:
        # 1. Identificador único Robusto: Usuario + Fecha + Asunto
        # Esto evita que si dos usuarios reciben el mismo correo, la DB se confunda
        identifier = f"{user_obj.username}-{mail['date']}-{mail['subject']}"
        
        # 2. get_or_create: Si el identifier existe, no hace nada. Si no, lo crea.
        EmailMessage.objects.get_or_create(
            message_id_hash=identifier, # Llave única
            user=user_obj,              # Asociación al dueño
            defaults={
                'sender': mail['from'],
                'recipient': f"{user_obj.username}@lan.local",
                'subject': mail['subject'],
                'body': mail['body'],
                'unread': True, # Por defecto nuevos como no leídos
                # Nota: El snippet se genera solo en el .save() del modelo
            }
        )