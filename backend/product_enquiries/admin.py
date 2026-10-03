from django.contrib import admin
from django.utils import timezone

from .models import EnquiryDelivery, ProductEnquiry


@admin.register(ProductEnquiry)
class ProductEnquiryAdmin(admin.ModelAdmin):
    list_display = ('id', 'product_type', 'name', 'email', 'created_at')
    list_filter = ('product_type', 'created_at')
    search_fields = ('name', 'email', 'company')
    readonly_fields = tuple(field.name for field in ProductEnquiry._meta.fields)

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False


@admin.register(EnquiryDelivery)
class EnquiryDeliveryAdmin(admin.ModelAdmin):
    list_display = ('enquiry', 'recipient', 'attempts', 'sent_at', 'next_attempt_at', 'last_error')
    list_filter = ('sent_at',)
    readonly_fields = tuple(field.name for field in EnquiryDelivery._meta.fields)
    actions = ('retry_pending',)

    @admin.action(description='Retry selected unsent notifications')
    def retry_pending(self, request, queryset):
        queryset.filter(sent_at__isnull=True).update(next_attempt_at=timezone.now())

    def has_add_permission(self, request):
        return False
