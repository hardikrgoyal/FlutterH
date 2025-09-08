from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator
from decimal import Decimal
from django.utils import timezone
from django.core.exceptions import ValidationError
import os

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

class Vehicle(models.Model):
    """
    Master data for individual vehicles
    """
    OWNERSHIP_CHOICES = [
        ('owned', 'Company Owned'),
        ('hired', 'Hired/Contract'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('maintenance', 'Under Maintenance'),
    ]
    
    vehicle_number = models.CharField(max_length=20, unique=True)
    vehicle_type = models.ForeignKey(VehicleType, on_delete=models.CASCADE)
    ownership = models.CharField(max_length=20, choices=OWNERSHIP_CHOICES, default='hired')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    owner_name = models.CharField(max_length=100, blank=True, null=True, help_text="Owner name for hired vehicles")
    owner_contact = models.CharField(max_length=15, blank=True, null=True)
    capacity = models.CharField(max_length=50, blank=True, null=True, help_text="Vehicle capacity (e.g., 10 MT, 25 CBM)")
    make_model = models.CharField(max_length=100, blank=True, null=True, help_text="Vehicle make and model")
    year_of_manufacture = models.PositiveIntegerField(blank=True, null=True)
    chassis_number = models.CharField(max_length=50, blank=True, null=True)
    engine_number = models.CharField(max_length=50, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        # Convert vehicle number to uppercase
        if self.vehicle_number:
            self.vehicle_number = self.vehicle_number.upper()
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.vehicle_number} ({self.vehicle_type.name})"
    
    @property
    def active_documents_count(self):
        return self.documents.filter(status='active').count()
    
    @property
    def expired_documents_count(self):
        return self.documents.filter(status='expired').count()
    
    @property
    def expiring_soon_count(self):
        from datetime import date, timedelta
        thirty_days_from_now = date.today() + timedelta(days=30)
        return self.documents.filter(
            status='active',
            expiry_date__lte=thirty_days_from_now,
            expiry_date__gte=date.today()
        ).count()
    
    class Meta:
        ordering = ['vehicle_number']

def vehicle_document_upload_path(instance, filename):
    """Generate upload path for vehicle documents"""
    # Create path like: vehicle_documents/ABC123/insurance/filename
    return f'vehicle_documents/{instance.vehicle.vehicle_number}/{instance.document_type}/{filename}'

class VehicleDocument(models.Model):
    """
    Vehicle document management with renewal history tracking
    """
    DOCUMENT_TYPE_CHOICES = [
        ('insurance', 'Insurance'),
        ('puc', 'PUC (Pollution Under Control)'),
        ('rc', 'RC (Registration Certificate)'),
        ('fitness', 'Fitness Certificate'),
        ('road_tax', 'Road Tax'),
        ('permit', 'Permit'),
        ('fastag', 'FASTag'),
        ('commercial_permit', 'Commercial Permit'),
        ('goods_permit', 'Goods Permit'),
        ('other', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('expired', 'Expired'),
    ]
    
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='documents')
    document_type = models.CharField(max_length=30, choices=DOCUMENT_TYPE_CHOICES)
    document_number = models.CharField(max_length=100, help_text="Policy No., RC No., Certificate No., etc.")
    document_file = models.FileField(upload_to=vehicle_document_upload_path, blank=True, null=True)
    issue_date = models.DateField(blank=True, null=True)
    expiry_date = models.DateField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    renewal_reference = models.ForeignKey('self', on_delete=models.SET_NULL, blank=True, null=True, 
                                        related_name='renewed_from', help_text="Reference to the document this replaces")
    notes = models.TextField(blank=True, null=True)
    added_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='added_vehicle_documents')
    added_on = models.DateTimeField(auto_now_add=True)
    updated_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='updated_vehicle_documents', null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)
    renewed_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='renewed_vehicle_documents', null=True, blank=True)
    renewed_on = models.DateTimeField(null=True, blank=True)
    
    def save(self, *args, **kwargs):
        # Auto-update status based on expiry date
        if self.expiry_date:
            today = timezone.now().date()
            if self.expiry_date < today and self.status == 'active':
                self.status = 'expired'
            elif self.expiry_date >= today and self.status == 'expired':
                # Only auto-activate if this is the latest document for this type
                latest_doc = VehicleDocument.objects.filter(
                    vehicle=self.vehicle,
                    document_type=self.document_type
                ).exclude(id=self.id).order_by('-added_on').first()
                
                if not latest_doc or self.added_on >= latest_doc.added_on:
                    self.status = 'active'
        
        super().save(*args, **kwargs)
        
        # If this is a new active document, mark previous documents of same type as expired
        if self.status == 'active':
            VehicleDocument.objects.filter(
                vehicle=self.vehicle,
                document_type=self.document_type,
                status='active'
            ).exclude(id=self.id).update(status='expired')
    
    def __str__(self):
        return f"{self.vehicle.vehicle_number} - {self.get_document_type_display()} ({self.document_number})"
    
    @property
    def days_until_expiry(self):
        """Calculate days until expiry (negative if expired)"""
        if self.expiry_date:
            today = timezone.now().date()
            return (self.expiry_date - today).days
        return None
    
    @property
    def is_expiring_soon(self):
        """Check if document expires within 30 days"""
        days = self.days_until_expiry
        return days is not None and 0 <= days <= 30
    
    @property
    def is_expired(self):
        """Check if document is expired"""
        days = self.days_until_expiry
        return days is not None and days < 0
    
    class Meta:
        ordering = ['-added_on']
        indexes = [
            models.Index(fields=['vehicle', 'document_type', 'status']),
            models.Index(fields=['expiry_date']),
            models.Index(fields=['status']),
        ]

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
    UNIT_CHOICES = [
        ('per_hour', 'Per Hour'),
        ('per_shift', 'Per Shift'),
        ('per_tonne', 'Per Tonne'),
        ('fixed_rate', 'Fixed Rate'),
        ('per_day', 'Per Day'),
        ('per_trip', 'Per Trip'),
    ]
    
    party = models.ForeignKey(PartyMaster, on_delete=models.CASCADE)
    vehicle_type = models.ForeignKey(VehicleType, on_delete=models.CASCADE) 
    work_type = models.ForeignKey(WorkType, on_delete=models.CASCADE)
    contract_type = models.CharField(max_length=20, choices=Equipment.CONTRACT_TYPE_CHOICES)
    unit = models.CharField(max_length=20, choices=UNIT_CHOICES, default='per_hour')
    rate = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    effective_from = models.DateField(default=timezone.now)
    valid_until = models.DateField(blank=True, null=True, help_text='Leave blank for indefinite validity')
    notes = models.TextField(blank=True, help_text='Additional notes or conditions')
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['party', 'vehicle_type', 'work_type', 'contract_type', 'effective_from']
        ordering = ['party__name', 'vehicle_type__name', 'work_type__name', 'contract_type', '-effective_from']
    
    def __str__(self):
        return f"{self.party.name} - {self.vehicle_type.name} - {self.work_type.name} - {self.get_contract_type_display()} - ₹{self.rate}"

    @property
    def unit_display(self):
        return self.get_unit_display()

    @property
    def validity_status(self):
        if not self.valid_until:
            return 'indefinite'
        if self.valid_until < timezone.now().date():
            return 'expired'
        return 'valid'

    @property
    def is_currently_valid(self):
        if not self.is_active:
            return False
        if self.effective_from > timezone.now().date():
            return False
        if self.valid_until and self.valid_until < timezone.now().date():
            return False
        return True

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


