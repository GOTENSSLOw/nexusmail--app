import hashlib
from datetime import datetime

from django.core.mail import send_mail
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.contrib.auth.models import User
<<<<<<< HEAD
from django.conf import settings
from .models import EmailMessage

from .services.system_service import create_system_user
from .services.email_service import get_inbox_from_imap, sync_emails_with_db
from .validators import sanitize_username, is_valid_username

@api_view(['POST'])
def send_email(request):
    sender = request.data.get('sender')
    to = request.data.get('to')
    subject = request.data.get('subject')
    body = request.data.get('body')

    if not sender or not to:
        return Response({"error": "sender and to required"}, status=400)

    try:
        user_obj = User.objects.get(username=sender)
    except User.DoesNotExist:
        return Response({"error": "Sender user not found in DB"}, status=404)

    # 1. Enviar correo real
    send_mail(
        subject,
        body,
        f"{sender}@{settings.MAIL_DOMAIN}",
        [to],
        fail_silently=False,
    )

    # 2. Guardar en DB para el Frontend
    email_obj = EmailMessage.objects.create(
        user=user_obj,
        message_id_hash=hashlib.sha256(f"{sender}-{to}-{subject}-{datetime.now().isoformat()}".encode()).hexdigest()[:64],
        recipient=to,
        sender=f"{sender}@{settings.MAIL_DOMAIN}",
        subject=subject,
        body=body,
        unread=False
    )
    return Response({
        "status": "email sent",
        "id": email_obj.id
    })

@api_view(['POST'])
def register_user(request):
    raw_username = request.data.get('username')
    password = request.data.get('password')

    if not raw_username or not password:
        return Response({"error": "Username and password are required"}, status=400)

    username = sanitize_username(raw_username)
    if not is_valid_username(username):
        return Response({"error": "Invalid username format"}, status=400)

    try:
        if User.objects.filter(username=username).exists():
            return Response({"error": "User already exists"}, status=400)
        
        User.objects.create_user(username=username, password=password)
        success = create_system_user(username, password)
        
        if not success:
            User.objects.filter(username=username).delete()
            return Response({"error": "System configuration failed"}, status=500)

        return Response({
            "message": "User registered successfully",
            "username": username
        }, status=201)

    except Exception as e:
        return Response({"error": str(e)}, status=500)

@api_view(['POST'])
def read_emails(request, username):
    password = request.data.get('password')
    if not password:
        return Response({"error": "Password required"}, status=400)

    safe_user = sanitize_username(username)
    
    try:
        user_obj = User.objects.get(username=safe_user)
        
        # Sincronizamos (Polling)
        sync_emails_with_db(user_obj, password)
        
        # Consultamos DB enriquecida
        emails = EmailMessage.objects.filter(user=user_obj).order_by('-time')
        
        payload = [{
            "id": e.id,
            "recipient": e.recipient,
            "subject": e.subject,
            "snippet": e.snippet, # Asegúrate de que el modelo genere esto en el save()
            "time": e.time.strftime("%Y-%m-%d %H:%M:%S"),
            "unread": e.unread
        } for e in emails]

        return Response(payload)

    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)
    except Exception as e:
        return Response({"error": f"Error: {str(e)}"}, status=500)