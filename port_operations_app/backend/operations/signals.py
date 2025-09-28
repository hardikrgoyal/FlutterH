from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.contrib.auth.models import User
from .models import POVendor, WOVendor, VendorAuditLog

def get_client_ip(request):
    """Get the client IP address from request"""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip

def get_user_agent(request):
    """Get the user agent from request"""
    return request.META.get('HTTP_USER_AGENT', '')

def create_audit_log(vendor, action, changes=None, request=None):
    """Create audit log entry for vendor changes"""
    vendor_type = 'PO' if isinstance(vendor, POVendor) else 'WO'
    
    # Get user from request if available
    user = None
    ip_address = None
    user_agent = None
    
    if request and hasattr(request, 'user'):
        user = request.user if request.user.is_authenticated else None
        ip_address = get_client_ip(request)
        user_agent = get_user_agent(request)
    
    VendorAuditLog.objects.create(
        vendor_type=vendor_type,
        vendor_id=vendor.id,
        vendor_name=vendor.name,
        action=action,
        performed_by=user,
        changes=changes or {},
        ip_address=ip_address,
        user_agent=user_agent,
    )

# Store original values before save for change tracking
_original_po_vendor_data = {}
_original_wo_vendor_data = {}

@receiver(pre_save, sender=POVendor)
def po_vendor_pre_save(sender, instance, **kwargs):
    """Store original values before save"""
    if instance.pk:  # Only for existing objects
        try:
            original = POVendor.objects.get(pk=instance.pk)
            _original_po_vendor_data[instance.pk] = {
                'name': original.name,
                'contact_person': original.contact_person,
                'phone_number': original.phone_number,
                'email': original.email,
                'address': original.address,
                'is_active': original.is_active,
            }
        except POVendor.DoesNotExist:
            pass

@receiver(pre_save, sender=WOVendor)
def wo_vendor_pre_save(sender, instance, **kwargs):
    """Store original values before save"""
    if instance.pk:  # Only for existing objects
        try:
            original = WOVendor.objects.get(pk=instance.pk)
            _original_wo_vendor_data[instance.pk] = {
                'name': original.name,
                'contact_person': original.contact_person,
                'phone_number': original.phone_number,
                'email': original.email,
                'address': original.address,
                'is_active': original.is_active,
            }
        except WOVendor.DoesNotExist:
            pass

@receiver(post_save, sender=POVendor)
def po_vendor_audit(sender, instance, created, **kwargs):
    """Track PO Vendor changes"""
    action = 'created' if created else 'updated'
    changes = {}
    
    if created:
        # For new records, store all field values
        changes = {
            'action': 'created',
            'fields': {
                'name': {'new': instance.name},
                'contact_person': {'new': instance.contact_person},
                'phone_number': {'new': instance.phone_number},
                'email': {'new': instance.email},
                'address': {'new': instance.address},
                'is_active': {'new': instance.is_active},
            }
        }
    else:
        # For updates, compare with original values
        original_data = _original_po_vendor_data.get(instance.pk, {})
        if original_data:
            field_changes = {}
            
            # Check each field for changes
            if original_data.get('name') != instance.name:
                field_changes['name'] = {
                    'old': original_data.get('name'),
                    'new': instance.name
                }
            
            if original_data.get('contact_person') != instance.contact_person:
                field_changes['contact_person'] = {
                    'old': original_data.get('contact_person'),
                    'new': instance.contact_person
                }
            
            if original_data.get('phone_number') != instance.phone_number:
                field_changes['phone_number'] = {
                    'old': original_data.get('phone_number'),
                    'new': instance.phone_number
                }
            
            if original_data.get('email') != instance.email:
                field_changes['email'] = {
                    'old': original_data.get('email'),
                    'new': instance.email
                }
            
            if original_data.get('address') != instance.address:
                field_changes['address'] = {
                    'old': original_data.get('address'),
                    'new': instance.address
                }
            
            if original_data.get('is_active') != instance.is_active:
                field_changes['is_active'] = {
                    'old': original_data.get('is_active'),
                    'new': instance.is_active
                }
                # Special handling for activation/deactivation
                if instance.is_active and not original_data.get('is_active'):
                    action = 'activated'
                elif not instance.is_active and original_data.get('is_active'):
                    action = 'deactivated'
            
            if field_changes:
                changes = {
                    'action': 'updated',
                    'fields': field_changes
                }
            
            # Clean up stored original data
            _original_po_vendor_data.pop(instance.pk, None)
    
    # Only create audit log if there are actual changes or it's a new record
    if changes:
        create_audit_log(instance, action, changes)

@receiver(post_save, sender=WOVendor)
def wo_vendor_audit(sender, instance, created, **kwargs):
    """Track WO Vendor changes"""
    action = 'created' if created else 'updated'
    changes = {}
    
    if created:
        # For new records, store all field values
        changes = {
            'action': 'created',
            'fields': {
                'name': {'new': instance.name},
                'contact_person': {'new': instance.contact_person},
                'phone_number': {'new': instance.phone_number},
                'email': {'new': instance.email},
                'address': {'new': instance.address},
                'is_active': {'new': instance.is_active},
            }
        }
    else:
        # For updates, compare with original values
        original_data = _original_wo_vendor_data.get(instance.pk, {})
        if original_data:
            field_changes = {}
            
            # Check each field for changes
            if original_data.get('name') != instance.name:
                field_changes['name'] = {
                    'old': original_data.get('name'),
                    'new': instance.name
                }
            
            if original_data.get('contact_person') != instance.contact_person:
                field_changes['contact_person'] = {
                    'old': original_data.get('contact_person'),
                    'new': instance.contact_person
                }
            
            if original_data.get('phone_number') != instance.phone_number:
                field_changes['phone_number'] = {
                    'old': original_data.get('phone_number'),
                    'new': instance.phone_number
                }
            
            if original_data.get('email') != instance.email:
                field_changes['email'] = {
                    'old': original_data.get('email'),
                    'new': instance.email
                }
            
            if original_data.get('address') != instance.address:
                field_changes['address'] = {
                    'old': original_data.get('address'),
                    'new': instance.address
                }
            
            if original_data.get('is_active') != instance.is_active:
                field_changes['is_active'] = {
                    'old': original_data.get('is_active'),
                    'new': instance.is_active
                }
                # Special handling for activation/deactivation
                if instance.is_active and not original_data.get('is_active'):
                    action = 'activated'
                elif not instance.is_active and original_data.get('is_active'):
                    action = 'deactivated'
            
            if field_changes:
                changes = {
                    'action': 'updated',
                    'fields': field_changes
                }
            
            # Clean up stored original data
            _original_wo_vendor_data.pop(instance.pk, None)
    
    # Only create audit log if there are actual changes or it's a new record
    if changes:
        create_audit_log(instance, action, changes)