# === MAINTENANCE SYSTEM MODELS ===

class Vendor(models.Model):
    """
    Master data for vendors/suppliers used in PO and WO
    """
    name = models.CharField(max_length=100, unique=True)
    contact_person = models.CharField(max_length=100, blank=True, null=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.name
    
    class Meta:
        ordering = ['name']


def maintenance_audio_upload_path(instance, filename):
    """Upload path for maintenance audio files"""
    model_name = instance.__class__.__name__.lower()
    return f'maintenance_audio/{model_name}/{instance.id}/{filename}'


class WorkOrder(models.Model):
    """
    Work Order model for maintenance job tracking
    """
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('closed', 'Closed'),
    ]
    
    CATEGORY_CHOICES = [
        ('engine', 'Engine'),
        ('hydraulic', 'Hydraulic'),
        ('bushing', 'Bushing'),
        ('electrical', 'Electrical'),
        ('other', 'Other'),
    ]
    
    wo_id = models.CharField(max_length=20, unique=True, editable=False)  # Auto-generated
    vendor = models.ForeignKey(Vendor, on_delete=models.CASCADE, related_name='work_orders')
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='work_orders', blank=True, null=True)
    vehicle_other = models.CharField(max_length=100, blank=True, null=True, help_text="For non-fleet vehicles")
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    remark_text = models.TextField(blank=True, null=True)
    remark_audio = models.FileField(upload_to=maintenance_audio_upload_path, blank=True, null=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='open')
    linked_po = models.ForeignKey('PurchaseOrder', on_delete=models.SET_NULL, blank=True, null=True, related_name='linked_work_orders')
    bill_no = models.CharField(max_length=50, blank=True, null=True)
    
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_work_orders')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        if not self.wo_id:
            # Generate WO ID: WO-YYYYMMDD-XXXX
            today = timezone.now().date()
            prefix = f"WO-{today.strftime('%Y%m%d')}"
            
            # Get the last WO for today
            last_wo = WorkOrder.objects.filter(
                wo_id__startswith=prefix
            ).order_by('-wo_id').first()
            
            if last_wo:
                # Extract sequence number and increment
                last_seq = int(last_wo.wo_id.split('-')[-1])
                new_seq = last_seq + 1
            else:
                new_seq = 1
            
            self.wo_id = f"{prefix}-{new_seq:04d}"
        
        super().save(*args, **kwargs)
    
    def __str__(self):
        vehicle_display = self.vehicle.vehicle_number if self.vehicle else self.vehicle_other
        return f"{self.wo_id} - {vehicle_display} ({self.vendor.name})"
    
    class Meta:
        ordering = ['-created_at']


