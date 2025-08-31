#!/usr/bin/env python
"""
Create demo data for the Port Operations Management System
"""
import os
import django
from decimal import Decimal
from datetime import datetime, timedelta, date

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'port_operations_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.utils import timezone
from operations.models import (
    CargoOperation, Equipment, TransportDetail, LabourCost, 
    MiscellaneousCost, RevenueStream, RateMaster,
    VehicleType, WorkType, PartyMaster
)
from financial.models import Wallet, PortExpense, DigitalVoucher

User = get_user_model()

def create_users():
    """Create demo users with different roles"""
    print("Creating demo users...")
    
    users_data = [
        {
            'username': 'admin',
            'password': 'admin123',
            'email': 'admin@portops.com',
            'first_name': 'Admin',
            'last_name': 'User',
            'role': 'admin'
        },
        {
            'username': 'manager1',
            'password': 'manager123',
            'email': 'manager1@portops.com',
            'first_name': 'John',
            'last_name': 'Manager',
            'role': 'manager'
        },
        {
            'username': 'supervisor1',
            'password': 'supervisor123',
            'email': 'supervisor1@portops.com',
            'first_name': 'Mike',
            'last_name': 'Supervisor',
            'role': 'supervisor'
        },
        {
            'username': 'supervisor2',
            'password': 'supervisor123',
            'email': 'supervisor2@portops.com',
            'first_name': 'Sarah',
            'last_name': 'Supervisor',
            'role': 'supervisor'
        },
        {
            'username': 'accountant1',
            'password': 'accountant123',
            'email': 'accountant1@portops.com',
            'first_name': 'Lisa',
            'last_name': 'Accountant',
            'role': 'accountant'
        },
        {
            'username': 'operator1',
            'password': 'operator123',
            'email': 'operator1@portops.com',
            'first_name': 'David',
            'last_name': 'Operator',
            'role': 'operator'
        }
    ]
    
    created_users = {}
    for user_data in users_data:
        user, created = User.objects.get_or_create(
            username=user_data['username'],
            defaults=user_data
        )
        if created:
            user.set_password(user_data['password'])
            user.save()
            print(f"Created user: {user.username} ({user.role})")
        created_users[user.role] = user
    
    return created_users

def create_master_data(users):
    """Create master data for vehicles, work types, and parties"""
    print("Creating master data...")
    
    # Vehicle Types
    vehicle_types_data = ['Hydra', 'Forklift', 'Crane', 'Truck', 'Trailor']
    for vehicle_name in vehicle_types_data:
        vehicle_type, created = VehicleType.objects.get_or_create(
            name=vehicle_name,
            defaults={'created_by': users['admin']}
        )
        if created:
            print(f"Created vehicle type: {vehicle_type.name}")
    
    # Work Types
    work_types_data = ['Loading', 'Unloading', 'Container Shifting', 'Lifting']
    for work_name in work_types_data:
        work_type, created = WorkType.objects.get_or_create(
            name=work_name,
            defaults={'created_by': users['admin']}
        )
        if created:
            print(f"Created work type: {work_type.name}")
    
    # Party Master
    parties_data = [
        {'name': 'XYZ Equipment', 'contact_person': 'Ramesh Kumar', 'phone_number': '+91-9876543210'},
        {'name': 'ABC Logistics', 'contact_person': 'Suresh Gupta', 'phone_number': '+91-9876543211'},
        {'name': 'Sunrise Equipment', 'contact_person': 'Rajesh Sharma', 'phone_number': '+91-9876543212'},
        {'name': 'Global Transport', 'contact_person': 'Mukesh Patel', 'phone_number': '+91-9876543213'},
    ]
    
    for party_data in parties_data:
        party, created = PartyMaster.objects.get_or_create(
            name=party_data['name'],
            defaults={**party_data, 'created_by': users['admin']}
        )
        if created:
            print(f"Created party: {party.name}")

