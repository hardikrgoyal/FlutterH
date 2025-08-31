#!/usr/bin/env python
"""
Test script to verify permissions are working correctly
"""
import os
import django
import requests
import json

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'port_operations_backend.settings')
django.setup()

def test_supervisor_permissions():
    """Test that supervisor can access cargo operations for reading"""
    
    # Login as supervisor
    login_data = {
        'username': 'supervisor1',
        'password': 'supervisor123'
    }
    
    login_response = requests.post('http://localhost:8000/api/auth/login/', json=login_data)
    
    if login_response.status_code != 200:
        print("❌ Failed to login as supervisor")
        return False
    
    token = login_response.json()['access']
    headers = {'Authorization': f'Bearer {token}'}
    
    # Test cargo operations access
    operations_response = requests.get(
        'http://localhost:8000/api/operations/cargo-operations/?running_only=true',
        headers=headers
    )
    
    if operations_response.status_code == 200:
        print("✅ Supervisor can access cargo operations")
        operations = operations_response.json()
        print(f"   Found {len(operations)} operations")
    else:
        print(f"❌ Supervisor cannot access cargo operations: {operations_response.status_code}")
        return False
    
    # Test vehicle types access
    vehicle_types_response = requests.get(
        'http://localhost:8000/api/operations/vehicle-types/',
        headers=headers
    )
    
    if vehicle_types_response.status_code == 200:
        print("✅ Supervisor can access vehicle types")
        vehicle_types = vehicle_types_response.json()
        print(f"   Found {len(vehicle_types)} vehicle types")
    else:
        print(f"❌ Supervisor cannot access vehicle types: {vehicle_types_response.status_code}")
        return False
    
    # Test work types access
    work_types_response = requests.get(
        'http://localhost:8000/api/operations/work-types/',
        headers=headers
    )
    
    if work_types_response.status_code == 200:
        print("✅ Supervisor can access work types")
        work_types = work_types_response.json()
        print(f"   Found {len(work_types)} work types")
    else:
        print(f"❌ Supervisor cannot access work types: {work_types_response.status_code}")
        return False
    
    # Test party master access
    parties_response = requests.get(
        'http://localhost:8000/api/operations/party-master/',
        headers=headers
    )
    
    if parties_response.status_code == 200:
        print("✅ Supervisor can access party master")
        parties = parties_response.json()
        print(f"   Found {len(parties)} parties")
    else:
        print(f"❌ Supervisor cannot access party master: {parties_response.status_code}")
        return False
    
    # Test that supervisor cannot create operations
    new_operation = {
        'operation_name': 'TEST-SUPERVISOR-001',
        'date': '2025-05-25',
        'cargo_type': 'paper_bales',
        'weight': '100.00',
        'party_name': 'Test Party'
    }
    
    create_response = requests.post(
        'http://localhost:8000/api/operations/cargo-operations/',
        json=new_operation,
        headers=headers
    )
    
    if create_response.status_code == 403:
        print("✅ Supervisor correctly cannot create operations")
    else:
        print(f"❌ Supervisor should not be able to create operations: {create_response.status_code}")
        return False
    
    print("\n🎉 All permission tests passed!")
    return True

if __name__ == '__main__':
    print("Testing supervisor permissions...")
    test_supervisor_permissions() 