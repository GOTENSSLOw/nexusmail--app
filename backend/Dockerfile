# Imagen base
FROM python:3.12-slim

# Variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Carpeta de trabajo
WORKDIR /app

# Copiar requirements
COPY requirements.txt .

# Instalar Python deps
RUN pip install --no-cache-dir -r requirements.txt

# Copiar proyecto
COPY . .

# Puerto
EXPOSE 8000

# Comando
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]