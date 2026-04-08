from django.db import models
from django.contrib.auth.models import User

class EmailMessage(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="emails")
    recipient = models.EmailField()
    sender = models.EmailField()
    subject = models.CharField(max_length=255)
    body = models.TextField()
    snippet = models.CharField(max_length=150)
    time = models.DateTimeField(auto_now_add=True)
    unread = models.BooleanField(default=True)
    
    # El "guardaespaldas" contra duplicados
    message_id_hash = models.CharField(max_length=255, unique=True, null=True, editable=False)

    def save(self, *args, **kwargs):
        if not self.snippet and self.body:
            self.snippet = self.body[:75] + "..."
        super().save(*args, **kwargs)