from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError
from decimal import Decimal

User = get_user_model()

class Wallet(models.Model):
    """
    Wallet system for supervisors
    """
    ACTION_CHOICES = [
        ('credit', 'Credit'),
        ('debit', 'Debit'),
    ]
    
    REFERENCE_CHOICES = [
        ('expense', 'Expense'),
        ('voucher', 'Voucher'),
        ('topup', 'Top-up'),
        ('adjustment', 'Adjustment'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='wallet_transactions')
    date = models.DateTimeField(auto_now_add=True)
    action = models.CharField(max_length=10, choices=ACTION_CHOICES)
    amount = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    reference = models.CharField(max_length=20, choices=REFERENCE_CHOICES)
    reference_id = models.CharField(max_length=50, blank=True, null=True)  # ID of related expense/voucher
    approved_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='approved_wallet_transactions', blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    balance_after = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    def __str__(self):
        return f"{self.user.username} - {self.action} {self.amount}"
    
    def clean(self):
        """Validate that accountants cannot have wallet transactions"""
        if self.user and self.user.role == 'accountant':
            raise ValidationError('Accountants cannot have wallet transactions')
    
    @classmethod
    def get_balance(cls, user):
        """Get current wallet balance for a user"""
        # Accountants don't have wallets
        if user.role == 'accountant':
            return Decimal('0.00')
        
        transactions = cls.objects.filter(user=user).order_by('-date')
        if transactions.exists():
            return transactions.first().balance_after
        return Decimal('0.00')
    
    def save(self, *args, **kwargs):
        # Validate before saving
        self.clean()
        
        # Calculate balance after transaction
        current_balance = self.get_balance(self.user)
        
        if self.action == 'credit':
            self.balance_after = current_balance + self.amount
        else:  # debit
            self.balance_after = current_balance - self.amount
            
        super().save(*args, **kwargs)
    
    class Meta:
        ordering = ['-date']

class PortExpense(models.Model):
    """
    In/Out Port Expense Tracking
    """
    STATUS_CHOICES = [
        ('submitted', 'Submitted'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('finalized', 'Finalized'),
    ]
    
    GATE_CHOICES = [
        ('north_gate', 'North Gate'),
        ('bandar_area', 'Bandar Area'),
        ('west_gate_1', 'West Gate 1'),
        ('west_gate_2', 'West Gate 2'),
        ('west_gate_3', 'West Gate 3'),
        ('cj_13', 'CJ 13'),
    ]
    
    IN_OUT_CHOICES = [
        ('In', 'In'),
        ('Out', 'Out'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='submitted_expenses')
    date_time = models.DateTimeField()
    vehicle = models.CharField(max_length=50)
    vehicle_number = models.CharField(max_length=20)
    gate_no = models.CharField(max_length=20, choices=GATE_CHOICES)
    in_out = models.CharField(max_length=3, choices=IN_OUT_CHOICES, default='In')
    description = models.TextField()
    cisf_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('50.00'))
    kpt_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('50.00'))
    customs_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('50.00'))
    road_tax_days = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    road_tax_amount = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    other_charges = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    photo = models.ImageField(upload_to='expense_photos/', blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='submitted')
    reviewed_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviewed_expenses', blank=True, null=True)
    approved_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='approved_expenses', blank=True, null=True)
    review_comments = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        # Auto-calculate road tax and total
        if not self.road_tax_amount:
            self.road_tax_amount = Decimal('50.00') * self.road_tax_days  # ₹50 per day
        
        self.total_amount = (
            self.cisf_amount + 
            self.kpt_amount + 
            self.customs_amount + 
            self.road_tax_amount + 
            self.other_charges
        )
        
        super().save(*args, **kwargs)
        
        # Auto-debit wallet when approved by admin/manager
        if self.status == 'approved' and self.reviewed_by:
            # Check if wallet transaction already exists
            existing_transaction = Wallet.objects.filter(
                user=self.user,
                reference='expense',
                reference_id=str(self.id)
            ).first()
            
            if not existing_transaction:
                Wallet.objects.create(
                    user=self.user,
                    action='debit',
                    amount=self.total_amount,
                    reference='expense',
                    reference_id=str(self.id),
                    approved_by=self.reviewed_by,
                    description=f"Port expense - {self.vehicle} {self.vehicle_number}"
                )
    
    def __str__(self):
        return f"{self.vehicle} {self.vehicle_number} - {self.date_time.date()}"
    
    class Meta:
        ordering = ['-created_at']

