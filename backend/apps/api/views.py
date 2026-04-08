# Create your views here.
from django.core.mail import send_mail
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .utils import create_system_user, get_inbox, is_valid_username, sanitize_username
from django.contrib.auth.models import User

@api_view(['POST'])
def send_email(request):
    sender = request.data.get('sender')
    to = request.data.get('to')
    subject = request.data.get('subject')
    body = request.data.get('body')

    if not sender or not to:
        return Response({"error": "sender and to required"}, status=400)

    send_mail(
        subject,
        body,
        f"{sender}@lan.local",  # Remitente dinámico
        [to],
        fail_silently=False,
    )
    return Response({"status": "email sent"})


@api_view(['POST'])
def register_user(request):
    raw_username = request.data.get('username')
    password = request.data.get('password')

    if not raw_username or not password:
        return Response({"error": "Username and password are required"}, status=400)

    # 1. Validar y Sanitizar
    username = sanitize_username(raw_username)
    if not is_valid_username(username):
        return Response({"error": "Invalid username format"}, status=400)

    try:
        # 2. Crear en base de datos Django (para persistencia interna)
        if User.objects.filter(username=username).exists():
            return Response({"error": "User already exists"}, status=400)
        
        User.objects.create_user(username=username, password=password)

        # 3. Crear en el Sistema (Postfix/Dovecot/Linux)
        # Usamos tu función de utils.py
        success = create_system_user(username, password)
        
        if not success:
            # Si falla el sistema, borramos de Django para no quedar inconsistentes
            User.objects.filter(username=username).delete()
            return Response({"error": "System configuration failed"}, status=500)

        return Response({
            "message": "User registered successfully",
            "username": username
        }, status=201)

    except Exception as e:
        return Response({"error": str(e)}, status=500)

@api_view(['GET'])
def read_emails(request, username):
    password = request.query_params.get('password')
    
    if not password:
        return Response({"error": "Password required"}, status=400)

    # Sanitizamos el username del path por seguridad
    safe_user = sanitize_username(username)

    try:
        # Usamos tu función get_inbox de utils.py
        emails = get_inbox(safe_user, password)
        return Response(emails)
    except Exception as e:
        # Esto atrapará errores de login de imaplib si la contraseña está mal
        return Response({"error": f"IMAP Error: {str(e)}"}, status=500)