import os
import subprocess
from ..validators import sanitize_username, is_valid_username

def create_system_user(username, password):
    clean_user = sanitize_username(username)
    if not is_valid_username(clean_user):
        raise ValueError("Nombre de usuario inválido.")

    # Usuario que corre Django (necesita acceso a Maildir via ACLs)
    django_user = os.environ.get("DJANGO_USER") or os.getenv("USER", "www-data")
    in_docker = os.environ.get("DOCKER_CONTAINER", "false").lower() == "true"

    try:
        cmd_prefix = [] if in_docker else ["sudo"]

        subprocess.run([*cmd_prefix, "useradd", "-m", clean_user], check=True)

        chpasswd_proc = subprocess.Popen([*cmd_prefix, "chpasswd"], stdin=subprocess.PIPE, text=True)
        chpasswd_proc.communicate(input=f"{clean_user}:{password}")

        maildir = f"/home/{clean_user}/Maildir"
        subprocess.run([*cmd_prefix, "mkdir", "-p", f"{maildir}/cur", f"{maildir}/new", f"{maildir}/tmp"], check=True)
        subprocess.run([*cmd_prefix, "chown", "-R", f"{clean_user}:{clean_user}", maildir], check=True)

        if not in_docker:
            # ACLs: dar acceso al usuario de Django (only on host, not available in slim Docker image)
            subprocess.run(["sudo", "setfacl", "-m", f"u:{django_user}:x", f"/home/{clean_user}"], check=True)
            subprocess.run(["sudo", "setfacl", "-R", "-m", f"u:{django_user}:rx", maildir], check=True)
            subprocess.run(["sudo", "setfacl", "-R", "-d", "-m", f"u:{django_user}:r", maildir], check=True)

        return True
    except subprocess.CalledProcessError:
        return False