class PurchaseOrder(models.Model):
    """
    Purchase Order model for maintenance procurement tracking
    """
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('closed', 'Closed'),
    ]
    
    CATEGORY_CHOICES = [
        ('engine', 'Engine'),
        ('hydraulic', 'Hydraulic'),
        ('bushing', 'Bushing'),
        ('electrical', 'Electrical'),
        ('other', 'Other'),
    ]
    
    po_id = models.CharField(max_length=20, unique=True, editable=False)  # Auto-generated
    vendor = models.ForeignKey(Vendor, on_delete=models.CASCADE, related_name='purchase_orders')
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='purchase_orders', blank=True, null=True)
    vehicle_other = models.CharField(max_length=100, blank=True, null=True, help_text="For non-fleet vehicles")
    for_stock = models.BooleanField(default=False, help_text="Items for stock instead of specific vehicle")
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    remark_text = models.TextField(blank=True, null=True)
    remark_audio = models.FileField(upload_to=maintenance_audio_upload_path, blank=True, null=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='open')
    linked_wo = models.ForeignKey(WorkOrder, on_delete=models.SET_NULL, blank=True, null=True, related_name='linked_purchase_orders')
    bill_no = models.CharField(max_length=50, blank=True, null=True)
    
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_purchase_orders')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        if not self.po_id:
            # Generate PO ID: PO-YYYYMMDD-XXXX
            today = timezone.now().date()
            prefix = f"PO-{today.strftime('%Y%m%d')}"
            
            # Get the last PO for today
            last_po = PurchaseOrder.objects.filter(
                po_id__startswith=prefix
            ).order_by('-po_id').first()
            
            if last_po:
                # Extract sequence number and increment
                last_seq = int(last_po.po_id.split('-')[-1])
                new_seq = last_seq + 1
            else:
                new_seq = 1
            
            self.po_id = f"{prefix}-{new_seq:04d}"
        
        super().save(*args, **kwargs)
    
    def __str__(self):
        if self.for_stock:
            target = "For Stock"
        else:
            target = self.vehicle.vehicle_number if self.vehicle else self.vehicle_other
        return f"{self.po_id} - {target} ({self.vendor.name})"
    
    def check_duplicate_po_warning(self):
        """
        Check if similar PO exists in last 24 hours for same vendor/vehicle
        Returns warning message if duplicate found
        """
        if not self.vendor:
            return None
            
        # Check for POs created in last 24 hours
        last_24_hours = timezone.now() - timezone.timedelta(hours=24)
        
        # Build query conditions
        query_conditions = models.Q(
            vendor=self.vendor,
            created_at__gte=last_24_hours
        )
        
        # Add vehicle condition if applicable
        if self.vehicle:
            query_conditions &= models.Q(vehicle=self.vehicle)
        elif self.vehicle_other:
            query_conditions &= models.Q(vehicle_other=self.vehicle_other)
        elif self.for_stock:
            query_conditions &= models.Q(for_stock=True)
        
        # Exclude current PO if updating
        existing_pos = PurchaseOrder.objects.filter(query_conditions)
        if self.pk:
            existing_pos = existing_pos.exclude(pk=self.pk)
        
        if existing_pos.exists():
            return "PO already exists for this vehicle/vendor today. Continue?"
        
        return None
    
    class Meta:
        ordering = ['-created_at']


