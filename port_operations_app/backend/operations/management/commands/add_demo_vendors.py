from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from operations.models import Vendor

User = get_user_model()

class Command(BaseCommand):
    help = 'Add demo vendor data for maintenance system'

    def handle(self, *args, **options):
        # Get or create admin user
        admin_user, created = User.objects.get_or_create(
            username='admin',
            defaults={
                'email': 'admin@portops.com',
                'first_name': 'Admin',
                'last_name': 'User',
                'is_staff': True,
                'is_superuser': True,
            }
        )
        
        if created:
            admin_user.set_password('admin123')
            admin_user.save()
            self.stdout.write(self.style.SUCCESS('Created admin user'))

        # Demo vendor data
        demo_vendors = [
            {
                'name': 'ABC Auto Parts',
                'contact_person': 'John Doe',
                'phone_number': '+91-9876543210',
                'email': 'john@abcautoparts.com',
                'address': '123 Industrial Area, Mumbai'
            },
            {
                'name': 'XYZ Hydraulics',
                'contact_person': 'Jane Smith',
                'phone_number': '+91-9876543211',
                'email': 'jane@xyzhydraulics.com',
                'address': '456 Service Road, Chennai'
            },
            {
                'name': 'Prime Engine Works',
                'contact_person': 'Raj Patel',
                'phone_number': '+91-9876543212',
                'email': 'raj@primeengine.com',
                'address': '789 Workshop Street, Pune'
            },
            {
                'name': 'Supreme Electrical',
                'contact_person': 'Priya Sharma',
                'phone_number': '+91-9876543213',
                'email': 'priya@supremeelectrical.com',
                'address': '321 Electric Avenue, Kolkata'
            },
            {
                'name': 'Universal Spares',
                'contact_person': 'Amit Kumar',
                'phone_number': '+91-9876543214',
                'email': 'amit@universalspares.com',
                'address': '654 Parts Plaza, Delhi'
            }
        ]

        created_count = 0
        for vendor_data in demo_vendors:
            vendor, created = Vendor.objects.get_or_create(
                name=vendor_data['name'],
                defaults={
                    **vendor_data,
                    'is_active': True,
                    'created_by': admin_user,
                }
            )
            
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Created vendor: {vendor_data["name"]}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'Vendor already exists: {vendor_data["name"]}')
                )

        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {created_count} new vendors')
        ) 