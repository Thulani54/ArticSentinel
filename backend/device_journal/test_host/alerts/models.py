from django.db import models
class Alert(models.Model):
    company = models.ForeignKey('company.Company', on_delete=models.CASCADE)
    device = models.ForeignKey('device.Device', on_delete=models.CASCADE)
    status = models.CharField(max_length=20, default='active')
    resolved_at = models.DateTimeField(null=True)
