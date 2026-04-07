# Makefile para levantar Postfix, Dovecot y Django API en LAN

# Variables
DJANGO_DIR := ./backend
DJANGO_USER := void
VENV := $(DJANGO_DIR)/venv
HOST := 0.0.0.0
PORT := 8000

.PHONY: start stop restart status django-test postfix-test dovecot-test

# ----------------------------------------------------------------------
# Levantar todos los servicios
start:
	sudo systemctl start postfix
	sudo systemctl start dovecot
	@echo "Servicios Postfix y Dovecot iniciados"
	@echo "Iniciando Django API..."
	source $(VENV)/bin/activate && cd $(DJANGO_DIR) && python manage.py runserver $(HOST):$(PORT)

# Detener servicios
stop:
	sudo systemctl stop postfix
	sudo systemctl stop dovecot
	@echo "Servicios Postfix y Dovecot detenidos"

# Reiniciar servicios
restart:
	sudo systemctl restart postfix
	sudo systemctl restart dovecot
	@echo "Servicios Postfix y Dovecot reiniciados"

# Ver estado de servicios
status:
	sudo systemctl status postfix
	sudo systemctl status dovecot

# Probar envío de correo vía Postfix
postfix-test:
	echo "Mensaje de prueba" | mail -s "Test Postfix" user2@lan.local

# Probar conexión a Dovecot (IMAP)
dovecot-test:
	telnet 127.0.0.1 143
	@echo "Conecta con: a login user2 tu_contraseña"
	@echo "Luego: a select INBOX"
	@echo "Finalmente: a logout"

# Probar endpoints Django API
django-test-send:
	curl -X POST http://127.0.0.1:8000/api/send-email/ \
		-H "Content-Type: application/json" \
		-d '{"sender": "joao", "to":"uwu@lan.local","subject":"Hola","body":"Prueba"}'

django-test-read:
	curl -s -X GET "http://127.0.0.1:$(PORT)/api/read-emails/uwu/?password=uwu12345" \
		-H "Content-Type: application/json"

create-user:
	@read -p "Nombre de usuario: " USER; \
	PASS=$${USER}12345; \
	sudo useradd -m $$USER; \
	echo "$$USER:$$PASS" | sudo chpasswd; \
	sudo -u $$USER doveadm mailbox create -u $$USER INBOX; \
	sudo -u $$USER doveadm mailbox create -u $$USER Sent; \
	sudo -u $$USER doveadm mailbox create -u $$USER Trash; \
	sudo -u $$USER mkdir -p /home/$$USER/Maildir/{cur,new,tmp}; \
	# Aplicar ACL recursiva a todo el Maildir para que Django pueda leer
	sudo setfacl -R -m u:$(DJANGO_USER):rx /home/$$USER/Maildir; \
	sudo setfacl -R -m u:$(DJANGO_USER):r /home/$$USER/Maildir/cur; \
	sudo setfacl -R -m u:$(DJANGO_USER):r /home/$$USER/Maildir/new; \
	sudo setfacl -R -m u:$(DJANGO_USER):r /home/$$USER/Maildir/tmp; \
	echo "Usuario $$USER creado con Maildir listo y contraseña $$PASS para $(DJANGO_USER)"

# Eliminar usuario de prueba
delete-user:
	@read -p "Nombre de usuario: " USER; \
	sudo userdel -r $$USER