class POItem(models.Model):
    """
    Itemized details for Purchase Orders (Phase 2 - Office role)
    """
    purchase_order = models.ForeignKey(PurchaseOrder, on_delete=models.CASCADE, related_name='items')
    item_name = models.CharField(max_length=200)
    quantity = models.DecimalField(max_digits=10, decimal_places=3, validators=[MinValueValidator(0)])
    rate = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    amount = models.DecimalField(max_digits=12, decimal_places=2, editable=False)
    assigned_vehicle = models.ForeignKey(Vehicle, on_delete=models.SET_NULL, blank=True, null=True)
    assigned_vehicle_other = models.CharField(max_length=100, blank=True, null=True)
    for_stock = models.BooleanField(default=False)
    
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        # Auto-calculate amount
        if self.quantity and self.rate:
            quantity_decimal = Decimal(str(self.quantity)) if not isinstance(self.quantity, Decimal) else self.quantity
            rate_decimal = Decimal(str(self.rate)) if not isinstance(self.rate, Decimal) else self.rate
            self.amount = quantity_decimal * rate_decimal
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.item_name} - {self.purchase_order.po_id}"
    
    class Meta:
        ordering = ['item_name']


class Stock(models.Model):
    """
    Stock management for items marked as "For Stock" in POs
    """
    item_name = models.CharField(max_length=200)
    quantity_in_hand = models.DecimalField(max_digits=10, decimal_places=3, validators=[MinValueValidator(0)])
    source_po = models.ForeignKey(PurchaseOrder, on_delete=models.CASCADE, related_name='stock_items')
    source_po_item = models.ForeignKey(POItem, on_delete=models.CASCADE, blank=True, null=True)
    last_issue_date = models.DateTimeField(blank=True, null=True)
    unit = models.CharField(max_length=20, default='nos')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.item_name} - {self.quantity_in_hand} {self.unit}"
    
    class Meta:
        ordering = ['item_name']


class IssueSlip(models.Model):
    """
    Issue slips for items issued from stock to vehicles
    """
    slip_id = models.CharField(max_length=20, unique=True, editable=False)  # Auto-generated
    stock_item = models.ForeignKey(Stock, on_delete=models.CASCADE, related_name='issue_slips')
    issued_quantity = models.DecimalField(max_digits=10, decimal_places=3, validators=[MinValueValidator(0)])
    assigned_vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='issued_items')
    assigned_vehicle_other = models.CharField(max_length=100, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    
    issued_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='issued_stock')
    issued_at = models.DateTimeField(auto_now_add=True)
    
    def save(self, *args, **kwargs):
        if not self.slip_id:
            # Generate Issue Slip ID: IS-YYYYMMDD-XXXX
            today = timezone.now().date()
            prefix = f"IS-{today.strftime('%Y%m%d')}"
            
            # Get the last Issue Slip for today
            last_slip = IssueSlip.objects.filter(
                slip_id__startswith=prefix
            ).order_by('-slip_id').first()
            
            if last_slip:
                # Extract sequence number and increment
                last_seq = int(last_slip.slip_id.split('-')[-1])
                new_seq = last_seq + 1
            else:
                new_seq = 1
            
            self.slip_id = f"{prefix}-{new_seq:04d}"
        
        # Update stock quantity and last issue date
        if self.pk is None:  # Only on creation
            self.stock_item.quantity_in_hand -= self.issued_quantity
            self.stock_item.last_issue_date = timezone.now()
            self.stock_item.save()
        
        super().save(*args, **kwargs)
    
    def __str__(self):
        vehicle = self.assigned_vehicle.vehicle_number if self.assigned_vehicle else self.assigned_vehicle_other
        return f"{self.slip_id} - {self.stock_item.item_name} to {vehicle}"
    
    class Meta:
        ordering = ['-issued_at']


class WorkOrderPurchaseLink(models.Model):
    """
    Through model to link WorkOrders and PurchaseOrders (many-to-many)
    """
    work_order = models.ForeignKey(WorkOrder, on_delete=models.CASCADE, related_name='po_links')
    purchase_order = models.ForeignKey(PurchaseOrder, on_delete=models.CASCADE, related_name='wo_links')
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('work_order', 'purchase_order')
        constraints = [
            models.UniqueConstraint(fields=['purchase_order'], name='unique_link_per_purchase_order')
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.work_order.wo_id} ↔ {self.purchase_order.po_id}"
