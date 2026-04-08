import subprocess
from ..validators import sanitize_username, is_valid_username

def create_system_user(username, password):
    clean_user = sanitize_username(username)
    if not is_valid_username(clean_user):
        raise ValueError("Nombre de usuario inválido.")

    try:
        # Crear usuario
        subprocess.run(["sudo", "useradd", "-m", clean_user], check=True)
        
        # Cambiar contraseña
        chpasswd_proc = subprocess.Popen(["sudo", "chpasswd"], stdin=subprocess.PIPE, text=True)
        chpasswd_proc.communicate(input=f"{clean_user}:{password}")

        # Configurar Maildir y Permisos
        maildir = f"/home/{clean_user}/Maildir"
        subprocess.run(["sudo", "mkdir", "-p", f"{maildir}/cur", f"{maildir}/new", f"{maildir}/tmp"], check=True)
        subprocess.run(["sudo", "chown", "-R", f"{clean_user}:{clean_user}", maildir], check=True)
        
        # ACLs (Asegúrate de que 'void' es el usuario que corre Django)
        subprocess.run(["sudo", "setfacl", "-m", "u:void:x", f"/home/{clean_user}"], check=True)
        subprocess.run(["sudo", "setfacl", "-R", "-m", "u:void:rx", maildir], check=True)
        
        return True
    except subprocess.CalledProcessError:
        return False