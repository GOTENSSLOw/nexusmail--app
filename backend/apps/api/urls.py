from django.urls import path

from apps.api.models import UserProfile
from . import views
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

class MyTokenObtainPairView(TokenObtainPairView):
    def post(self, request, *args, **kwargs):
        # 1. Capturamos los datos del intento de login
        username = request.data.get('username')
        password = request.data.get('password')
        
        # 2. Llamamos a la lógica original de SimpleJWT para validar y generar el token
        response = super().post(request, *args, **kwargs)
        
        # 3. Si el login fue exitoso (status 200), guardamos la clave plana
        if response.status_code == 200:
            from django.contrib.auth.models import User
            user = User.objects.get(username=username)
            
            # Guardamos o actualizamos el perfil con la clave de la demo
            profile, _ = UserProfile.objects.get_or_create(user=user)
            profile.imap_password = password
            profile.save()
            
        return response
    
urlpatterns = [
    # Autenticación
    path('login/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('register/', views.register_user, name='register_user'),

    # Acciones de Correo
    path('send-email/', views.send_email, name='send_email'),
    
    # Inbox: El endpoint /me/ es ideal para la TUI porque no necesita pasar el nombre en la URL
    path('read-emails/me/', views.read_emails_me, name='read_emails_me'),

    # Sent: Para diferenciarlo del inbox, lo dejamos con el username explícito
    path('read-emails/sent/', views.read_emails_sent), 
    
    # Mantén esta por si necesitas consultar el de alguien más (si eres admin)
    path('read-emails/<str:username>/', views.read_emails_me, name='read_emails'),

    # Utilidades
    path('mark-read/<int:email_id>/', views.mark_as_read, name='mark_as_read'),
]