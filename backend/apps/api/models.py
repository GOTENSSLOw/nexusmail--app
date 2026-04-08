from django.db import models
from django.contrib.auth.models import User

class EmailMessage(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="emails")
    recipient = models.EmailField()
    sender = models.EmailField()
    subject = models.CharField(max_length=255)
    body = models.TextField()
    snippet = models.CharField(max_length=150) # Resumen generado
    time = models.DateTimeField(auto_now_add=True)
    unread = models.BooleanField(default=True)

    def save(self, *args, **kwargs):
        if not self.snippet and self.body:
            self.snippet = self.body[:75] + "..."
        super().save(*args, **kwargs)