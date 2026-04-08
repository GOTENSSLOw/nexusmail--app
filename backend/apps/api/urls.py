# apps/api/urls.py
from django.urls import path
from . import views
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('send-email/', views.send_email, name='send_email'),
    path('read-emails/<str:username>/', views.read_emails, name='read_emails'),
    path('register/', views.register_user, name='register_user'),
    path('login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
]