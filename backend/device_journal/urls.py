from django.urls import path
from . import views
urlpatterns = [
    path('devices/<int:device_id>/refills/', views.refills),
    path('devices/<int:device_id>/scans/', views.scans),
    path('alerts/<int:alert_id>/team/', views.alert_team),
]
