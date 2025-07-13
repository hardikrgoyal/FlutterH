from django.contrib import admin
from .models import (
    CargoOperation, RateMaster, Equipment, EquipmentRateMaster, TransportDetail, 
    LabourCost, MiscellaneousCost, RevenueStream,
    VehicleType, WorkType, PartyMaster, ContractorMaster
)

@admin.register(CargoOperation)
class CargoOperationAdmin(admin.ModelAdmin):
    list_display = ['operation_name', 'party_name', 'cargo_type', 'weight', 'project_status', 'date', 'created_by']
    list_filter = ['project_status', 'cargo_type', 'date', 'created_at']
    search_fields = ['operation_name', 'party_name', 'packaging']
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
