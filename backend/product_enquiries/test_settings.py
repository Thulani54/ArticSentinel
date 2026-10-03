"""Isolated test database and mail backend; never reads production settings."""
SECRET_KEY = 'test-only-product-enquiries'
INSTALLED_APPS = ['django.contrib.auth', 'django.contrib.contenttypes', 'rest_framework', 'product_enquiries']
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': ':memory:'}}
ROOT_URLCONF = 'product_enquiries.urls'
USE_TZ = True
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'
DEFAULT_FROM_EMAIL = 'ArticSentinel <noreply@example.com>'
PRODUCT_ENQUIRY_RECIPIENTS = ('admin-one@example.com', 'admin-two@example.com')
