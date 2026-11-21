from django.urls import path
from . import views, diagnostics
urlpatterns = [path('status/', diagnostics.status), path('test/', diagnostics.send_test), path('devices/<int:device_id>/rules/',views.device_rules),path('register/',views.register),path('unregister/',views.unregister)]