class DigitalVoucher(models.Model):
    """
    Digital voucher system for expense tracking
    """
    STATUS_CHOICES = [
        ('submitted', 'Submitted'),
        ('approved', 'Approved'),
        ('declined', 'Declined'),
        ('logged', 'Logged to Tally'),
    ]
    
    EXPENSE_CATEGORY_CHOICES = [
        ('fuel', 'Fuel'),
        ('maintenance', 'Maintenance'),
        ('office_supplies', 'Office Supplies'),
        ('travel', 'Travel'),
        ('meals', 'Meals'),
        ('communication', 'Communication'),
        ('utilities', 'Utilities'),
        ('professional_services', 'Professional Services'),
        ('others', 'Others'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='submitted_vouchers')
    date_time = models.DateTimeField()
    expense_category = models.CharField(max_length=30, choices=EXPENSE_CATEGORY_CHOICES)
    amount = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    bill_photo = models.ImageField(upload_to='voucher_photos/')
    remarks = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='submitted')
    approved_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='approved_vouchers', blank=True, null=True)
    logged_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='logged_vouchers', blank=True, null=True)
    approval_comments = models.TextField(blank=True, null=True)
    tally_reference = models.CharField(max_length=50, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        
        # Auto-debit wallet when approved by admin
        if self.status == 'approved' and self.approved_by:
            # Check if wallet transaction already exists
            existing_transaction = Wallet.objects.filter(
                user=self.user,
                reference='voucher',
                reference_id=str(self.id)
            ).first()
            
            if not existing_transaction:
                Wallet.objects.create(
                    user=self.user,
                    action='debit',
                    amount=self.amount,
                    reference='voucher',
                    reference_id=str(self.id),
                    approved_by=self.approved_by,
                    description=f"Digital voucher - {self.expense_category}"
                )
    
    def __str__(self):
        return f"{self.expense_category} - {self.amount} ({self.user.username})"
    
    class Meta:
        ordering = ['-created_at']

class WalletTopUp(models.Model):
    """
    Wallet top-up tracking by accountants
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='wallet_topups')
    amount = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    payment_method = models.CharField(max_length=20, choices=[
        ('imps', 'IMPS'),
        ('neft', 'NEFT'),
        ('cash', 'Cash'),
        ('cheque', 'Cheque'),
        ('others', 'Others'),
    ])
    reference_number = models.CharField(max_length=50, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    topped_up_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='performed_topups')
    created_at = models.DateTimeField(auto_now_add=True)
    
    def clean(self):
        """Validate that accountants cannot be topped up"""
        if self.user and self.user.role == 'accountant':
            raise ValidationError('Accountants do not have wallets and cannot be topped up')
    
    def save(self, *args, **kwargs):
        # Validate before saving
        self.clean()
        
        super().save(*args, **kwargs)
        
        # Create wallet credit transaction
        Wallet.objects.create(
            user=self.user,
            action='credit',
            amount=self.amount,
            reference='topup',
            reference_id=str(self.id),
            approved_by=self.topped_up_by,
            description=f"Wallet top-up via {self.payment_method}"
        )
    
    def __str__(self):
        return f"Top-up {self.amount} for {self.user.username}"
    
    class Meta:
        ordering = ['-created_at']

class TallyLog(models.Model):
    """
    Track entries logged to Tally system
    """
    ENTRY_TYPE_CHOICES = [
        ('expense', 'Port Expense'),
        ('voucher', 'Digital Voucher'),
        ('revenue', 'Revenue Entry'),
        ('manual', 'Manual Entry'),
    ]
    
    entry_type = models.CharField(max_length=20, choices=ENTRY_TYPE_CHOICES)
    reference_id = models.CharField(max_length=50)  # ID of the related record
    tally_voucher_number = models.CharField(max_length=50)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    description = models.TextField()
    logged_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='tally_logs')
    logged_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Tally {self.tally_voucher_number} - {self.entry_type}"
    
    class Meta:
        ordering = ['-logged_at']
