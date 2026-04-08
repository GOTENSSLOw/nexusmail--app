# apps/api/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('send-email/', views.send_email, name='send_email'),
    path('read-emails/<str:username>/', views.read_emails, name='read_emails'),
    path('register/', views.register_user, name='register_user'),
]