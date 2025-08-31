from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator
from decimal import Decimal
from django.utils import timezone
from django.core.exceptions import ValidationError

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
        ('paper_bales', 'Paper Bales'),
        ('raw_salt', 'Raw Salt'),
        ('coal', 'Coal'),
        ('silica', 'Silica'),
        ('breakbulk', 'Breakbulk'),
        ('container', 'Container'),
        ('bulk', 'Bulk'),
        ('project', 'Project Cargo'),
        ('others', 'Others'),
    ]
    
    operation_name = models.CharField(max_length=100, unique=True)
    date = models.DateField()
    cargo_type = models.CharField(max_length=50, choices=CARGO_TYPE_CHOICES)
    weight = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    party_name = models.CharField(max_length=100)
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

class ContractorMaster(models.Model):
    """
    Master data for labour contractors
    """
    name = models.CharField(max_length=100, unique=True)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.name
    
    class Meta:
        ordering = ['name']

class ServiceTypeMaster(models.Model):
    """
    Master data for service types used in revenue streams
    """
    name = models.CharField(max_length=50, unique=True)
    code = models.CharField(max_length=20, unique=True)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name
    
    class Meta:
        ordering = ['name']

class UnitTypeMaster(models.Model):
    """
    Master data for unit types used in revenue streams
    """
    name = models.CharField(max_length=50, unique=True)
    code = models.CharField(max_length=20, unique=True)
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
    quantity = models.DecimalField(max_digits=10, decimal_places=3, blank=True, null=True, help_text="Calculated quantity based on contract type")
    comments = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='running')
    
    # Rate and amount - only visible to managers and admins
    rate = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)], blank=True, null=True)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    
    # Invoice tracking fields - only for managers and admins
    invoice_number = models.CharField(max_length=50, blank=True, null=True)
    invoice_received = models.BooleanField(null=True, blank=True)  # null=pending, True=received, False=not applicable
    invoice_date = models.DateField(blank=True, null=True)
    
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_equipment')
    ended_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ended_equipment', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    @property
    def amount(self):
        """Calculate total amount"""
        if self.rate is not None and self.quantity is not None:
            # Ensure both values are Decimal for consistent calculation
            rate_decimal = Decimal(str(self.rate)) if not isinstance(self.rate, Decimal) else self.rate
            quantity_decimal = Decimal(str(self.quantity)) if not isinstance(self.quantity, Decimal) else self.quantity
            return quantity_decimal * rate_decimal
        return None
    
    def save(self, *args, **kwargs):
        # Calculate duration when equipment is ended
        if self.end_time and self.start_time:
            duration = self.end_time - self.start_time
            self.duration_hours = Decimal(str(duration.total_seconds() / 3600))
            self.status = 'completed'
            
            # Calculate quantity based on contract type if not already set
            if self.quantity is None:
                if self.contract_type == 'hours':
                    self.quantity = self.duration_hours
                elif self.contract_type == 'shift':
                    # CEILING(hours/8, 0.5) formula
                    shifts = self.duration_hours / Decimal('8')
                    import math
                    # Convert to float for math.ceil operation, then back to Decimal
                    shifts_float = float(shifts)
                    self.quantity = Decimal(str(math.ceil(shifts_float * 2) / 2))  # Round to nearest 0.5
                elif self.contract_type == 'fixed':
                    self.quantity = Decimal('1.0')
                # For tonnes, quantity should be set manually before ending
            
            # Auto-populate rate from EquipmentRateMaster if not provided
            if not self.rate:
                try:
                    rate_master = EquipmentRateMaster.objects.get(
                        party=self.party,
                        vehicle_type=self.vehicle_type,
                        work_type=self.work_type,
                        contract_type=self.contract_type,
                        is_active=True
                    )
                    self.rate = rate_master.rate
                except EquipmentRateMaster.DoesNotExist:
                    pass  # Rate will need to be provided manually
            
            # Calculate total amount - ensure both values are Decimal
            if self.rate and self.quantity:
                # Convert both to Decimal to ensure type compatibility
                rate_decimal = Decimal(str(self.rate)) if not isinstance(self.rate, Decimal) else self.rate
                quantity_decimal = Decimal(str(self.quantity)) if not isinstance(self.quantity, Decimal) else self.quantity
                self.total_amount = quantity_decimal * rate_decimal
        
        # Convert vehicle number to uppercase
        if self.vehicle_number:
            self.vehicle_number = self.vehicle_number.upper()
        
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.vehicle_type.name} - {self.vehicle_number} ({self.operation.operation_name})"
    
    class Meta:
        ordering = ['-created_at']

