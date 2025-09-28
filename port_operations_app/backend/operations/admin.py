from django.contrib import admin
from .models import (
    CargoOperation, RateMaster, Equipment, EquipmentRateMaster, TransportDetail, 
    LabourCost, MiscellaneousCost, RevenueStream,
    VehicleType, WorkType, PartyMaster, ContractorMaster, ServiceTypeMaster, UnitTypeMaster,
    Vehicle, VehicleDocument,
    # Maintenance system models
    Vendor, POVendor, WOVendor, WorkOrder, PurchaseOrder, POItem, Stock, IssueSlip
)

@admin.register(CargoOperation)
class CargoOperationAdmin(admin.ModelAdmin):
    list_display = ['operation_name', 'party_name', 'cargo_type', 'weight', 'date', 'created_by']
    list_filter = ['cargo_type', 'date', 'created_at']
    search_fields = ['operation_name', 'party_name']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'date'

    def save_model(self, request, obj, form, change):
        if not obj.pk:  # New object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)

@admin.register(VehicleType)
class VehicleTypeAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active', 'created_by', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name']
    readonly_fields = ['created_by', 'created_at']

@admin.register(WorkType)
class WorkTypeAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active', 'created_by', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name']
    readonly_fields = ['created_by', 'created_at']

@admin.register(PartyMaster)
class PartyMasterAdmin(admin.ModelAdmin):
    list_display = ['name', 'contact_person', 'phone_number', 'is_active', 'created_by', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'contact_person']
    readonly_fields = ['created_by', 'created_at']

@admin.register(ContractorMaster)
class ContractorMasterAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active', 'created_by', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name']
    readonly_fields = ['created_by', 'created_at']

@admin.register(ServiceTypeMaster)
class ServiceTypeMasterAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'is_active', 'created_by', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'code']
    readonly_fields = ['created_by', 'created_at']

@admin.register(UnitTypeMaster)
class UnitTypeMasterAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'is_active', 'created_by', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'code']
    readonly_fields = ['created_by', 'created_at']

@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ['vehicle_number', 'vehicle_type', 'ownership', 'status', 'owner_name', 'active_documents_count', 'expired_documents_count', 'expiring_soon_count', 'created_at']
    list_filter = ['vehicle_type', 'ownership', 'status', 'is_active', 'created_at']
    search_fields = ['vehicle_number', 'owner_name', 'make_model', 'chassis_number', 'engine_number']
    readonly_fields = ['created_by', 'created_at', 'updated_at', 'active_documents_count', 'expired_documents_count', 'expiring_soon_count']
    
    def save_model(self, request, obj, form, change):
        if not obj.pk:  # New object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)

class VehicleDocumentInline(admin.TabularInline):
    model = VehicleDocument
    extra = 0
    readonly_fields = ['status', 'days_until_expiry', 'added_by', 'added_on', 'updated_at']
    fields = ['document_type', 'document_number', 'document_file', 'issue_date', 'expiry_date', 'status', 'days_until_expiry', 'notes']
    
    def save_model(self, request, obj, form, change):
        if not obj.pk:  # New object
            obj.added_by = request.user
        super().save_model(request, obj, form, change)

@admin.register(VehicleDocument)
class VehicleDocumentAdmin(admin.ModelAdmin):
    list_display = ['vehicle', 'document_type', 'document_number', 'expiry_date', 'status', 'days_until_expiry', 'is_expiring_soon', 'added_by', 'added_on']
    list_filter = ['document_type', 'status', 'expiry_date', 'added_on', 'vehicle__vehicle_type']
    search_fields = ['vehicle__vehicle_number', 'document_number', 'vehicle__owner_name']
    readonly_fields = ['status', 'days_until_expiry', 'is_expiring_soon', 'is_expired', 'added_by', 'added_on', 'updated_at']
    date_hierarchy = 'expiry_date'
    
    def save_model(self, request, obj, form, change):
        if not obj.pk:  # New object
            obj.added_by = request.user
        super().save_model(request, obj, form, change)
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('vehicle', 'vehicle__vehicle_type', 'added_by')

# Add inline to Vehicle admin
VehicleAdmin.inlines = [VehicleDocumentInline]

@admin.register(Equipment)
class EquipmentAdmin(admin.ModelAdmin):
    list_display = ['vehicle_type', 'vehicle_number', 'operation', 'status', 'start_time', 'end_time', 'duration_hours', 'amount', 'invoice_received', 'invoice_number']
    list_filter = ['status', 'contract_type', 'date', 'created_at', 'invoice_received']
    search_fields = ['vehicle_number', 'operation__operation_name', 'vehicle_type__name', 'party__name', 'invoice_number']
    readonly_fields = ['duration_hours', 'amount', 'total_amount', 'created_at', 'updated_at']
    date_hierarchy = 'start_time'

@admin.register(EquipmentRateMaster)
class EquipmentRateMasterAdmin(admin.ModelAdmin):
    list_display = ['party', 'vehicle_type', 'work_type', 'contract_type', 'rate', 'is_active', 'created_at']
    list_filter = ['contract_type', 'is_active', 'created_at']
    search_fields = ['party__name', 'vehicle_type__name', 'work_type__name']
    readonly_fields = ['created_by', 'created_at', 'updated_at']

@admin.register(RateMaster)
class RateMasterAdmin(admin.ModelAdmin):
    list_display = ['contractor', 'labour_type', 'rate', 'is_active', 'created_at']
    list_filter = ['labour_type', 'is_active', 'created_at']
    search_fields = ['contractor__name']
    readonly_fields = ['created_by', 'created_at', 'updated_at']

