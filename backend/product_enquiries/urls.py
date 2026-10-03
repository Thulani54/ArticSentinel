from django.urls import path

from .views import create_enquiry

urlpatterns = [path('enquiries/', create_enquiry, name='product-enquiry-create')]
