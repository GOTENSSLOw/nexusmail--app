# Imagen base
FROM python:3.12-slim

# Variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Carpeta de trabajo
WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements
COPY requirements.txt .

# Instalar Python deps
RUN pip install --no-cache-dir -r requirements.txt

# Copiar proyecto
COPY . .

# Puerto
EXPOSE 8000

# Comando
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]