@admin.register(TransportDetail)
class TransportDetailAdmin(admin.ModelAdmin):
    list_display = ['vehicle', 'vehicle_number', 'operation', 'party_name', 'date', 'cost']
    list_filter = ['contract_type', 'date', 'created_at']
    search_fields = ['vehicle_number', 'operation__operation_name', 'party_name']
    readonly_fields = ['cost', 'created_at', 'updated_at']
    date_hierarchy = 'date'

@admin.register(LabourCost)
class LabourCostAdmin(admin.ModelAdmin):
    list_display = ['contractor', 'labour_type', 'shift', 'work_type', 'operation', 'date', 'amount', 'invoice_received', 'invoice_number']
    list_filter = ['labour_type', 'shift', 'work_type', 'date', 'invoice_received', 'contractor']
    search_fields = ['contractor__name', 'operation__operation_name', 'invoice_number']
    readonly_fields = ['amount', 'created_at', 'updated_at']
    date_hierarchy = 'date'

@admin.register(MiscellaneousCost)
class MiscellaneousCostAdmin(admin.ModelAdmin):
    list_display = ['party', 'cost_type', 'operation', 'date', 'total']
    list_filter = ['cost_type', 'date', 'created_at']
    search_fields = ['party', 'operation__operation_name']
    readonly_fields = ['total', 'created_at', 'updated_at']
    date_hierarchy = 'date'

@admin.register(RevenueStream)
class RevenueStreamAdmin(admin.ModelAdmin):
    list_display = ['party', 'service_type', 'operation', 'date', 'amount']
    list_filter = ['service_type', 'unit_type', 'date', 'created_at']
    search_fields = ['party', 'operation__operation_name']
    readonly_fields = ['amount', 'created_at', 'updated_at']
    date_hierarchy = 'date'

# === MAINTENANCE SYSTEM ADMIN ===

@admin.register(Vendor)
class VendorAdmin(admin.ModelAdmin):
    list_display = ['name', 'contact_person', 'phone_number', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'contact_person', 'phone_number']
    readonly_fields = ['created_by', 'created_at']
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)




@admin.register(POVendor)
class POVendorAdmin(admin.ModelAdmin):
    list_display = ['name', 'contact_person', 'phone_number', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'contact_person', 'phone_number']
    readonly_fields = ['created_by', 'created_at']
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(WOVendor)
class WOVendorAdmin(admin.ModelAdmin):
    list_display = ['name', 'contact_person', 'phone_number', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'contact_person', 'phone_number']
    readonly_fields = ['created_by', 'created_at']
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(WorkOrder)
class WorkOrderAdmin(admin.ModelAdmin):
    list_display = ['wo_id', 'vendor', 'vehicle', 'vehicle_other', 'category', 'status', 'created_at']
    list_filter = ['status', 'category', 'created_at', 'vendor']
    search_fields = ['wo_id', 'vendor__name', 'vehicle__vehicle_number', 'vehicle_other']
    readonly_fields = ['wo_id', 'created_by', 'created_at', 'updated_at']
    
    fieldsets = (
        (None, {
            'fields': ('wo_id', 'vendor', 'vehicle', 'vehicle_other', 'category', 'status')
        }),
        ('Remarks', {
            'fields': ('remark_text', 'remark_audio')
        }),
        ('Links & Bill', {
            'fields': ('linked_po', 'bill_no')
        }),
        ('Audit', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(PurchaseOrder)
class PurchaseOrderAdmin(admin.ModelAdmin):
    list_display = ['po_id', 'vendor', 'vehicle', 'vehicle_other', 'for_stock', 'category', 'status', 'created_at']
    list_filter = ['status', 'category', 'for_stock', 'created_at', 'vendor']
    search_fields = ['po_id', 'vendor__name', 'vehicle__vehicle_number', 'vehicle_other']
    readonly_fields = ['po_id', 'created_by', 'created_at', 'updated_at']
    
    fieldsets = (
        (None, {
            'fields': ('po_id', 'vendor', 'vehicle', 'vehicle_other', 'for_stock', 'category', 'status')
        }),
        ('Remarks', {
            'fields': ('remark_text', 'remark_audio')
        }),
        ('Links & Bill', {
            'fields': ('linked_wo', 'bill_no')
        }),
        ('Audit', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


class POItemInline(admin.TabularInline):
    model = POItem
    extra = 0
    readonly_fields = ['amount', 'created_by', 'created_at', 'updated_at']


@admin.register(POItem)
class POItemAdmin(admin.ModelAdmin):
    list_display = ['item_name', 'purchase_order', 'quantity', 'rate', 'amount', 'assigned_vehicle', 'for_stock']
    list_filter = ['for_stock', 'created_at', 'purchase_order__vendor']
    search_fields = ['item_name', 'purchase_order__po_id']
    readonly_fields = ['amount', 'created_by', 'created_at', 'updated_at']
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(Stock)
class StockAdmin(admin.ModelAdmin):
    list_display = ['item_name', 'quantity_in_hand', 'unit', 'source_po', 'last_issue_date']
    list_filter = ['unit', 'last_issue_date', 'created_at']
    search_fields = ['item_name', 'source_po__po_id']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(IssueSlip)
class IssueSlipAdmin(admin.ModelAdmin):
    list_display = ['slip_id', 'stock_item', 'issued_quantity', 'assigned_vehicle', 'assigned_vehicle_other', 'issued_at']
    list_filter = ['issued_at', 'stock_item']
    search_fields = ['slip_id', 'stock_item__item_name', 'assigned_vehicle__vehicle_number', 'assigned_vehicle_other']
    readonly_fields = ['slip_id', 'issued_by', 'issued_at']
    
    def save_model(self, request, obj, form, change):
        if not change:  # Creating new object
            obj.issued_by = request.user
        super().save_model(request, obj, form, change)
