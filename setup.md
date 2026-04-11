# Project Setup

## Docker (Recomendado)

```bash
# Copiar env example
cp backend/.env.example backend/.env

# Levantar todo
make docker-up

# Ver logs
make docker-logs

# Bajar
make docker-down
```

Puertos: Frontend `:5173`, API `:8000`, SMTP `:25`, IMAP `:143`

Usuarios: user1/user112345, user2/user212345, user3/user312345

---

## VM Ubuntu (servidor de correo)

### Instalar servicios

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
make seed-users
# o manualmente:
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

---

## Desarrollo Local (Windows / Linux / macOS)

### Frontend

```bash
cd frontend
npm install
npm run dev
```

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Linux/macOS
# venv\Scripts\activate         # Windows

pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

---

## Variables de Entorno

Ver `backend/.env.example` para todas las variables disponibles.

| Variable | Default | Descripción |
|---|---|---|
| `DJANGO_SECRET_KEY` | insecure key | Clave secreta de Django |
| `DJANGO_DEBUG` | `False` | Modo debug |
| `MAIL_DOMAIN` | `lan.local` | Dominio de correo |
| `SMTP_HOST` | `127.0.0.1` | IP del servidor SMTP (Postfix) |
| `SMTP_PORT` | `25` | Puerto SMTP |
| `IMAP_HOST` | `127.0.0.1` | IP del servidor IMAP (Dovecot) |
| `DJANGO_SYSTEM_USER` | `ubuntu` | Usuario del sistema para ACLs |

---

## Make Targets

```bash
make help           # Ver todos los comandos
make vm-full-setup  # Instalar deps + migrar
make vm-full-start  # Levantar todo (VM)
make vm-full-stop   # Parar servicios
make docker-up      # Docker compose up
make docker-down    # Docker compose down
make create-user NAME=foo PASS=bar
make seed-users     # Crear user1/user2/user3
```
