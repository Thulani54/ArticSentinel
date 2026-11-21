from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    initial = True
    dependencies = [migrations.swappable_dependency(settings.AUTH_USER_MODEL)]
    operations = [
        migrations.CreateModel(name='PlatformAdministrator', fields=[
            ('id', models.BigAutoField(primary_key=True, serialize=False)),
            ('enabled', models.BooleanField(default=True)),
            ('must_change_password', models.BooleanField(default=True)),
            ('created_at', models.DateTimeField(auto_now_add=True)),
            ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
        ]),
        migrations.CreateModel(name='AccessEvent', fields=[
            ('id', models.BigAutoField(primary_key=True, serialize=False)),
            ('action', models.CharField(max_length=40)),
            ('resource', models.CharField(blank=True, max_length=40)),
            ('filters', models.JSONField(default=dict)),
            ('created_at', models.DateTimeField(auto_now_add=True)),
            ('user', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
        ], options={'ordering': ['-created_at', '-pk']}),
    ]
