#!/usr/bin/env python
"""
Create test expenses and vouchers for approval workflow testing
"""
import os
import django
from decimal import Decimal
from datetime import datetime, timedelta

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'port_operations_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.utils import timezone
from financial.models import PortExpense, DigitalVoucher

User = get_user_model()

def create_test_expenses():
    """Create test port expenses and digital vouchers"""
    print("Creating test expenses and vouchers...")
    
    # Get users
    try:
        supervisor = User.objects.get(username='supervisor1')
        manager = User.objects.get(username='manager1') 
        admin = User.objects.get(username='admin')
        accountant = User.objects.get(username='accountant1')
    except User.DoesNotExist:
        print("Demo users not found. Please run create_demo_data.py first.")
        return
    
    # Create test port expenses
    expenses_data = [
        {
            'user': supervisor,
            'date_time': timezone.now() - timedelta(hours=2),
            'vehicle': 'Truck',
            'vehicle_number': 'GJ01AB1234',
            'gate_no': 'gate_1',
            'description': 'Port entry for container delivery',
            'cisf_amount': Decimal('50.00'),
            'kpt_amount': Decimal('100.00'),
            'customs_amount': Decimal('75.00'),
            'road_tax_days': 1,
            'other_charges': Decimal('25.00'),
            'status': 'submitted'
        },
        {
            'user': supervisor,
            'date_time': timezone.now() - timedelta(hours=5),
            'vehicle': 'Container Truck',
            'vehicle_number': 'MH12CD5678',
            'gate_no': 'gate_2',
            'description': 'Port exit after cargo unloading',
            'cisf_amount': Decimal('50.00'),
            'kpt_amount': Decimal('100.00'),
            'customs_amount': Decimal('75.00'),
            'road_tax_days': 2,
            'other_charges': Decimal('50.00'),
            'status': 'submitted'
        },
        {
            'user': supervisor,
            'date_time': timezone.now() - timedelta(days=1),
            'vehicle': 'Trailer',
            'vehicle_number': 'KA03EF9012',
            'gate_no': 'main_gate',
            'description': 'Heavy cargo transport',
            'cisf_amount': Decimal('50.00'),
            'kpt_amount': Decimal('100.00'),
            'customs_amount': Decimal('75.00'),
            'road_tax_days': 1,
            'other_charges': Decimal('0.00'),
            'status': 'approved',
            'reviewed_by': manager
        }
    ]
    
    for expense_data in expenses_data:
        # Calculate road tax and total
        road_tax_amount = Decimal('200.00') * expense_data['road_tax_days']
        total_amount = (
            expense_data['cisf_amount'] + 
            expense_data['kpt_amount'] + 
            expense_data['customs_amount'] + 
            road_tax_amount + 
            expense_data['other_charges']
        )
        
        expense_data['road_tax_amount'] = road_tax_amount
        expense_data['total_amount'] = total_amount
        
        expense, created = PortExpense.objects.get_or_create(
            vehicle_number=expense_data['vehicle_number'],
            defaults=expense_data
        )
        
        if created:
            print(f"Created port expense: {expense.vehicle} {expense.vehicle_number} - Status: {expense.status}")
    
    # Create test digital vouchers
    vouchers_data = [
        {
            'user': supervisor,
            'date_time': timezone.now() - timedelta(hours=1),
            'expense_category': 'fuel',
            'amount': Decimal('2500.00'),
            'remarks': 'Fuel for port operations vehicles',
            'status': 'submitted'
        },
        {
            'user': supervisor,
            'date_time': timezone.now() - timedelta(hours=3),
            'expense_category': 'maintenance',
            'amount': Decimal('1500.00'),
            'remarks': 'Equipment maintenance and repairs',
            'status': 'submitted'
        },
        {
            'user': supervisor,
            'date_time': timezone.now() - timedelta(days=1, hours=2),
            'expense_category': 'office_supplies',
            'amount': Decimal('750.00'),
            'remarks': 'Office stationery and supplies',
            'status': 'approved',
            'approved_by': admin
        }
    ]
    
    for voucher_data in vouchers_data:
        voucher, created = DigitalVoucher.objects.get_or_create(
            user=voucher_data['user'],
            date_time=voucher_data['date_time'],
            expense_category=voucher_data['expense_category'],
            defaults=voucher_data
        )
        
        if created:
            print(f"Created digital voucher: {voucher.expense_category} - ₹{voucher.amount} - Status: {voucher.status}")
    
    print("\nTest expenses and vouchers created successfully!")
    print("\nApproval Workflow:")
    print("1. Port expenses: Supervisor submits → Manager/Admin approves → Accountant finalizes")
    print("2. Digital vouchers: Supervisor submits → Admin approves → Accountant logs to Tally")
    print("\nYou can now test the approval workflow in the app!")

if __name__ == '__main__':
    create_test_expenses() 