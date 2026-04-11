# Project Setup

< var >: variable

## Docker Deployment (Recommended)

### Quick Start
```bash
# Levantar todos los servicios
docker compose up -d

# Ver logs
docker compose logs -f

# Bajar servicios
docker compose down
```

### Environment Setup
```bash
cp backend/.env.example backend/.env
# Editar backend/.env con valores deseados
```

### Puertos Expuestos
- Frontend: http://localhost:5173
- Django API: http://localhost:8000
- SMTP: localhost:25
- IMAP: localhost:143

### Usuarios Docker Default
- user1/user112345
- user2/user212345
- user3/user312345

## VM Deployment (Manual)

### Requisitos
- Python 3.x con venv
- Postfix configurado para `lan.local`
- Dovecot configurado para IMAP
- Nginx o similar para servir frontend

### Variables de Entorno
```
DJANGO_SECRET_KEY=change-me-in-production
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=*
MAIL_DOMAIN=lan.local
SMTP_HOST=127.0.0.1
SMTP_PORT=25
SMTP_USER=
SMTP_PASSWORD=
DEFAULT_FROM_EMAIL=user1@lan.local
IMAP_HOST=127.0.0.1
DJANGO_SYSTEM_USER=ubuntu
```

## First time setup

### Frontend

```
cd frontend
npm install
npm run dev
```

### Backend

```
cd backend
python -m venv venv
venv\Scripts\Activate.ps1
pip install -r requirements.<windows/linux>.txt
python manage.py createsuperuser
<username> (ej: rossm)
<email> (admin@gmail.com)
<password> (123)
python manage.py runserver
```

## Run

## Frontend

```
cd frontend
npm run dev
```

### Backend

```
cd backend
venv\Scripts\Activate.ps1
python manage.py runserver
```
