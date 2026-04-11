.PHONY: help vm-full-setup vm-full-start vm-full-stop \
        docker-up docker-down docker-build docker-logs \
        create-user seed-users migrate clean

# === HELP ===
help:
	@echo "NexusMail - Multi-Mode Deployment"
	@echo ""
	@echo "VM Full (todo en la VM):"
	@echo "  make vm-full-setup    Instalar deps y migrar"
	@echo "  make vm-full-start    Levantar todo (Postfix+Dovecot+Django+Vite)"
	@echo "  make vm-full-stop     Parar servicios"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-up        docker compose up -d"
	@echo "  make docker-down      docker compose down"
	@echo "  make docker-build     docker compose build"
	@echo "  make docker-logs      docker compose logs -f"
	@echo ""
	@echo "Utilidades:"
	@echo "  make create-user NAME=foo PASS=bar"
	@echo "  make seed-users       Crear user1/user2/user3"
	@echo "  make migrate          Ejecutar migraciones"

# === VM FULL ===
vm-full-setup:
	cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python manage.py migrate

vm-full-start:
	sudo systemctl start postfix
	sudo systemctl start dovecot
	cd frontend && npm run dev &
	cd backend && source venv/bin/activate && python manage.py runserver 0.0.0.0:8000

vm-full-stop:
	sudo systemctl stop postfix
	sudo systemctl stop dovecot
	pkill -f "manage.py runserver" 2>/dev/null || true
	pkill -f "vite" 2>/dev/null || true

# === DOCKER ===
docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-build:
	docker compose build --no-cache

docker-logs:
	docker compose logs -f

# === UTILITIES ===
create-user:
	sudo useradd -m -s /bin/bash $(NAME)
	echo "$(NAME):$(PASS)" | sudo chpasswd
	sudo mkdir -p /home/$(NAME)/Maildir/{cur,new,tmp}
	sudo chown -R $(NAME):$(NAME) /home/$(NAME)/Maildir
	sudo chmod -R 700 /home/$(NAME)/Maildir
	@echo "User $(NAME) created with password $(PASS)"

seed-users:
	@for u in user1 user2 user3; do \
		$(MAKE) create-user NAME=$$u PASS=$${u}12345; \
	done

migrate:
	cd backend && source venv/bin/activate && python manage.py migrate

clean:
	docker compose down -v 2>/dev/null || true
	cd backend && rm -rf venv db.sqlite3
	cd frontend && rm -rf node_modules dist
