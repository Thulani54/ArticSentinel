from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone

class Migration(migrations.Migration):
    initial = True
    dependencies = [('device','0018_gascylinderconfig'),('user','0001_initial')]
    operations = [
        migrations.CreateModel(name='ConnectionState',fields=[
            ('id',models.BigAutoField(auto_created=True,primary_key=True,serialize=False,verbose_name='ID')),
            ('online',models.BooleanField()),('sequence',models.PositiveIntegerField(default=0)),
            ('changed_at',models.DateTimeField(default=django.utils.timezone.now)),
            ('last_reading_at',models.DateTimeField(null=True)),
            ('device',models.OneToOneField(on_delete=django.db.models.deletion.CASCADE,to='device.device')),
        ]),
        migrations.CreateModel(name='ConnectionDelivery',fields=[
            ('id',models.BigAutoField(auto_created=True,primary_key=True,serialize=False,verbose_name='ID')),
            ('sequence',models.PositiveIntegerField()),('online',models.BooleanField()),
            ('recipient',models.EmailField(max_length=254)),
            ('created_at',models.DateTimeField(default=django.utils.timezone.now)),
            ('attempts',models.PositiveSmallIntegerField(default=0)),
            ('next_attempt_at',models.DateTimeField(default=django.utils.timezone.now)),
            ('status',models.CharField(default='pending',max_length=16)),
            ('sent_at',models.DateTimeField(null=True)),
            ('last_error',models.CharField(blank=True,max_length=200)),
            ('state',models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,to='scale_connections.connectionstate')),
            ('profile',models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,to='user.user')),
        ],options={'constraints':[models.UniqueConstraint(fields=('state','sequence','recipient'),name='unique_scale_connection_recipient')]}),
    ]