class EquipmentRateMaster(models.Model):
    """
    Master data for equipment rates based on party, vehicle type, work type, and contract type
    """
    party = models.ForeignKey(PartyMaster, on_delete=models.CASCADE)
    vehicle_type = models.ForeignKey(VehicleType, on_delete=models.CASCADE) 
    work_type = models.ForeignKey(WorkType, on_delete=models.CASCADE)
    contract_type = models.CharField(max_length=20, choices=Equipment.CONTRACT_TYPE_CHOICES)
    rate = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['party', 'vehicle_type', 'work_type', 'contract_type']
        ordering = ['party__name', 'vehicle_type__name', 'work_type__name', 'contract_type']
    
    def __str__(self):
        return f"{self.party.name} - {self.vehicle_type.name} - {self.work_type.name} - {self.get_contract_type_display()} - ₹{self.rate}"

class RateMaster(models.Model):
    """
    Master data for contractor rates based on labour type
    """
    LABOUR_TYPE_CHOICES = [
        ('casual', 'Casual'),
        ('tonnes', 'Tonnes'),
        ('fixed', 'Fixed'),
    ]
    
    contractor = models.ForeignKey(ContractorMaster, on_delete=models.CASCADE)
    labour_type = models.CharField(max_length=20, choices=LABOUR_TYPE_CHOICES)
    rate = models.DecimalField(max_digits=10, decimal_places=2)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['contractor', 'labour_type']
        ordering = ['contractor__name', 'labour_type']
    
    def __str__(self):
        return f"{self.contractor.name} - {self.get_labour_type_display()} - ₹{self.rate}"

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
        # Auto-calculate cost - ensure both values are Decimal
        if self.quantity and self.rate:
            quantity_decimal = Decimal(str(self.quantity)) if not isinstance(self.quantity, Decimal) else self.quantity
            rate_decimal = Decimal(str(self.rate)) if not isinstance(self.rate, Decimal) else self.rate
            self.cost = quantity_decimal * rate_decimal
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.vehicle} - {self.vehicle_number} ({self.operation.operation_name})"
    
    class Meta:
        ordering = ['-date']

