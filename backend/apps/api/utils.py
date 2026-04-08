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



import re

def sanitize_username(username: str) -> str:
    # 1. Convertir a minúsculas (estándar en sistemas de correo)
    username = username.lower().strip()
    
    # 2. Solo permitir letras (a-z) y números (0-9)
    # Eliminamos cualquier cosa que no sea alfanumérica
    username = re.sub(r'[^a-z0-9]', '', username)
    
    # 3. Limitar longitud (Linux useradd suele tener un límite de 32)
    # Dejamos 30 por seguridad
    return username[:30]

def is_valid_username(username: str) -> bool:
    """Verifica si el usuario es válido antes de procesar"""
    if not username or len(username) < 3:
        return False
    # No permitir que el usuario empiece con un número (regla de Linux)
    if username[0].isdigit():
        return False
    return True


import subprocess

def create_system_user(username, password):
    clean_user = sanitize_username(username)
    
    if not is_valid_username(clean_user):
        raise ValueError("Nombre de usuario inválido o demasiado corto.")

    try:
        # Forma SEGURA: Pasamos una lista, NO un string con shell=True
        # 1. Crear usuario
        subprocess.run(["sudo", "useradd", "-m", clean_user], check=True)
        
        # 2. Cambiar contraseña (stdin para evitar que se vea en logs)
        chpasswd_proc = subprocess.Popen(
            ["sudo", "chpasswd"], 
            stdin=subprocess.PIPE, 
            text=True
        )
        chpasswd_proc.communicate(input=f"{clean_user}:{password}")

        # 3. Permisos Maildir y ACLs
        # Nota: Aquí sí usamos rutas construidas, pero con el usuario ya limpio
        maildir = f"/home/{clean_user}/Maildir"
        
        subprocess.run(["sudo", "mkdir", "-p", f"{maildir}/cur", f"{maildir}/new", f"{maildir}/tmp"], check=True)
        subprocess.run(["sudo", "chown", "-R", f"{clean_user}:{clean_user}", maildir], check=True)
        
        # ACLs para Django (usuario void)
        subprocess.run(["sudo", "setfacl", "-m", "u:void:x", f"/home/{clean_user}"], check=True)
        subprocess.run(["sudo", "setfacl", "-R", "-m", "u:void:rx", maildir], check=True)
        subprocess.run(["sudo", "setfacl", "-R", "-d", "-m", "u:void:r", maildir], check=True)

        return True
    except subprocess.CalledProcessError as e:
        print(f"Error ejecutando comando: {e}")
        return False