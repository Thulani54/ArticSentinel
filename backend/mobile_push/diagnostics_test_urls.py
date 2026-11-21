from django.urls import path
from . import diagnostics
urlpatterns = [path('status/', diagnostics.status), path('test/', diagnostics.send_test)]
