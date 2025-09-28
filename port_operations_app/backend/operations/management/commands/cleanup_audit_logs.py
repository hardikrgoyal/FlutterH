from django.core.management.base import BaseCommand
from django.db import transaction
from operations.models import VendorAuditLog, ListItemAuditLog


class Command(BaseCommand):
    help = 'Cleanup old audit logs, keeping only the last 10 entries per vendor/item'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting',
        )
        parser.add_argument(
            '--keep-count',
            type=int,
            default=10,
            help='Number of audit log entries to keep per vendor/item (default: 10)',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        keep_count = options['keep_count']
        
        self.stdout.write(f"Cleaning up audit logs, keeping last {keep_count} entries per vendor/item")
        if dry_run:
            self.stdout.write(self.style.WARNING("DRY RUN MODE - No actual deletions will be performed"))
        
        # Cleanup vendor audit logs
        vendor_deleted = self.cleanup_vendor_audit_logs(keep_count, dry_run)
        
        # Cleanup list item audit logs
        list_item_deleted = self.cleanup_list_item_audit_logs(keep_count, dry_run)
        
        total_deleted = vendor_deleted + list_item_deleted
        
        if dry_run:
            self.stdout.write(
                self.style.SUCCESS(f"Would delete {total_deleted} audit log entries "
                                 f"({vendor_deleted} vendor, {list_item_deleted} list item)")
            )
        else:
            self.stdout.write(
                self.style.SUCCESS(f"Successfully deleted {total_deleted} audit log entries "
                                 f"({vendor_deleted} vendor, {list_item_deleted} list item)")
            )

    def cleanup_vendor_audit_logs(self, keep_count, dry_run):
        """Cleanup vendor audit logs, keeping only the last N entries per vendor"""
        deleted_count = 0
        
        # Get all unique vendor combinations
        vendor_combinations = VendorAuditLog.objects.values('vendor_type', 'vendor_id').distinct()
        
        for combination in vendor_combinations:
            vendor_type = combination['vendor_type']
            vendor_id = combination['vendor_id']
            
            # Get all audit logs for this vendor, ordered by creation time (newest first)
            all_logs = VendorAuditLog.objects.filter(
                vendor_type=vendor_type,
                vendor_id=vendor_id
            ).order_by('-created_at')
            
            # Get logs to delete (everything beyond the keep_count)
            logs_to_delete = all_logs[keep_count:]
            
            if logs_to_delete.exists():
                count = logs_to_delete.count()
                if not dry_run:
                    with transaction.atomic():
                        logs_to_delete.delete()
                deleted_count += count
                
                self.stdout.write(
                    f"{'Would delete' if dry_run else 'Deleted'} {count} audit logs for "
                    f"{vendor_type} vendor {vendor_id}"
                )
        
        return deleted_count

    def cleanup_list_item_audit_logs(self, keep_count, dry_run):
        """Cleanup list item audit logs, keeping only the last N entries per item"""
        deleted_count = 0
        
        # Get all unique list item combinations
        item_combinations = ListItemAuditLog.objects.values('list_type_code', 'item_id').distinct()
        
        for combination in item_combinations:
            list_type_code = combination['list_type_code']
            item_id = combination['item_id']
            
            # Get all audit logs for this item, ordered by creation time (newest first)
            all_logs = ListItemAuditLog.objects.filter(
                list_type_code=list_type_code,
                item_id=item_id
            ).order_by('-created_at')
            
            # Get logs to delete (everything beyond the keep_count)
            logs_to_delete = all_logs[keep_count:]
            
            if logs_to_delete.exists():
                count = logs_to_delete.count()
                if not dry_run:
                    with transaction.atomic():
                        logs_to_delete.delete()
                deleted_count += count
                
                self.stdout.write(
                    f"{'Would delete' if dry_run else 'Deleted'} {count} audit logs for "
                    f"list item {list_type_code}:{item_id}"
                )
        
        return deleted_count 