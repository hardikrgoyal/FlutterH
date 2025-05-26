from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from operations.models import ContractorMaster, RateMaster

User = get_user_model()

class Command(BaseCommand):
    help = 'Add demo rate master data'

    def handle(self, *args, **options):
        # Get admin user
        try:
            admin_user = User.objects.get(username='admin')
        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR('Admin user not found. Please create admin user first.'))
            return

        # Get contractors
        contractors = ContractorMaster.objects.all()
        if not contractors.exists():
            self.stdout.write(self.style.ERROR('No contractors found. Please add contractors first.'))
            return

        # Demo rates for each labour type
        demo_rates = {
            'casual': 500.00,
            'tonnes': 150.00,
            'fixed': 2000.00,
        }

        created_count = 0
        for contractor in contractors:
            for labour_type, rate in demo_rates.items():
                rate_master, created = RateMaster.objects.get_or_create(
                    contractor=contractor,
                    labour_type=labour_type,
                    defaults={
                        'rate': rate,
                        'created_by': admin_user,
                    }
                )
                if created:
                    created_count += 1
                    self.stdout.write(
                        self.style.SUCCESS(
                            f'Created rate: {contractor.name} - {labour_type} - ₹{rate}'
                        )
                    )

        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {created_count} rate master records')
        ) 