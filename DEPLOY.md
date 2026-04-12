# NexusMail - Guía de Despliegue

Servidor de correo académico: Postfix + Dovecot + Django + React.

## Tabla de Contenidos

1. [Prerrequisitos](#1-prerrequisitos)
2. [Despliegue VM Completa](#2-despliegue-vm-completa)
3. [Despliegue Docker Compose](#3-despliegue-docker-compose)
4. [Despliegue Multi-PC](#4-despliegue-multi-pc)
5. [Variables de Entorno](#5-variables-de-entorno)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. Prerrequisitos

### VM Full Deployment (Ubuntu)

| Componente | Versión mínima | Comando de instalación |
|---|---|---|
| Ubuntu | 20.04+ | — |
| Python | 3.8+ | Incluido en Ubuntu |
| Node.js | 18+ | `curl -fsSL https://deb.nodesource.com/setup_18.x \| sudo bash - && sudo apt install -y nodejs` |
| Postfix | Cualquiera | `sudo apt install -y postfix` |
| Dovecot | Cualquiera | `sudo apt install -y dovecot-core dovecot-imapd dovecot-pop3d` |
| ACL | Cualquiera | `sudo apt install -y acl` |
| Git | Cualquiera | `sudo apt install -y git` |

### Docker Compose

| Componente | Versión mínima | Comando de instalación |
|---|---|---|
| Docker Engine | 20.10+ | [docs.docker.com/engine/install](https://docs.docker.com/engine/install/) |
| Docker Compose | 2.0+ | Incluido con Docker Desktop / `docker compose` plugin |
| Git | Cualquiera | `sudo apt install -y git` |

### Multi-PC

- **Servidor**: misma requisitos que VM Full (arriba)
- **Clientes**: solo un navegador web moderno (Chrome, Firefox, Edge)
- **Red**: todos los PCs en la misma red LAN

---

## 2. Despliegue VM Completa

Todo corre en una sola máquina Ubuntu. Postfix, Dovecot, Django y el frontend de Vite se levantan juntos.

### Paso 1: Clonar el repositorio

```bash
cd /opt
sudo git clone https://github.com/tu-org/nexusmail--app.git
cd nexusmail--app
```

### Paso 2: Instalar paquetes del sistema

```bash
sudo apt-get update
sudo apt-get install -y \
  postfix \
  dovecot-core \
  dovecot-imapd \
  dovecot-pop3d \
  python3-venv \
  python3-pip \
  acl \
  git
```

> Durante la instalación de Postfix, seleccionar **"Internet Site"** y poner como dominio `lan.local`.

### Paso 3: Configurar Postfix

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
sudo systemctl enable postfix
```

**¿Qué hace cada línea?**

| Comando | Propósito |
|---|---|
| `myhostname` | Nombre FQDN del servidor de correo |
| `mydomain` | Dominio base |
| `myorigin` | Dominio que se agrega a direcciones sin dominio |
| `mydestination` | Dominios para los que este servidor acepta correo |
| `inet_interfaces` | Escuchar en todas las interfaces |
| `inet_protocols` | Solo IPv4 (evita problemas en redes sin IPv6) |
| `home_mailbox` | Entregar correo en formato Maildir en el home del usuario |
| `mynetworks` | Redes autorizadas para reenviar correo (ajustar según tu red) |

### Paso 4: Configurar Dovecot

```bash
sudo tee /etc/dovecot/conf.d/99-local.conf > /dev/null << 'EOF'
mail_location = maildir:~/Maildir
ssl = no
disable_plaintext_auth = no
EOF
sudo systemctl restart dovecot
sudo systemctl enable dovecot
```

Esto habilita IMAP/POP3 sin TLS (solo para entornos de laboratorio/académicos, **no producción**).

### Paso 5: Crear usuarios del sistema

Opción A — usar Make (recomendado):

```bash
make seed-users
```

Opción B — manual:

```bash
for user in user1 user2 user3; do
  sudo useradd -m -s /bin/bash "$user"
  echo "$user:${user}12345" | sudo chpasswd
  sudo mkdir -p /home/$user/Maildir/{cur,new,tmp}
  sudo chown -R $user:$user /home/$user/Maildir
  sudo chmod -R 700 /home/$user/Maildir
done
```

Crear un usuario personalizado:

```bash
make create-user NAME=miusuario PASS=mipassword123
```

**Usuarios por defecto:**

| Usuario | Contraseña |
|---|---|
| user1 | user112345 |
| user2 | user212345 |
| user3 | user312345 |

### Paso 6: Configurar el backend

```bash
cd backend
cp .env.example .env
# Editar .env si es necesario (ver sección 5)

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
```

En una terminal separada (o con `screen`/`tmux`):

```bash
cd /opt/nexusmail--app/backend
source venv/bin/activate
python manage.py runserver 0.0.0.0:8000
```

### Paso 7: Configurar el frontend

```bash
cd frontend
npm install
npm run dev
```

> En producción, usar `npm run build` y servir el `dist/` con nginx.

### Paso 8: Abrir puertos en el firewall

```bash
sudo ufw allow 25/tcp    # SMTP (Postfix)
sudo ufw allow 110/tcp   # POP3 (Dovecot)
sudo ufw allow 143/tcp   # IMAP (Dovecot)
sudo ufw allow 8000/tcp  # Django API
sudo ufw allow 5173/tcp  # Frontend Vite
```

Verificar:

```bash
sudo ufw status
```

### Paso 9: Verificar que todo funciona

```bash
# Verificar que Postfix responde
telnet localhost 25

# Verificar que Dovecot IMAP responde
telnet localhost 143

# Verificar que Django responde
curl http://localhost:8000/api/

# Verificar que el frontend responde
curl http://localhost:5173/
```

Enviar un correo de prueba:

```bash
echo "Test body" | mail -s "Test Subject" user1@lan.local
```

### Paso 10: Acceder desde el navegador

- **Frontend**: `http://<ip-servidor>:5173/`
- **Django Admin**: `http://<ip-servidor>:8000/admin/`

Para obtener la IP del servidor:

```bash
ip addr show | grep 'inet ' | grep -v 127.0.0.1
```

### Atajos con Make

```bash
make vm-full-setup   # Instalar deps + migrar
make vm-full-start   # Levantar todo (Postfix + Dovecot + Django + Vite)
make vm-full-stop    # Parar servicios
```

---

## 3. Despliegue Docker Compose

Todo corre en contenedores. No necesitas instalar Postfix ni Dovecot en el host.

### Paso 1: Prerrequisitos

```bash
# Verificar Docker
docker --version
docker compose version

# Si no tenés Docker:
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker $USER
# Cerrá y reabrí la sesión
```

### Paso 2: Clonar el repositorio

```bash
git clone https://github.com/tu-org/nexusmail--app.git
cd nexusmail--app
```

### Paso 3: Configurar variables de entorno

```bash
cp backend/.env.example backend/.env
```

Opcionalmente, editar `backend/.env` para personalizar dominio, claves, etc.

### Paso 4: Construir imágenes

```bash
make docker-build
# o directamente:
docker compose build
```

### Paso 5: Levantar servicios

```bash
make docker-up
# o directamente:
docker compose up -d
```

### Paso 6: Verificar logs

```bash
make docker-logs
# o directamente:
docker compose logs -f
```

Para ver logs de un servicio específico:

```bash
docker compose logs -f django
docker compose logs -f postfix
docker compose logs -f dovecot
```

### Paso 7: Verificar que cada servicio está corriendo

```bash
docker compose ps
```

Deberías ver 5 servicios con estado `Up`:

| Servicio | Estado esperado | Puerto |
|---|---|---|
| postfix | Up | 25 |
| dovecot | Up | 143, 110 |
| init | Exited (0) — es normal, corre una vez | — |
| django | Up | 8000 |
| frontend | Up | 5173 |

### Paso 8: Acceder desde el navegador

- **Frontend**: `http://localhost:5173/`
- **Django Admin**: `http://localhost:8000/admin/`

Si accedés desde otra máquina en la red:
- `http://<ip-servidor>:5173/`
- `http://<ip-servidor>:8000/admin/`

### Paso 9: Agregar usuarios

Los usuarios por defecto se crean automáticamente (user1/user2/user3).

Para agregar usuarios personalizados, editar las variables en `docker-compose.yml` o pasarlas como variables de entorno del host:

```bash
export USERS="user1,user2,user3,nuevo"
export USER_PASSWORDS="user112345,user212345,user312345,nuevopass"
docker compose up -d init
```

O recrear el contenedor init:

```bash
docker compose run --rm -e USERS="user1,user2,user3,admin4" \
  -e USER_PASSWORDS="user112345,user212345,user312345,admin456" \
  init
```

### Paso 10: Detener servicios

```bash
make docker-down
# o directamente:
docker compose down
```

Para borrar también los volúmenes (datos de correo y BD):

```bash
docker compose down -v
```

### Arquitectura Docker

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│ Postfix │     │ Dovecot │     │  Init   │
│  :25    │     │ :143    │     │ (once)  │
└────┬────┘     └────┬────┘     └────┬────┘
     │               │               │
     └───────┬───────┘               │
             │                       │
         ┌───┴───┐              ┌────┴────┐
         │ maildata volume       │ userdb  │
         └───┬───┘              │ volume  │
             │                  └────┬────┘
     ┌───────┴───────┐              │
     │               │              │
┌────┴────┐    ┌─────┴─────┐        │
│ Django  │    │  Frontend │        │
│ :8000   │    │  :5173    │        │
└─────────┘    └───────────┘        │
             Network: nexus (bridge)
```

---

## 4. Despliegue Multi-PC

Un servidor central + N PCs clientes que acceden por navegador. Ideal para laboratorios y demos de red.

### Paso 1: Configurar el servidor

Seguir los pasos de la **Sección 2 (VM Full Deployment)** en la máquina que actuará como servidor.

**Importante**: verificar que la IP del servidor sea estática o bien conocida:

```bash
# En el servidor
ip addr show | grep 'inet ' | grep -v 127.0.0.1
# Ejemplo: 192.168.1.100
```

### Paso 2: Verificar firewall en el servidor

```bash
sudo ufw status
# Debe mostrar abierto: 25, 110, 143, 8000, 5173
```

Si falta algún puerto:

```bash
sudo ufw allow 25/tcp
sudo ufw allow 110/tcp
sudo uuf allow 143/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 5173/tcp
```

### Paso 3: Acceder desde los clientes

Los PCs clientes solo necesitan un navegador. Abrir:

```
http://<ip-del-servidor>:5173/
```

Ejemplo: `http://192.168.1.100:5173/`

La API de Django está en:

```
http://<ip-del-servidor>:8000/
```

### Paso 4: Capturar tráfico SMTP/IMAP con Wireshark

En el **servidor**, instalar Wireshark o `tshark`:

```bash
sudo apt install -y tshark
```

Capturar tráfico SMTP (puerto 25):

```bash
sudo tshark -i any -f "tcp port 25" -Y "smtp"
```

Capturar tráfico IMAP (puerto 143):

```bash
sudo tshark -i any -f "tcp port 143" -Y "imap"
```

Capturar ambos simultáneamente:

```bash
sudo tshark -i any -f "tcp port 25 or tcp port 143" -w /tmp/nexusmail-capture.pcap
```

Abrir el `.pcap` en Wireshark GUI para análisis detallado:

```bash
wireshark /tmp/nexusmail-capture.pcap &
```

**Filtros útiles en Wireshark:**

| Filtro | Qué muestra |
|---|---|
| `smtp` | Todo el tráfico SMTP |
| `imap` | Todo el tráfico IMAP |
| `smtp.req.command` | Comandos SMTP enviados |
| `imap.request` | Requests IMAP |
| `tcp.port == 25` | Todo en puerto 25 |
| `ip.addr == 192.168.1.50` | Tráfico de un cliente específico |

---

## 5. Variables de Entorno

Archivo: `backend/.env`

| Variable | Default | Descripción |
|---|---|---|
| `DJANGO_SECRET_KEY` | `django-insecure-dev-key` | Clave secreta de Django. **Cambiar en producción.** |
| `DJANGO_DEBUG` | `False` | Modo debug de Django |
| `DJANGO_SETTINGS_MODULE` | `config.settings` | Módulo de settings de Django |
| `MAIL_DOMAIN` | `lan.local` | Dominio de correo (ej: `universidad.edu`) |
| `SMTP_HOST` | `127.0.0.1` | IP/hostname del servidor SMTP (Postfix). En Docker: `postfix` |
| `SMTP_PORT` | `25` | Puerto SMTP |
| `IMAP_HOST` | `127.0.0.1` | IP/hostname del servidor IMAP (Dovecot). En Docker: `dovecot` |
| `IMAP_PORT` | `143` | Puerto IMAP |
| `DJANGO_SYSTEM_USER` | `ubuntu` | Usuario del sistema para ACLs del Maildir |

Variables específicas de Docker (definidas en `docker-compose.yml`):

| Variable | Default | Descripción |
|---|---|---|
| `USERS` | `user1,user2,user3` | Lista de usuarios separados por coma |
| `USER_PASSWORDS` | `user112345,user212345,user312345` | Contraseñas en el mismo orden que `USERS` |
| `DOCKER_CONTAINER` | `true` | Flag interno para modo container |

---

## 6. Troubleshooting

### Error: "Address already in use" / Conflicto de puertos

**Síntoma**: Postfix o Dovecot no arrancan, el error dice que el puerto está en uso.

```bash
# Ver qué proceso usa el puerto
sudo ss -tlnp | grep ':25\|:143\|:8000\|:5173'

# Si es un proceso viejo, matarlo
sudo fuser -k 25/tcp
sudo fuser -k 143/tcp
```

En Docker, verificar que no haya Postfix/Dovecot corriendo en el host:

```bash
sudo systemctl stop postfix
sudo systemctl stop dovecot
```

### Error: Firewall bloqueando conexiones

**Síntoma**: No se puede acceder desde otra máquina en la red.

```bash
# Verificar reglas
sudo ufw status verbose

# Abrir puertos necesarios
sudo ufw allow 25/tcp
sudo ufw allow 110/tcp
sudo ufw allow 143/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 5173/tcp

# Verificar conectividad desde el cliente
nc -zv <ip-servidor> 25
nc -zv <ip-servidor> 143
nc -zv <ip-servidor> 8000
nc -zv <ip-servidor> 5173
```

### Error: Usuarios no creados

**Síntoma**: Login falla, no se puede enviar/recibir correo.

**En VM:**

```bash
# Verificar usuarios
getent passwd user1 user2 user3

# Si no existen, crearlos
make seed-users

# Verificar Maildir
ls -la /home/user1/Maildir/
# Debe haber carpetas: cur/ new/ tmp/
```

**En Docker:**

```bash
# Ver logs del init container
docker compose logs init

# Recrear usuarios
docker compose run --rm init
```

### Error: Dovecot auth falla

**Síntoma**: No se puede hacer login IMAP, error de autenticación.

**En VM:**

```bash
# Verificar que Dovecot esté corriendo
sudo systemctl status dovecot

# Ver logs
sudo journalctl -u dovecot -f

# Verificar configuración
sudo dovecot -n | grep -A2 "ssl\|auth\|mail_location"

# Reiniciar
sudo systemctl restart dovecot
```

**En Docker:**

```bash
# Ver logs de Dovecot
docker compose logs dovecot

# Verificar que el archivo passwd existe
docker compose exec dovecot cat /etc/userdb/passwd

# Si está vacío, recrear el init
docker compose down
docker compose up -d init
docker compose up -d dovecot
```

### Error: CORS desde el frontend

**Síntoma**: El navegador muestra errores CORS en la consola.

**Solución**: Verificar que Django tenga CORS configurado.

```bash
# En backend/config/settings.py debe existir:
# CORS_ALLOWED_ORIGINS = ["http://localhost:5173"]
# o para desarrollo:
# CORS_ALLOW_ALL_ORIGINS = True
```

Si accedés desde otra IP (multi-PC), agregar esa IP:

```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:5173",
    "http://192.168.1.100:5173",
]
```

### Error: Dovecot no arranca en Docker

**Síntoma**: `docker compose logs dovecot` muestra errores de configuración.

```bash
# Verificar que el archivo de config se monta correctamente
docker compose exec dovecot cat /etc/dovecot/dovecot.conf

# Reiniciar el servicio
docker compose restart dovecot
```

### Django no conecta a Postfix/Dovecot en Docker

**Síntoma**: Errores de conexión al enviar correo.

Verificar que Django use los nombres del servicio Docker como hostname:

```bash
docker compose exec django env | grep -E "SMTP_HOST|IMAP_HOST"
# Debe mostrar: SMTP_HOST=postfix, IMAP_HOST=dovecot
```

### Reinicio completo (nuclear option)

Si nada funciona, empezar de cero:

**VM:**

```bash
make vm-full-stop
cd backend && rm -rf venv db.sqlite3
cd ../frontend && rm -rf node_modules
make vm-full-setup
make seed-users
make vm-full-start
```

**Docker:**

```bash
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

---

## Referencia Rápida de Puertos

| Servicio | Puerto | Protocolo | Uso |
|---|---|---|---|
| Postfix SMTP | 25 | TCP | Envío de correo |
| Dovecot POP3 | 110 | TCP | Lectura de correo (legacy) |
| Dovecot IMAP | 143 | TCP | Lectura de correo |
| Django API | 8000 | TCP | Backend REST API |
| Vite Frontend | 5173 | TCP | Interfaz web |

## Referencia Rápida de Make

```bash
make help             # Ver todos los comandos
make vm-full-setup    # Instalar deps + migrar
make vm-full-start    # Levantar todo (VM)
make vm-full-stop     # Parar servicios (VM)
make docker-build     # Construir imágenes Docker
make docker-up        # docker compose up -d
make docker-down      # docker compose down
make docker-logs      # docker compose logs -f
make create-user NAME=foo PASS=bar  # Crear usuario individual
make seed-users       # Crear user1/user2/user3
make migrate          # Ejecutar migraciones Django
make clean            # Borrar todo (volúmenes, venv, node_modules)
```
