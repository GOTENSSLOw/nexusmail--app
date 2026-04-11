# Imagen base
FROM python:3.12-slim

# Variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Carpeta de trabajo
WORKDIR /app

# Copiar requirements (usar el archivo limpio de dependencias)
COPY requirements.windows.txt ./requirements.txt

# Instalar Python deps
RUN pip install --no-cache-dir -r requirements.txt

# Copiar proyecto
COPY . .

# Puerto
EXPOSE 8000

# Comando
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]