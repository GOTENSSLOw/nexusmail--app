import os
import subprocess
from ..validators import sanitize_username, is_valid_username

def create_system_user(username, password):
    clean_user = sanitize_username(username)
    if not is_valid_username(clean_user):
        raise ValueError("Nombre de usuario inválido.")

    # Usuario que corre Django (necesita acceso a Maildir via ACLs)
    django_user = os.environ.get("DJANGO_USER") or os.getenv("USER", "www-data")

    try:
        subprocess.run(["sudo", "useradd", "-m", clean_user], check=True)

        chpasswd_proc = subprocess.Popen(["sudo", "chpasswd"], stdin=subprocess.PIPE, text=True)
        chpasswd_proc.communicate(input=f"{clean_user}:{password}")

        maildir = f"/home/{clean_user}/Maildir"
        subprocess.run(["sudo", "mkdir", "-p", f"{maildir}/cur", f"{maildir}/new", f"{maildir}/tmp"], check=True)
        subprocess.run(["sudo", "chown", "-R", f"{clean_user}:{clean_user}", maildir], check=True)

        # ACLs: dar acceso al usuario de Django
        subprocess.run(["sudo", "setfacl", "-m", f"u:{django_user}:x", f"/home/{clean_user}"], check=True)
        subprocess.run(["sudo", "setfacl", "-R", "-m", f"u:{django_user}:rx", maildir], check=True)
        subprocess.run(["sudo", "setfacl", "-R", "-d", "-m", f"u:{django_user}:r", maildir], check=True)

        return True
    except subprocess.CalledProcessError:
        return False