def create_demo_operations(manager):
    """Create demo cargo operations"""
    print("Creating demo cargo operations...")
    
    operations_data = [
        {
            'operation_name': 'PAPERBALES-001',
            'date': date.today(),
            'cargo_type': 'paper_bales',
            'weight': Decimal('500.00'),
            'party_name': 'Arya Translogistics',
            'remarks': 'Urgent delivery required'
        },
        {
            'operation_name': 'RAWSALT-002',
            'date': date.today() - timedelta(days=1),
            'cargo_type': 'raw_salt',
            'weight': Decimal('1200.00'),
            'party_name': 'Jeel Kandla',
            'remarks': 'Export grade salt'
        },
        {
            'operation_name': 'COAL-003',
            'date': date.today() - timedelta(days=2),
            'cargo_type': 'coal',
            'weight': Decimal('2500.00'),
            'party_name': 'Industrial Corp',
            'remarks': 'High grade coal shipment'
        },
        {
            'operation_name': 'SILICA-004',
            'date': date.today(),
            'cargo_type': 'silica',
            'weight': Decimal('1800.00'),
            'party_name': 'Arya Translogistics',
            'remarks': 'Industrial grade silica'
        },
        {
            'operation_name': 'PAPERBALES-005',
            'date': date.today(),
            'cargo_type': 'paper_bales',
            'weight': Decimal('900.00'),
            'party_name': 'Jeel Kandla',
            'remarks': 'Export cargo - paper bales'
        }
    ]
    
    operations = []
    for op_data in operations_data:
        operation, created = CargoOperation.objects.get_or_create(
            operation_name=op_data['operation_name'],
            defaults={**op_data, 'created_by': manager}
        )
        if created:
            print(f"Created operation: {operation.operation_name}")
        operations.append(operation)
    
    return operations

def create_demo_equipment(operations, users):
    """Create demo equipment entries"""
    print("Creating demo equipment...")
    
    # Get master data
    hydra = VehicleType.objects.get(name='Hydra')
    forklift = VehicleType.objects.get(name='Forklift')
    crane = VehicleType.objects.get(name='Crane')
    
    loading = WorkType.objects.get(name='Loading')
    unloading = WorkType.objects.get(name='Unloading')
    shifting = WorkType.objects.get(name='Container Shifting')
    
    xyz_equipment = PartyMaster.objects.get(name='XYZ Equipment')
    abc_logistics = PartyMaster.objects.get(name='ABC Logistics')
    sunrise_equipment = PartyMaster.objects.get(name='Sunrise Equipment')
    
    equipment_data = [
        {
            'operation': operations[0],
            'date': date.today(),
            'vehicle_type': hydra,
            'vehicle_number': 'KA-01-1234',
            'work_type': loading,
            'party': xyz_equipment,
            'contract_type': 'hours',
            'start_time': timezone.now() - timedelta(hours=2),
            'status': 'running'
        },
        {
            'operation': operations[1],
            'date': date.today(),
            'vehicle_type': forklift,
            'vehicle_number': 'KA-02-5678',
            'work_type': unloading,
            'party': abc_logistics,
            'contract_type': 'hours',
            'start_time': timezone.now() - timedelta(hours=4),
            'end_time': timezone.now() - timedelta(hours=1),
            'status': 'completed',
            'comments': 'Work completed successfully'
        },
        {
            'operation': operations[3],
            'date': date.today(),
            'vehicle_type': crane,
            'vehicle_number': 'TN-09-9876',
            'work_type': shifting,
            'party': sunrise_equipment,
            'contract_type': 'shift',
            'start_time': timezone.now() - timedelta(hours=1),
            'status': 'running'
        }
    ]
    
    for eq_data in equipment_data:
        equipment, created = Equipment.objects.get_or_create(
            vehicle_number=eq_data['vehicle_number'],
            operation=eq_data['operation'],
            defaults={**eq_data, 'created_by': users['supervisor']}
        )
        if created:
            print(f"Created equipment: {equipment.vehicle_type.name} - {equipment.vehicle_number}")

def create_wallet_data(users):
    """Create wallet data for supervisors"""
    print("Creating wallet data...")
    
    for role, user in users.items():
        if role in ['supervisor', 'operator']:
            # Create initial wallet top-up transaction
            wallet_transaction, created = Wallet.objects.get_or_create(
                user=user,
                reference='topup',
                defaults={
                    'action': 'credit',
                    'amount': Decimal('5000.00'),
                    'reference': 'topup',
                    'approved_by': users['admin'],
                    'description': 'Initial wallet balance for demo'
                }
            )
            if created:
                print(f"Created wallet transaction for {user.username} with amount: {wallet_transaction.amount}")
                print(f"Balance for {user.username}: {Wallet.get_balance(user)}")

def main():
    """Main function to create all demo data"""
    print("Starting demo data creation...")
    
    # Create users
    users = create_users()
    
    # Create master data
    create_master_data(users)
    
    # Create operations
    operations = create_demo_operations(users['manager'])
    
    # Create equipment
    create_demo_equipment(operations, users)
    
    # Create wallet data
    create_wallet_data(users)
    
    print("\nDemo data creation completed!")
    print("You can now log in with:")
    print("- admin/admin123 (Admin)")
    print("- manager1/manager123 (Manager)")
    print("- supervisor1/supervisor123 (Supervisor)")
    print("- accountant1/accountant123 (Accountant)")

if __name__ == '__main__':
    main() 