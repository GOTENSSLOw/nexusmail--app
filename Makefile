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
postfix-status:
	sudo systemctl status postfix

dovecot-status:
	sudo systemctl status dovecot

# Probar endpoints Django API
django-test-send:
	curl -X POST http://127.0.0.1:8000/api/send-email/ \
		-H "Content-Type: application/json" \
		-d '{"sender": "joao", "to":"uwu@lan.local","subject":"Hola","body":"Prueba"}' | jq 

django-test-read:
	curl -s -X GET "http://127.0.0.1:$(PORT)/api/read-emails/uwu/?password=uwu12345" \
		-H "Content-Type: application/json" | jq 

create-user:
	@read -p "Nombre de usuario: " USR; \
	PASS=$${USR}12345; \
	sudo useradd -m -s /bin/bash $$USR; \
	echo "$$USR:$$PASS" | sudo chpasswd; \
	sudo mkdir -p /home/$$USR/Maildir/{cur,new,tmp}; \
	sudo chown -R $$USR:$$USR /home/$$USR/Maildir; \
	sudo chmod -R 700 /home/$$USR/Maildir; \
	sudo setfacl -m u:$(DJANGO_USER):x /home/$$USR; \
	# ACLs: rx para entrar a carpetas y r para leer archivos \
	sudo setfacl -R -m u:$(DJANGO_USER):rx /home/$$USR/Maildir; \
	# Establecer ACL por defecto para futuros correos \
	sudo setfacl -R -d -m u:$(DJANGO_USER):r /home/$$USR/Maildir; \
	echo "------------------------------------------------"; \
	echo "Usuario: $$USR"; \
	echo "Password: $$PASS"; \
	echo "Maildir configurado para $(DJANGO_USER)"; \
	echo "------------------------------------------------"

# Eliminar usuario de prueba
delete-user:
	@read -p "Nombre de usuario: " USER; \
	sudo userdel -r $$USER

get-users:
	ls /home
