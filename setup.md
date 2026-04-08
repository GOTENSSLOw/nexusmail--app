# Project Setup

< var >: variable

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