from django.db import models
class Device(models.Model):
    company = models.ForeignKey('company.Company', on_delete=models.CASCADE)
    device_id = models.CharField(max_length=50)
    device_type = models.CharField(max_length=20)
