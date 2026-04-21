# NexusMail — Deploy

Servidor de correo académico: Postfix + Dovecot + Django + React.

```
┌─────────────────────────────────────────────────────────────┐
│                     NexusMail Architecture                   │
│                                                             │
│  ┌──────────┐     ┌─────────┐     ┌──────────┐             │
│  │  Postfix │     │ Dovecot │     │   Init   │             │
│  │  SMTP :25│     │ IMAP:143│     │  (once)  │             │
│  └─────┬────┘     └────┬────┘     └────┬─────┘             │
│        │               │               │                   │
│        └───────┬───────┘               │                   │
│         ┌──────┴──────┐        ┌───────┴─────┐             │
│         │ mail volume │        │  userdb     │             │
│         └──────┬──────┘        │  volume     │             │
│    ┌───────────┴───────────┐   └───────┬─────┘             │
│    │                       │           │                   │
│ ┌──┴───┐            ┌──────┴───┐       │                   │
│ │Django│            │ Frontend │       │                   │
│ │:8000 │            │  :5173   │       │                   │
│ └──────┘            └──────────┘       │                   │
│         Network: bridge (nexus)        │                   │
└─────────────────────────────────────────────────────────────┘
```

## Prerrequisitos

### VM (Ubuntu/Debian con systemd)

| Componente | Mínimo | Instalación |
|---|---|---|
| Ubuntu | 20.04+ | — |
| Docker Engine | 20.10+ | [docs.docker.com/engine/install](https://docs.docker.com/engine/install/) |
| Docker Compose | 2.0+ | Incluido con Docker Desktop / `docker compose` plugin |
| Git | cualquier | `sudo apt install -y git` |

> Para despliegue **sin** Docker ni systemd (macOS, WSL), usar `scripts/start-all.sh` directamente.

### Docker Only

| Componente | Mínimo | Instalación |
|---|---|---|
| Docker Engine | 20.10+ | [docs.docker.com/engine/install](https://docs.docker.com/engine/install/) |
| Docker Compose | 2.0+ | Incluido con Docker Desktop / `docker compose` plugin |
| Git | cualquier | `sudo apt install -y git` |

---

## Quick Start

### Docker
```bash
./scripts/start-docker.sh          # start
./scripts/start-docker.sh --stop   # stop
./scripts/start-docker.sh --status # status
./scripts/start-docker.sh --rebuild # rebuild
./scripts/start-docker.sh --logs  # follow logs
```

### VM (Ubuntu/Debian con systemd)
```bash
./scripts/start-vm.sh             # start all
./scripts/start-vm.sh --stop      # stop all
./scripts/start-vm.sh --status    # status
./scripts/start-vm.sh --init      # init only (migrations, users)
./scripts/start-vm.sh --logs      # follow logs
```

### Dev (Backend VM + Frontend hot-reload)
```bash
./scripts/start-mixed.sh           # frontend runs in foreground
./scripts/start-mixed.sh --stop    # stop all
./scripts/start-mixed.sh --status  # status
```

### All-native (sin Docker, sin systemd — macOS, WSL)
```bash
./scripts/start-all.sh             # start all
./scripts/start-all.sh --stop      # stop all
./scripts/start-all.sh --status     # status
```

---

## Makefile

| Target | Descripción |
|---|---|
| `make vm-full-setup` | Instalar deps + migrar |
| `make vm-full-start` | Levantar todo (Postfix + Dovecot + Django + Vite) |
| `make vm-full-stop` | Parar servicios |
| `make docker-up` | `docker compose up -d` |
| `make docker-down` | `docker compose down` |
| `make docker-build` | Construir imágenes |
| `make docker-logs` | `docker compose logs -f` |
| `make seed-users` | Crear user1/user2/user3 |
| `make create-user NAME=x PASS=y` | Crear usuario individual |
| `make migrate` | Ejecutar migraciones Django |
| `make clean` | Borrar todo (volúmenes, venv, node_modules) |

---

## Puertos

| Servicio | Puerto | Protocolo | Uso |
|---|---|---|---|
| Postfix SMTP | 25 | TCP | Envío de correo |
| Dovecot POP3 | 110 | TCP | Lectura legacy |
| Dovecot IMAP | 143 | TCP | Lectura de correo |
| Django API | 8000 | TCP | Backend REST API |
| Vite Frontend | 5173 | TCP | Interfaz web |

---

## Variables de Entorno

### Archivos `.env`

| Archivo | Propósito |
|---|---|
| `.env` (raíz) | Variables globales para Docker Compose |
| `backend/.env.example` | Plantilla para setups sin Docker |
| `frontend/.env` | Opcional: sobrescribe `VITE_API_URL` |

### Variables principales

| Variable | Default | Descripción |
|---|---|---|
| `DJANGO_SECRET_KEY` | `django-insecure-dev-key` | Clave secreta Django (**cambiar en producción**) |
| `DJANGO_DEBUG` | `False` | Modo debug |
| `MAIL_DOMAIN` | `lan.local` | Dominio de correo |
| `SMTP_HOST` | `127.0.0.1` | Host SMTP (Docker: `postfix`) |
| `SMTP_PORT` | `25` | Puerto SMTP |
| `IMAP_HOST` | `127.0.0.1` | Host IMAP (Docker: `dovecot`) |
| `IMAP_PORT` | `143` | Puerto IMAP |

### Variables Docker-only

| Variable | Default | Descripción |
|---|---|---|
| `USERS` | `user1,user2,user3` | Usuarios separados por coma |
| `USER_PASSWORDS` | `user112345,user212345,user312345` | Contraseñas en mismo orden |

---

## Acceso

```bash
# Obtener IP del servidor
ip addr show | grep 'inet ' | grep -v 127.0.0.1

# URLs (reemplazar <ip> con la IP del servidor)
Frontend:     http://<ip>:5173/
Django API:    http://<ip>:8000/
Django Admin:  http://<ip>:8000/admin/
```

**Usuarios por defecto:** user1/user112345, user2/user212345, user3/user312345

---

## Troubleshooting

### "Address already in use"
```bash
sudo ss -tlnp | grep ':25\|:143\|:8000\|:5173'
sudo fuser -k 25/tcp 143/tcp 8000/tcp 5173/tcp
```

### Firewall bloqueando
```bash
sudo ufw allow 25/tcp 110/tcp 143/tcp 8000/tcp 5173/tcp
nc -zv <ip-servidor> 25  # verificar conectividad
```

### Usuarios no creados (Docker)
```bash
docker compose logs init
docker compose run --rm init
```

### Dovecot auth falla
```bash
# VM
sudo systemctl status dovecot
sudo journalctl -u dovecot -f

# Docker
docker compose logs dovecot
docker compose exec dovecot cat /etc/userdb/passwd
```

### Nuclear reset

**VM:**
```bash
./scripts/start-vm.sh --stop
cd backend && rm -rf venv db.sqlite3
./scripts/start-vm.sh --init
./scripts/start-vm.sh
```

**Docker:**
```bash
./scripts/start-docker.sh --stop
docker compose down -v
./scripts/start-docker.sh --rebuild
```

---

## Scripts

| Script | Propósito |
|---|---|
| `scripts/start-docker.sh` | Wrapper Docker Compose |
| `scripts/start-vm.sh` | Levanta servicios nativos en VM |
| `scripts/start-mixed.sh` | Backend VM + frontend hot-reload |
| `scripts/start-all.sh` | Todo nativo sin Docker/systemd |
| `scripts/init-container.sh` | Inicializa contenedor init (usuarios, Dovecot DB) |
| `scripts/create-user.sh` | Crear usuarios manual en VM |