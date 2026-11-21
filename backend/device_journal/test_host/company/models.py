from django.conf import settings
from django.db import models
class Company(models.Model):
    name = models.CharField(max_length=100)
class Profile(models.Model):
    is_active = models.BooleanField(default=True)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='profile')
    business = models.ForeignKey(Company, on_delete=models.CASCADE)
    secondary_businesses = models.ManyToManyField(Company, related_name='secondary_profiles')
