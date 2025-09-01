from django.contrib import admin
from .models import Wallet, PortExpense, DigitalVoucher, WalletTopUp, TallyLog

@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ['user', 'action', 'amount', 'reference', 'balance_after', 'date', 'approved_by']
    list_filter = ['action', 'reference', 'date']
    search_fields = ['user__username', 'description']
    readonly_fields = ['balance_after', 'date']
    date_hierarchy = 'date'

@admin.register(PortExpense)
class PortExpenseAdmin(admin.ModelAdmin):
    list_display = ['vehicle', 'vehicle_number', 'user', 'gate_no', 'in_out', 'total_amount', 'status', 'date_time']
    list_filter = ['status', 'gate_no', 'in_out', 'date_time']
    search_fields = ['vehicle', 'vehicle_number', 'user__username']
    readonly_fields = ['road_tax_amount', 'total_amount', 'created_at', 'updated_at']
    date_hierarchy = 'date_time'

@admin.register(DigitalVoucher)
class DigitalVoucherAdmin(admin.ModelAdmin):
    list_display = ['expense_category', 'amount', 'user', 'status', 'date_time', 'approved_by']
    list_filter = ['expense_category', 'status', 'date_time']
    search_fields = ['user__username', 'remarks']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'date_time'

@admin.register(WalletTopUp)
class WalletTopUpAdmin(admin.ModelAdmin):
    list_display = ['user', 'amount', 'payment_method', 'topped_up_by', 'created_at']
    list_filter = ['payment_method', 'created_at']
    search_fields = ['user__username', 'reference_number']
    readonly_fields = ['created_at']
    date_hierarchy = 'created_at'

@admin.register(TallyLog)
class TallyLogAdmin(admin.ModelAdmin):
    list_display = ['entry_type', 'tally_voucher_number', 'amount', 'logged_by', 'logged_at']
    list_filter = ['entry_type', 'logged_at']
    search_fields = ['tally_voucher_number', 'reference_id', 'description']
    readonly_fields = ['logged_at']
    date_hierarchy = 'logged_at'
