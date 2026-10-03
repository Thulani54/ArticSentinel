from django.urls import path
from . import views
urlpatterns = [path('devices/<int:device_id>/rules/',views.device_rules),path('register/',views.register),path('unregister/',views.unregister)]
