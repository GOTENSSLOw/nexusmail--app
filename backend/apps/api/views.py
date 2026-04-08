from django.core.mail import send_mail
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response

from .models import EmailMessage 
from .services.system_service import create_system_user
from .services.email_service import sync_emails_with_db
from .validators import sanitize_username, is_valid_username

# --- REGISTRO (Público) ---
@api_view(['POST'])
@permission_classes([AllowAny])
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

        return Response({"message": "User registered successfully", "username": username}, status=201)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


# --- ENVIAR CORREO (Requiere Token) ---
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_email(request):
    # Sacamos la identidad del TOKEN, no del body
    user_obj = request.user 
    to = request.data.get('to')
    subject = request.data.get('subject')
    body = request.data.get('body')

    if not to or not subject:
        return Response({"error": "Recipient and subject required"}, status=400)
    
    # 1. Enviar vía SMTP (Postfix)
    try:
        send_mail(
            subject,
            body,
            f"{user_obj.username}@lan.local",
            [to],
            fail_silently=False,
        )

        # 2. Guardar en DB para historial
        email_obj = EmailMessage.objects.create(
            user=user_obj,
            recipient=to,
            sender=f"{user_obj.username}@lan.local",
            subject=subject,
            body=body,
            unread=False
        )
        return Response({"status": "email sent", "id": email_obj.id})
    except Exception as e:
        return Response({"error": f"Mail system error: {str(e)}"}, status=500)

# --- LEER CORREOS (Endpoint para la TUI /me/) ---
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def read_emails_me(request):
    user_obj = request.user
    password = request.query_params.get('password') 
    
    try:
        if password:
            sync_emails_with_db(user_obj, password)
        
        emails = EmailMessage.objects.filter(user=user_obj).order_by('-time')
        
        payload = [{
            "id": e.id,
            "recipient": e.recipient,
            "subject": e.subject,
            "snippet": e.snippet,
            "time": e.time.strftime("%Y-%m-%d %H:%M:%S"),
            "unread": e.unread
        } for e in emails]

        return Response(payload)
    except Exception as e:
        return Response({"error": str(e)}, status=500)

# --- MARCAR COMO LEÍDO ---
@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def mark_as_read(request, email_id):
    try:
        # Solo puedes marcar como leído TUS propios correos
        email_obj = EmailMessage.objects.get(id=email_id, user=request.user)
        email_obj.unread = False
        email_obj.save()
        return Response({"status": "read"})
    except EmailMessage.DoesNotExist:
        return Response({"error": "Email not found"}, status=404)