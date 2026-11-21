"""Authenticated SMTP with certificate verification and an explicit TLS identity.
The socket endpoint may differ from the hosting provider's certificate name.
"""
import logging
import smtplib
import ssl
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.core.mail.backends.smtp import EmailBackend as DjangoSMTPBackend
from django.utils.html import strip_tags

logger = logging.getLogger(__name__)

class VerifiedSMTP(smtplib.SMTP):
    def starttls(self, *, context=None):
        endpoint = self._host
        self._host = getattr(settings, 'EMAIL_TLS_SERVER_NAME', '') or endpoint
        try:
            return super().starttls(context=context or ssl.create_default_context())
        finally:
            self._host = endpoint

class VerifiedEmailBackend(DjangoSMTPBackend):
    @property
    def connection_class(self):
        if self.use_ssl:
            raise ValueError('Use STARTTLS on port 587 for this mail provider')
        return VerifiedSMTP

    def close(self):
        # SMTP acceptance must not be reported as a failure if only QUIT fails.
        try:
            super().close()
        except (OSError, smtplib.SMTPException):
            if self.connection is not None:
                try:
                    self.connection.close()
                except OSError:
                    pass
            self.connection = None
            logger.warning('SMTP connection close failed after the delivery attempt')

# Compatibility for existing settings/imports, with verification now mandatory.
SSLRelaxedEmailBackend = VerifiedEmailBackend

def send_html_email(recipient, subject, html_message):
    message = EmailMultiAlternatives(
        subject, strip_tags(html_message.replace('<br>', '\n').replace('<br/>', '\n')),
        settings.DEFAULT_FROM_EMAIL, [recipient],
    )
    message.attach_alternative(html_message, 'text/html')
    return message.send(fail_silently=False) == 1
