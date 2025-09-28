from django.db import migrations
from django.contrib.auth import get_user_model

def populate_list_data(apps, schema_editor):
    ListTypeMaster = apps.get_model('operations', 'ListTypeMaster')
    ListItemMaster = apps.get_model('operations', 'ListItemMaster')
    User = apps.get_model('authentication', 'User')
    
    # Get the first admin user, or create one if none exists
    admin_user = User.objects.filter(is_superuser=True).first()
    if not admin_user:
        admin_user = User.objects.filter(is_staff=True).first()
    if not admin_user:
        admin_user = User.objects.filter().first()
    if not admin_user:
        # Create a system user if no admin exists
        admin_user = User.objects.create(
            username='system',
            email='system@company.com',
            is_staff=True,
            is_superuser=True,
            role='admin'
        )
    
    # Define list types and their items
    list_data = {
        'cargo_types': {
            'name': 'Cargo Types',
            'description': 'Types of cargo handled in operations',
            'items': [
                {'name': 'Paper Bales', 'code': 'paper_bales', 'sort_order': 1},
                {'name': 'Raw Salt', 'code': 'raw_salt', 'sort_order': 2},
                {'name': 'Coal', 'code': 'coal', 'sort_order': 3},
                {'name': 'Silica', 'code': 'silica', 'sort_order': 4},
                {'name': 'Breakbulk', 'code': 'breakbulk', 'sort_order': 5},
                {'name': 'Container', 'code': 'container', 'sort_order': 6},
                {'name': 'Bulk', 'code': 'bulk', 'sort_order': 7},
                {'name': 'Project Cargo', 'code': 'project', 'sort_order': 8},
                {'name': 'Others', 'code': 'others', 'sort_order': 9},
            ]
        },
        'party_names': {
            'name': 'Party Names',
            'description': 'List of party names for operations',
            'items': [
                {'name': 'Arya Translogistics', 'code': 'arya_translogistics', 'sort_order': 1},
                {'name': 'Jeel Kandla', 'code': 'jeel_kandla', 'sort_order': 2},
            ]
        },
        'gate_locations': {
            'name': 'Gate Locations',
            'description': 'Port gate locations for expenses',
            'items': [
                {'name': 'North Gate', 'code': 'north_gate', 'sort_order': 1},
                {'name': 'Bandar Area', 'code': 'bandar_area', 'sort_order': 2},
                {'name': 'West Gate 1', 'code': 'west_gate_1', 'sort_order': 3},
                {'name': 'West Gate 2', 'code': 'west_gate_2', 'sort_order': 4},
                {'name': 'West Gate 3', 'code': 'west_gate_3', 'sort_order': 5},
                {'name': 'CJ 13', 'code': 'cj_13', 'sort_order': 6},
            ]
        },
        'voucher_categories': {
            'name': 'Voucher Categories',
            'description': 'Categories for voucher expenses',
            'items': [
                {'name': 'Fuel', 'code': 'fuel', 'sort_order': 1},
                {'name': 'Maintenance', 'code': 'maintenance', 'sort_order': 2},
                {'name': 'Office Supplies', 'code': 'office_supplies', 'sort_order': 3},
                {'name': 'Travel', 'code': 'travel', 'sort_order': 4},
                {'name': 'Meals', 'code': 'meals', 'sort_order': 5},
                {'name': 'Communication', 'code': 'communication', 'sort_order': 6},
                {'name': 'Utilities', 'code': 'utilities', 'sort_order': 7},
                {'name': 'Professional Services', 'code': 'professional_services', 'sort_order': 8},
                {'name': 'Others', 'code': 'others', 'sort_order': 9},
            ]
        },
        'contract_types': {
            'name': 'Contract Types',
            'description': 'Types of contracts for equipment',
            'items': [
                {'name': 'Fixed', 'code': 'fixed', 'sort_order': 1},
                {'name': 'Shift', 'code': 'shift', 'sort_order': 2},
                {'name': 'Tonnes', 'code': 'tonnes', 'sort_order': 3},
                {'name': 'Hours', 'code': 'hours', 'sort_order': 4},
            ]
        },
        'cost_types': {
            'name': 'Cost Types',
            'description': 'Types of miscellaneous costs',
            'items': [
                {'name': 'Office Supplies', 'code': 'office_supplies', 'sort_order': 1},
                {'name': 'Travel & Transport', 'code': 'travel_transport', 'sort_order': 2},
                {'name': 'Communication', 'code': 'communication', 'sort_order': 3},
                {'name': 'Utilities', 'code': 'utilities', 'sort_order': 4},
                {'name': 'Professional Services', 'code': 'professional_services', 'sort_order': 5},
                {'name': 'Maintenance & Repairs', 'code': 'maintenance_repairs', 'sort_order': 6},
                {'name': 'Insurance', 'code': 'insurance', 'sort_order': 7},
                {'name': 'Legal & Compliance', 'code': 'legal_compliance', 'sort_order': 8},
                {'name': 'Marketing & Advertising', 'code': 'marketing_advertising', 'sort_order': 9},
                {'name': 'Others', 'code': 'others', 'sort_order': 10},
            ]
        },
        'in_out_options': {
            'name': 'In/Out Options',
            'description': 'Direction options for port operations',
            'items': [
                {'name': 'In', 'code': 'in', 'sort_order': 1},
                {'name': 'Out', 'code': 'out', 'sort_order': 2},
            ]
        },
        'maintenance_categories': {
            'name': 'Maintenance Categories',
            'description': 'Categories for work orders and purchase orders',
            'items': [
                {'name': 'Engine', 'code': 'engine', 'sort_order': 1},
                {'name': 'Hydraulic', 'code': 'hydraulic', 'sort_order': 2},
                {'name': 'Bushing', 'code': 'bushing', 'sort_order': 3},
                {'name': 'Electrical', 'code': 'electrical', 'sort_order': 4},
                {'name': 'Other', 'code': 'other', 'sort_order': 5},
            ]
        },
        'vehicle_types_list': {
            'name': 'Vehicle Types List',
            'description': 'List of vehicle types for expenses (separate from equipment)',
            'items': [
                {'name': 'Pickup', 'code': 'pickup', 'sort_order': 1},
                {'name': 'Truck/Trailer', 'code': 'truck_trailer', 'sort_order': 2},
                {'name': 'Car', 'code': 'car', 'sort_order': 3},
                {'name': 'Motorcycle', 'code': 'motorcycle', 'sort_order': 4},
                {'name': 'Van', 'code': 'van', 'sort_order': 5},
            ]
        },
        'document_types': {
            'name': 'Document Types',
            'description': 'Types of vehicle documents',
            'items': [
                {'name': 'Insurance', 'code': 'insurance', 'sort_order': 1},
                {'name': 'Road Tax', 'code': 'road_tax', 'sort_order': 2},
                {'name': 'Registration', 'code': 'registration', 'sort_order': 3},
                {'name': 'Permit', 'code': 'permit', 'sort_order': 4},
                {'name': 'Pollution Certificate', 'code': 'pollution_certificate', 'sort_order': 5},
                {'name': 'Fastag', 'code': 'fastag', 'sort_order': 6},
                {'name': 'Other', 'code': 'other', 'sort_order': 7},
            ]
        },
        'priority_levels': {
            'name': 'Priority Levels',
            'description': 'Priority levels for work orders and tasks',
            'items': [
                {'name': 'Low', 'code': 'low', 'sort_order': 1},
                {'name': 'Medium', 'code': 'medium', 'sort_order': 2},
                {'name': 'High', 'code': 'high', 'sort_order': 3},
                {'name': 'Critical', 'code': 'critical', 'sort_order': 4},
                {'name': 'Emergency', 'code': 'emergency', 'sort_order': 5},
            ]
        },
        'status_options': {
            'name': 'Status Options',
            'description': 'Common status options for various entities',
            'items': [
                {'name': 'Draft', 'code': 'draft', 'sort_order': 1},
                {'name': 'Pending', 'code': 'pending', 'sort_order': 2},
                {'name': 'In Progress', 'code': 'in_progress', 'sort_order': 3},
                {'name': 'Completed', 'code': 'completed', 'sort_order': 4},
                {'name': 'Cancelled', 'code': 'cancelled', 'sort_order': 5},
                {'name': 'On Hold', 'code': 'on_hold', 'sort_order': 6},
            ]
        }
    }
    
    # Create list types and items
    for list_code, list_info in list_data.items():
        # Create or get list type
        list_type, created = ListTypeMaster.objects.get_or_create(
            code=list_code,
            defaults={
                'name': list_info['name'],
                'description': list_info['description']
            }
        )
        
        # Create list items
        for item_data in list_info['items']:
            ListItemMaster.objects.get_or_create(
                list_type=list_type,
                name=item_data['name'],
                defaults={
                    'code': item_data['code'],
                    'sort_order': item_data['sort_order'],
                    'created_by': admin_user
                }
            )

def reverse_populate_list_data(apps, schema_editor):
    ListTypeMaster = apps.get_model('operations', 'ListTypeMaster')
    ListItemMaster = apps.get_model('operations', 'ListItemMaster')
    
    # Delete all list items and types
    ListItemMaster.objects.all().delete()
    ListTypeMaster.objects.all().delete()

class Migration(migrations.Migration):
    dependencies = [
        ('operations', '0032_add_list_management_models'),
    ]

    operations = [
        migrations.RunPython(populate_list_data, reverse_populate_list_data),
    ] 