from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from operations.models import VehicleType, Vehicle, VehicleDocument
from datetime import date, timedelta
import random

User = get_user_model()

class Command(BaseCommand):
    help = 'Add demo vehicles and documents for testing'

    def handle(self, *args, **options):
        # Get admin user
        admin_user = User.objects.filter(role='admin').first()
        if not admin_user:
            self.stdout.write(self.style.ERROR('No admin user found'))
            return

        # Create vehicle types if they don't exist
        vehicle_types_data = [
            'Dumper',
            'Tipper',
            'Truck',
            'JCB',
            'Crane',
            'Loader',
            'Trailer',
            'Container Truck',
        ]

        vehicle_types = []
        for type_name in vehicle_types_data:
            vehicle_type, created = VehicleType.objects.get_or_create(
                name=type_name,
                defaults={'created_by': admin_user}
            )
            vehicle_types.append(vehicle_type)
            if created:
                self.stdout.write(f'Created vehicle type: {type_name}')

        # Create demo vehicles
        demo_vehicles_data = [
            {'number': 'MH01AB1234', 'type': 'Dumper', 'ownership': 'hired', 'owner': 'Ramesh Transport'},
            {'number': 'MH02CD5678', 'type': 'Tipper', 'ownership': 'owned', 'owner': None},
            {'number': 'GJ03EF9012', 'type': 'Truck', 'ownership': 'hired', 'owner': 'Gujarat Logistics'},
            {'number': 'KA04GH3456', 'type': 'JCB', 'ownership': 'hired', 'owner': 'Bangalore Equipment'},
            {'number': 'TN05IJ7890', 'type': 'Crane', 'ownership': 'owned', 'owner': None},
            {'number': 'AP06KL1234', 'type': 'Loader', 'ownership': 'hired', 'owner': 'Andhra Machines'},
            {'number': 'RJ07MN5678', 'type': 'Trailer', 'ownership': 'hired', 'owner': 'Rajasthan Heavy'},
            {'number': 'UP08OP9012', 'type': 'Container Truck', 'ownership': 'hired', 'owner': 'UP Container Services'},
        ]

        vehicles = []
        for vehicle_data in demo_vehicles_data:
            vehicle_type = next((vt for vt in vehicle_types if vt.name == vehicle_data['type']), vehicle_types[0])
            
            vehicle, created = Vehicle.objects.get_or_create(
                vehicle_number=vehicle_data['number'],
                defaults={
                    'vehicle_type': vehicle_type,
                    'ownership': vehicle_data['ownership'],
                    'status': 'active',
                    'owner_name': vehicle_data['owner'],
                    'owner_contact': f'+91 9876543{random.randint(100, 999)}' if vehicle_data['owner'] else None,
                    'capacity': f'{random.randint(5, 25)} MT',
                    'make_model': f'Tata {random.randint(1000, 9999)}',
                    'year_of_manufacture': random.randint(2015, 2024),
                    'created_by': admin_user,
                }
            )
            vehicles.append(vehicle)
            if created:
                self.stdout.write(f'Created vehicle: {vehicle_data["number"]}')

        # Create demo documents for each vehicle
        document_types = [
            'insurance',
            'puc', 
            'rc',
            'fitness',
            'road_tax',
            'permit'
        ]

        for vehicle in vehicles:
            # Create 2-4 random document types for each vehicle
            selected_doc_types = random.sample(document_types, random.randint(2, 4))
            
            for doc_type in selected_doc_types:
                # Create current active document
                issue_date = date.today() - timedelta(days=random.randint(30, 365))
                expiry_date = date.today() + timedelta(days=random.randint(30, 365))
                
                # Make some documents expire soon for testing
                if random.random() < 0.3:  # 30% chance
                    expiry_date = date.today() + timedelta(days=random.randint(1, 30))
                
                # Make some documents already expired for testing
                if random.random() < 0.2:  # 20% chance
                    expiry_date = date.today() - timedelta(days=random.randint(1, 30))

                document_number = f'{doc_type.upper()}{random.randint(100000, 999999)}'
                
                document, created = VehicleDocument.objects.get_or_create(
                    vehicle=vehicle,
                    document_type=doc_type,
                    document_number=document_number,
                    defaults={
                        'issue_date': issue_date,
                        'expiry_date': expiry_date,
                        'status': 'expired' if expiry_date < date.today() else 'active',
                        'notes': f'Demo {doc_type} document for {vehicle.vehicle_number}',
                        'added_by': admin_user,
                    }
                )
                
                if created:
                    self.stdout.write(f'Created {doc_type} document for {vehicle.vehicle_number}')
                
                # Create some renewal history for testing
                if random.random() < 0.4:  # 40% chance of having renewal history
                    old_expiry = issue_date - timedelta(days=random.randint(1, 365))
                    old_issue = old_expiry - timedelta(days=365)
                    old_document_number = f'{doc_type.upper()}{random.randint(100000, 999999)}'
                    
                    old_document = VehicleDocument.objects.create(
                        vehicle=vehicle,
                        document_type=doc_type,
                        document_number=old_document_number,
                        issue_date=old_issue,
                        expiry_date=old_expiry,
                        status='expired',
                        notes=f'Previous {doc_type} document for {vehicle.vehicle_number}',
                        added_by=admin_user,
                    )
                    
                    # Link current document as renewal of old one
                    document.renewal_reference = old_document
                    document.save()
                    
                    self.stdout.write(f'Created renewal history for {vehicle.vehicle_number} {doc_type}')

        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully created {len(vehicles)} demo vehicles with documents'
            )
        ) 