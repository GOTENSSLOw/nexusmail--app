# Create your views here.
from django.core.mail import send_mail
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .utils import get_inbox

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


@api_view(['GET'])
def read_emails(request, username):
    password = request.query_params.get('password')
    if not password:
        return Response({"error": "Password required"}, status=400)
    emails = get_inbox(username, password)
    return Response(emails)