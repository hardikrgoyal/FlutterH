from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator
from decimal import Decimal
from django.utils import timezone

User = get_user_model()

class CargoOperation(models.Model):
    """
    Central model for cargo operations - acts as foreign key across modules
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('ongoing', 'Ongoing'),
        ('completed', 'Completed'),
    ]
    
    CARGO_TYPE_CHOICES = [
        ('breakbulk', 'Breakbulk'),
        ('container', 'Container'),
        ('bulk', 'Bulk'),
        ('project', 'Project Cargo'),
        ('others', 'Others'),
    ]
    
    operation_name = models.CharField(max_length=100, unique=True)
    date = models.DateField()
    cargo_type = models.CharField(max_length=20, choices=CARGO_TYPE_CHOICES)
    weight = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    packaging = models.CharField(max_length=100)
    party_name = models.CharField(max_length=100)
    project_status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    remarks = models.TextField(blank=True, null=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_operations')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.operation_name} - {self.party_name}"
    
    class Meta:
        ordering = ['-created_at']

class VehicleType(models.Model):
    """
    Master data for vehicle types that can be hired
    """
    name = models.CharField(max_length=50, unique=True)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.name
    
    class Meta:
        ordering = ['name']

class WorkType(models.Model):
    """
    Master data for work types
    """
    name = models.CharField(max_length=50, unique=True)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.name
    
    class Meta:
        ordering = ['name']

class PartyMaster(models.Model):
    """
    Master data for party names
    """
    name = models.CharField(max_length=100, unique=True)
    contact_person = models.CharField(max_length=100, blank=True, null=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.name
    
    class Meta:
        ordering = ['name']

class Equipment(models.Model):
    """
    Equipment tracking for hired equipment
    """
    CONTRACT_TYPE_CHOICES = [
        ('fixed', 'Fixed'),
        ('shift', 'Shift'),
        ('tonnes', 'Tonnes'),
        ('hours', 'Hours'),
    ]
    
    STATUS_CHOICES = [
        ('running', 'Running'),
        ('completed', 'Completed'),
    ]
    
    operation = models.ForeignKey(CargoOperation, on_delete=models.CASCADE, related_name='equipment')
    date = models.DateField(default=timezone.now)
    vehicle_type = models.ForeignKey(VehicleType, on_delete=models.CASCADE)
    vehicle_number = models.CharField(max_length=20)
    work_type = models.ForeignKey(WorkType, on_delete=models.CASCADE)
    party = models.ForeignKey(PartyMaster, on_delete=models.CASCADE)
    contract_type = models.CharField(max_length=20, choices=CONTRACT_TYPE_CHOICES)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField(blank=True, null=True)
    duration_hours = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    comments = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='running')
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_equipment')
    ended_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ended_equipment', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        # Calculate duration when equipment is ended
        if self.end_time and self.start_time:
            duration = self.end_time - self.start_time
            self.duration_hours = Decimal(str(duration.total_seconds() / 3600))
            self.status = 'completed'
        
        # Convert vehicle number to uppercase
        if self.vehicle_number:
            self.vehicle_number = self.vehicle_number.upper()
        
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.vehicle_type.name} - {self.vehicle_number} ({self.operation.operation_name})"
    
    class Meta:
        ordering = ['-created_at']

class RateMaster(models.Model):
    """
    Rate master configuration for auto-calculating costs
    """
    CATEGORY_CHOICES = [
        ('transport', 'Transport'),
        ('equipment', 'Equipment'),
        ('service', 'Service'),
        ('labour', 'Labour'),
    ]
    
    party = models.CharField(max_length=100)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    sub_category = models.CharField(max_length=50)  # e.g., Hydra, Casual Labour, etc.
    unit = models.CharField(max_length=20)  # e.g., Hour, MT, Trip, etc.
    rate = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    effective_date = models.DateField()
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.party} - {self.sub_category} - {self.rate}/{self.unit}"
    
    class Meta:
        ordering = ['-effective_date']

class TransportDetail(models.Model):
    """
    Transport details for operations
    """
    CONTRACT_TYPE_CHOICES = [
        ('per_trip', 'Per Trip'),
        ('per_mt', 'Per MT'),
        ('daily', 'Daily'),
        ('lumpsum', 'Lumpsum'),
    ]
    
    operation = models.ForeignKey(CargoOperation, on_delete=models.CASCADE, related_name='transport_details')
    date = models.DateField()
    vehicle = models.CharField(max_length=50)
    vehicle_number = models.CharField(max_length=20)
    contract_type = models.CharField(max_length=20, choices=CONTRACT_TYPE_CHOICES)
    quantity = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    party_name = models.CharField(max_length=100)
    bill_no = models.CharField(max_length=50, blank=True, null=True)
    rate = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    cost = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        # Auto-calculate cost
        self.cost = self.quantity * self.rate
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.vehicle} - {self.vehicle_number} ({self.operation.operation_name})"
    
    class Meta:
        ordering = ['-date']

class LabourCost(models.Model):
    """
    Labour cost tracking
    """
    LABOUR_TYPE_CHOICES = [
        ('casual', 'Casual'),
        ('skilled', 'Skilled'),
        ('operator', 'Operator'),
        ('supervisor', 'Supervisor'),
        ('others', 'Others'),
    ]
    
    WORK_TYPE_CHOICES = [
        ('loading', 'Loading'),
        ('unloading', 'Unloading'),
        ('shifting', 'Shifting'),
        ('lashing', 'Lashing'),
        ('others', 'Others'),
    ]
    
    operation = models.ForeignKey(CargoOperation, on_delete=models.CASCADE, related_name='labour_costs')
    date = models.DateField()
    contractor_name = models.CharField(max_length=100)
    labour_type = models.CharField(max_length=20, choices=LABOUR_TYPE_CHOICES)
    work_type = models.CharField(max_length=20, choices=WORK_TYPE_CHOICES)
    labour_count_tonnage = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    rate = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    amount = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        # Auto-calculate amount
        self.amount = self.labour_count_tonnage * self.rate
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.contractor_name} - {self.labour_type} ({self.operation.operation_name})"
    
    class Meta:
        ordering = ['-date']

class MiscellaneousCost(models.Model):
    """
    Miscellaneous cost tracking
    """
    COST_TYPE_CHOICES = [
        ('material', 'Material'),
        ('service', 'Service'),
        ('equipment_rental', 'Equipment Rental'),
        ('permits', 'Permits'),
        ('documentation', 'Documentation'),
        ('others', 'Others'),
    ]
    
    operation = models.ForeignKey(CargoOperation, on_delete=models.CASCADE, related_name='miscellaneous_costs')
    date = models.DateField()
    party = models.CharField(max_length=100)
    cost_type = models.CharField(max_length=20, choices=COST_TYPE_CHOICES)
    quantity = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    rate = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    total = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        # Auto-calculate total
        self.total = self.quantity * self.rate
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.cost_type} - {self.party} ({self.operation.operation_name})"
    
    class Meta:
        ordering = ['-date']

class RevenueStream(models.Model):
    """
    Revenue tracking for operations
    """
    SERVICE_TYPE_CHOICES = [
        ('stevedoring', 'Stevedoring'),
        ('storage', 'Storage'),
        ('transport', 'Transport'),
        ('handling', 'Handling'),
        ('documentation', 'Documentation'),
        ('others', 'Others'),
    ]
    
    UNIT_TYPE_CHOICES = [
        ('mt', 'MT'),
        ('cbm', 'CBM'),
        ('per_unit', 'Per Unit'),
        ('lumpsum', 'Lumpsum'),
        ('daily', 'Daily'),
        ('monthly', 'Monthly'),
    ]
    
    operation = models.ForeignKey(CargoOperation, on_delete=models.CASCADE, related_name='revenue_streams')
    date = models.DateField()
    party = models.CharField(max_length=100)
    service_type = models.CharField(max_length=20, choices=SERVICE_TYPE_CHOICES)
    unit_type = models.CharField(max_length=20, choices=UNIT_TYPE_CHOICES)
    quantity = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)], default=1)
    rate = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    amount = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        # Auto-calculate amount
        self.amount = self.quantity * self.rate
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.service_type} - {self.party} ({self.operation.operation_name})"
    
    class Meta:
        ordering = ['-date']
