from rest_framework import serializers

from .catalog import PRODUCTS


class EnquirySerializer(serializers.Serializer):
    request_id = serializers.UUIDField()
    name = serializers.CharField(min_length=2, max_length=120)
    email = serializers.EmailField(max_length=254)
    phone = serializers.CharField(max_length=40, required=False, allow_blank=True, default='')
    company = serializers.CharField(max_length=160, required=False, allow_blank=True, default='')
    product_type = serializers.ChoiceField(choices=list(PRODUCTS))
    message = serializers.CharField(min_length=10, max_length=2000)
    contact_consent = serializers.BooleanField()

    def validate_email(self, value):
        return value.lower()

    def validate_contact_consent(self, value):
        if value is not True:
            raise serializers.ValidationError('Please allow our team to contact you about this request.')
        return value

    def validate(self, attrs):
        for key in ('name', 'email', 'phone', 'company'):
            if any(ord(char) < 32 for char in attrs[key]):
                raise serializers.ValidationError({key: 'Use a single line without control characters.'})
        return attrs
