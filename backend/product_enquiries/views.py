import logging

from django.core.exceptions import ImproperlyConfigured
from django.db import DatabaseError
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .serializers import EnquirySerializer
from .service import RequestConflict, SubmissionLimited, save_enquiry, source_hash

logger = logging.getLogger(__name__)


@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
def create_enquiry(request):
    serializer = EnquirySerializer(data=request.data)
    if not serializer.is_valid():
        return Response({'error': 'Please check the highlighted fields.',
                         'fields': serializer.errors}, status=400)
    try:
        enquiry, created = save_enquiry(serializer.validated_data, source_hash(request))
    except RequestConflict:
        return Response({'error': 'This request reference has already been used. Reopen the form to send a different request.'}, status=409)
    except SubmissionLimited:
        return Response({'error': 'Please wait before sending another request. Your earlier requests are already with our team.',
                         'retry_after': 3600}, status=429, headers={'Retry-After': '3600'})
    except (ImproperlyConfigured, DatabaseError) as error:
        logger.error('Product enquiry unavailable: %s', type(error).__name__)
        return Response({'error': 'We could not save your request right now. Please try again shortly.'}, status=503)
    return Response({'success': True, 'reference': str(enquiry.pk),
                     'delivery_status': 'queued',
                     'message': 'Your request has been received. Our team will contact you.'},
                    status=201 if created else 200)
