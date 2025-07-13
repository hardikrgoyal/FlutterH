from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from operations.models import PartyMaster, VehicleType, WorkType, EquipmentRateMaster

User = get_user_model()

class Command(BaseCommand):
    help = 'Add demo equipment rate master data'

    def handle(self, *args, **options):
        # Get admin user
        try:
            admin_user = User.objects.get(username='admin')
        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR('Admin user not found. Please create admin user first.'))
            return

        # Get master data
        parties = PartyMaster.objects.filter(is_active=True)
        vehicle_types = VehicleType.objects.filter(is_active=True)
        work_types = WorkType.objects.filter(is_active=True)
        
        if not parties.exists():
            self.stdout.write(self.style.ERROR('No parties found. Please add parties first.'))
            return
        if not vehicle_types.exists():
            self.stdout.write(self.style.ERROR('No vehicle types found. Please add vehicle types first.'))
            return
        if not work_types.exists():
            self.stdout.write(self.style.ERROR('No work types found. Please add work types first.'))
            return

        # Demo rates for each contract type
        demo_rates = {
            'hours': 800.00,
            'shift': 6000.00,
            'tonnes': 250.00,
            'fixed': 15000.00,
        }

        created_count = 0
        for party in parties:
            for vehicle_type in vehicle_types:
                for work_type in work_types:
                    for contract_type, rate in demo_rates.items():
                        equipment_rate, created = EquipmentRateMaster.objects.get_or_create(
                            party=party,
                            vehicle_type=vehicle_type,
                            work_type=work_type,
                            contract_type=contract_type,
                            defaults={
                                'rate': rate,
                                'created_by': admin_user,
                            }
                        )
                        if created:
                            created_count += 1
                            self.stdout.write(
                                self.style.SUCCESS(
                                    f'Created rate: {party.name} - {vehicle_type.name} - {work_type.name} - {contract_type} - ₹{rate}'
                                )
                            )

        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {created_count} equipment rate master records')
        ) 