class LabourCost(models.Model):
    """
    Labour cost tracking for cargo operations
    """
    LABOUR_TYPE_CHOICES = [
        ('casual', 'Casual'),
        ('tonnes', 'Tonnes'),
        ('fixed', 'Fixed'),
    ]
    
    WORK_TYPE_CHOICES = [
        ('loading', 'Loading'),
        ('unloading', 'Unloading'),
        ('shifting', 'Shifting'),
        ('sorting', 'Sorting'),
        ('other', 'Other'),
    ]
    
    SHIFT_CHOICES = [
        ('1st_shift', '1st Shift'),
        ('2nd_shift', '2nd Shift'),
        ('3rd_shift', '3rd Shift'),
    ]

    operation = models.ForeignKey(CargoOperation, on_delete=models.CASCADE)
    date = models.DateField()
    contractor = models.ForeignKey(ContractorMaster, on_delete=models.CASCADE)
    labour_type = models.CharField(max_length=20, choices=LABOUR_TYPE_CHOICES)
    work_type = models.CharField(max_length=20, choices=WORK_TYPE_CHOICES)
    
    # For casual labour - shift is required
    shift = models.CharField(max_length=20, choices=SHIFT_CHOICES, null=True, blank=True)
    
    # For tonnes - quantity is required, for casual - number of workers, for fixed - always 1
    labour_count_tonnage = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0.01)])
    
    # Rate and amount - only visible to managers and admins
    rate = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)], null=True, blank=True)
    
    remarks = models.TextField(blank=True, null=True)
    
    # Invoice tracking fields - only for managers and admins
    invoice_number = models.CharField(max_length=50, blank=True, null=True)
    invoice_received = models.BooleanField(null=True, blank=True)  # null=pending, True=received, False=not applicable
    invoice_date = models.DateField(null=True, blank=True)
    
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    @property
    def amount(self):
        """Calculate total amount"""
        if self.rate is not None:
            # Ensure both values are Decimal for consistent calculation
            rate_decimal = Decimal(str(self.rate)) if not isinstance(self.rate, Decimal) else self.rate
            labour_decimal = Decimal(str(self.labour_count_tonnage)) if not isinstance(self.labour_count_tonnage, Decimal) else self.labour_count_tonnage
            return labour_decimal * rate_decimal
        return None

    @property
    def contractor_name(self):
        """Get contractor name for API responses"""
        return self.contractor.name if self.contractor else None
    
    @property
    def contractor_id(self):
        """Get contractor ID for API responses"""
        return self.contractor.id if self.contractor else None
    
    @property
    def operation_name(self):
        """Get operation name for API responses"""
        return self.operation.operation_name if self.operation else None

    def clean(self):
        """Validate labour type specific fields"""
        if self.labour_type == 'casual' and not self.shift:
            raise ValidationError({'shift': 'Shift is required for casual labour'})
        elif self.labour_type != 'casual' and self.shift:
            raise ValidationError({'shift': 'Shift should only be specified for casual labour'})

    def save(self, *args, **kwargs):
        # For fixed labour type, always set labour_count_tonnage to 1
        if self.labour_type == 'fixed':
            self.labour_count_tonnage = 1
        
        # Auto-populate rate from RateMaster if not provided
        if not self.rate:
            try:
                rate_master = RateMaster.objects.get(
                    contractor=self.contractor,
                    labour_type=self.labour_type,
                    is_active=True
                )
                self.rate = rate_master.rate
            except RateMaster.DoesNotExist:
                pass  # Rate will need to be provided manually
        
        self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.contractor.name} - {self.operation.operation_name} - {self.date}"

    class Meta:
        ordering = ['-date', '-created_at']

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
    bill_no = models.CharField(max_length=50, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        # Auto-calculate total - ensure both values are Decimal
        if self.quantity and self.rate:
            quantity_decimal = Decimal(str(self.quantity)) if not isinstance(self.quantity, Decimal) else self.quantity
            rate_decimal = Decimal(str(self.rate)) if not isinstance(self.rate, Decimal) else self.rate
            self.total = quantity_decimal * rate_decimal
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.cost_type} - {self.party} ({self.operation.operation_name})"
    
    class Meta:
        ordering = ['-date']

class RevenueStream(models.Model):
    """
    Revenue tracking for operations
    """
    operation = models.ForeignKey(CargoOperation, on_delete=models.CASCADE, related_name='revenue_streams')
    date = models.DateField()
    party = models.CharField(max_length=100)
    service_type = models.ForeignKey(ServiceTypeMaster, on_delete=models.CASCADE)
    unit_type = models.ForeignKey(UnitTypeMaster, on_delete=models.CASCADE)
    quantity = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)], default=1)
    rate = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    amount = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    bill_no = models.CharField(max_length=50, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        # Auto-calculate amount - ensure both values are Decimal
        if self.quantity and self.rate:
            quantity_decimal = Decimal(str(self.quantity)) if not isinstance(self.quantity, Decimal) else self.quantity
            rate_decimal = Decimal(str(self.rate)) if not isinstance(self.rate, Decimal) else self.rate
            self.amount = quantity_decimal * rate_decimal
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.service_type} - {self.party} ({self.operation.operation_name})"
    
    class Meta:
        ordering = ['-date']
