# Project Setup

## Frontend

```bash
cd frontend
npm install
npm run dev
```

## Backend

### 1. Crear entorno virtual

```bash
cd backend
python -m venv venv
```

### 2. Activar entorno

**Linux / macOS:**
```bash
source venv/bin/activate
```

**Windows (CMD):**
```bash
venv\Scripts\activate.bat
```

**Windows (PowerShell):**
```powershell
venv\Scripts\Activate.ps1
```

### 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 4. Migrar base de datos

```bash
python manage.py migrate
```

### 5. Crear superusuario

```bash
python manage.py createsuperuser
```

### 6. Iniciar servidor

```bash
python manage.py runserver
```

Para acceso desde la LAN (VM o red local):

```bash
python manage.py runserver 0.0.0.0:8000
```

---

## Docker

```bash
cd backend
docker build -t nexusmail-backend .
docker run -p 8000:8000 nexusmail-backend
```

---

## VM Ubuntu (servidor de correo)

### Instalar servicios del sistema

```bash
sudo apt-get update
sudo apt-get install -y postfix dovecot-core dovecot-imapd dovecot-pop3d python3-venv python3-pip acl
```

### Configurar Postfix

```bash
sudo postconf -e 'myhostname = mail.lan.local'
sudo postconf -e 'mydomain = lan.local'
sudo postconf -e 'myorigin = lan.local'
sudo postconf -e 'mydestination = mail.lan.local, localhost.lan.local, localhost, lan.local'
sudo postconf -e 'inet_interfaces = all'
sudo postconf -e 'inet_protocols = ipv4'
sudo postconf -e 'home_mailbox = Maildir/'
sudo postconf -e 'mynetworks = 127.0.0.0/8, 192.168.0.0/24'
sudo systemctl restart postfix
```

### Configurar Dovecot

```bash
cat | sudo tee /etc/dovecot/conf.d/99-local.conf << 'EOF'
mail_location = maildir:~/Maildir
ssl = no
disable_plaintext_auth = no
EOF
sudo systemctl restart dovecot
```

### Crear usuarios de prueba

```bash
for user in user1 user2 user3; do
  sudo useradd -m -s /bin/bash "$user"
  echo "$user:${user}12345" | sudo chpasswd
  sudo mkdir -p /home/$user/Maildir/{cur,new,tmp}
  sudo chown -R $user:$user /home/$user/Maildir
  sudo chmod -R 700 /home/$user/Maildir
done
```

### Abrir firewall

```bash
sudo ufw allow 25/tcp    # SMTP
sudo ufw allow 110/tcp   # POP3
sudo ufw allow 143/tcp   # IMAP
sudo ufw allow 8000/tcp  # Django
sudo ufw allow 5173/tcp  # Vite
```

### Levantar backend + frontend

```bash
# Backend
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000

# Frontend (otra terminal)
cd frontend
npm install
npm run dev
```
