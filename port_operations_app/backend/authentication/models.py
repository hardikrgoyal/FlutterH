from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    """
    Custom User model with role-based permissions
    """
    ROLE_CHOICES = [
        ('admin', 'Admin'),
        ('manager', 'Manager'),
        ('supervisor', 'Supervisor'),
        ('accountant', 'Accountant'),
    ]
    
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='supervisor')
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    employee_id = models.CharField(max_length=20, unique=True, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
    
    @property
    def is_admin(self):
        return self.role == 'admin'
    
    @property
    def is_manager(self):
        return self.role == 'manager'
    
    @property
    def is_supervisor(self):
        return self.role == 'supervisor'
    
    @property
    def is_accountant(self):
        return self.role == 'accountant'
    
    def has_permission(self, permission):
        """
        Check if user has specific permission based on role
        """
        permissions = {
            'admin': [
                'manage_users', 'approve_data', 'configure_rates',
                'create_operations', 'manage_operations', 'enter_expenses',
                'field_data_entry', 'view_wallet', 'submit_vouchers',
                'approve_financial', 'topup_wallets', 'log_tally', 'enter_revenue',
                'manage_vehicle_documents', 'view_vehicle_documents'
            ],
            'manager': [
                'create_operations', 'manage_operations', 'approve_supervisor_entries',
                'enter_expenses', 'configure_rates', 'enter_revenue',
                'manage_vehicle_documents', 'view_vehicle_documents'
            ],
            'supervisor': [
                'field_data_entry', 'view_wallet', 'submit_vouchers',
                'start_equipment', 'end_equipment', 'view_vehicle_documents'
            ],
            'accountant': [
                'approve_financial', 'topup_wallets', 'log_tally', 'enter_revenue',
                'manage_vehicle_documents', 'view_vehicle_documents'
            ]
        }
        
        return permission in permissions.get(self.role, [])
