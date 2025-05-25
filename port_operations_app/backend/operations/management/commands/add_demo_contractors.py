from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from operations.models import ContractorMaster

User = get_user_model()

class Command(BaseCommand):
    help = 'Add demo contractor data'

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

        # Demo contractor data
        demo_contractors = [
            'ABC Labour Contractors',
            'XYZ Workforce Solutions',
            'Port Labour Services',
            'Marine Workers Union',
            'Cargo Handling Contractors'
        ]

        created_count = 0
        for contractor_name in demo_contractors:
            contractor, created = ContractorMaster.objects.get_or_create(
                name=contractor_name,
                defaults={
                    'is_active': True,
                    'created_by': admin_user,
                }
            )
            
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Created contractor: {contractor_name}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'Contractor already exists: {contractor_name}')
                )

        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {created_count} new contractors')
        ) 