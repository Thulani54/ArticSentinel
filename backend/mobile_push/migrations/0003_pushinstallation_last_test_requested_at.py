from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [('mobile_push', '0002_devicealertsettings_devicealertrule_and_more')]
    operations = [migrations.AddField(model_name='pushinstallation', name='last_test_requested_at', field=models.DateTimeField(null=True, blank=True))]
