from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.contrib.auth.models import User
from .models import POVendor, WOVendor, VendorAuditLog, ListItemMaster, ListTypeMaster, ListItemAuditLog

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
        # Cleanup old audit logs, keeping only the last 10
        cleanup_old_vendor_audit_logs(instance)

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
        # Cleanup old audit logs, keeping only the last 10
        cleanup_old_vendor_audit_logs(instance)

# Store original values for list items
_original_list_item_data = {}

def create_list_item_audit_log(item, action, changes=None, request=None):
    """Create audit log entry for list item changes"""
    try:
        list_type = ListTypeMaster.objects.get(id=item.list_type_id)
        list_type_code = list_type.code
        list_type_name = list_type.name
    except ListTypeMaster.DoesNotExist:
        list_type_code = 'unknown'
        list_type_name = 'Unknown List Type'
    
    # Get user from request if available
    user = None
    ip_address = None
    user_agent = None
    
    if request and hasattr(request, 'user'):
        user = request.user if request.user.is_authenticated else None
        ip_address = get_client_ip(request)
        user_agent = get_user_agent(request)
    
    ListItemAuditLog.objects.create(
        list_type_code=list_type_code,
        list_type_name=list_type_name,
        item_id=item.id,
        item_name=item.name,
        action=action,
        performed_by=user,
        changes=changes or {},
        ip_address=ip_address,
        user_agent=user_agent,
    )

@receiver(pre_save, sender=ListItemMaster)
def list_item_pre_save(sender, instance, **kwargs):
    """Store original values before save"""
    if instance.pk:  # Only for existing objects
        try:
            original = ListItemMaster.objects.get(pk=instance.pk)
            _original_list_item_data[instance.pk] = {
                'name': original.name,
                'code': original.code,
                'description': original.description,
                'sort_order': original.sort_order,
                'is_active': original.is_active,
            }
        except ListItemMaster.DoesNotExist:
            pass

@receiver(post_save, sender=ListItemMaster)
def list_item_audit(sender, instance, created, **kwargs):
    """Track List Item changes"""
    action = 'created' if created else 'updated'
    changes = {}
    
    if created:
        # For new records, store all field values
        changes = {
            'action': 'created',
            'fields': {
                'name': {'new': instance.name},
                'code': {'new': instance.code},
                'description': {'new': instance.description},
                'sort_order': {'new': instance.sort_order},
                'is_active': {'new': instance.is_active},
            }
        }
    else:
        # For updates, compare with original values
        if instance.pk in _original_list_item_data:
            original = _original_list_item_data[instance.pk]
            changed_fields = {}
            
            # Check each field for changes
            for field in ['name', 'code', 'description', 'sort_order', 'is_active']:
                old_value = original.get(field)
                new_value = getattr(instance, field)
                
                if old_value != new_value:
                    changed_fields[field] = {
                        'old': old_value,
                        'new': new_value
                    }
            
            if changed_fields:
                changes = {
                    'action': 'updated',
                    'fields': changed_fields
                }
            
            # Clean up stored original data
            del _original_list_item_data[instance.pk]
    
    # Create audit log entry
    if changes:
        create_list_item_audit_log(instance, action, changes)
        # Cleanup old audit logs, keeping only the last 10
        cleanup_old_list_item_audit_logs(instance)

def cleanup_old_vendor_audit_logs(vendor_instance):
    """Keep only the last 10 audit logs for a vendor"""
    try:
        vendor_type = 'PO' if isinstance(vendor_instance, POVendor) else 'WO'
        
        # Get all audit logs for this vendor, ordered by creation time (newest first)
        all_logs = VendorAuditLog.objects.filter(
            vendor_type=vendor_type,
            vendor_id=vendor_instance.id
        ).order_by('-created_at')
        
        # Delete everything beyond the 10th entry
        logs_to_delete = all_logs[10:]
        if logs_to_delete.exists():
            logs_to_delete.delete()
    except Exception:
        # Silently fail cleanup to avoid breaking the main operation
        pass

def cleanup_old_list_item_audit_logs(list_item_instance):
    """Keep only the last 10 audit logs for a list item"""
    try:
        list_type = ListTypeMaster.objects.get(id=list_item_instance.list_type_id)
        
        # Get all audit logs for this item, ordered by creation time (newest first)
        all_logs = ListItemAuditLog.objects.filter(
            list_type_code=list_type.code,
            item_id=list_item_instance.id
        ).order_by('-created_at')
        
        # Delete everything beyond the 10th entry
        logs_to_delete = all_logs[10:]
        if logs_to_delete.exists():
            logs_to_delete.delete()
    except Exception:
        # Silently fail cleanup to avoid breaking the main operation
        pass
