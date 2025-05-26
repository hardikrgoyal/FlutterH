from django.contrib import admin
from .models import (
    CargoOperation, RateMaster, Equipment, TransportDetail, 
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

@admin.register(VehicleType)
class VehicleTypeAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active', 'created_by', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name']
    readonly_fields = ['created_at']

@admin.register(WorkType)
class WorkTypeAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active', 'created_by', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name']
    readonly_fields = ['created_at']

@admin.register(PartyMaster)
class PartyMasterAdmin(admin.ModelAdmin):
    list_display = ['name', 'contact_person', 'phone_number', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'contact_person', 'phone_number']
    readonly_fields = ['created_by', 'created_at']

@admin.register(Equipment)
class EquipmentAdmin(admin.ModelAdmin):
    list_display = ['vehicle_type', 'vehicle_number', 'operation', 'status', 'start_time', 'end_time', 'duration_hours']
    list_filter = ['status', 'contract_type', 'date', 'created_at']
    search_fields = ['vehicle_number', 'operation__operation_name', 'vehicle_type__name', 'party__name']
    readonly_fields = ['duration_hours', 'created_at', 'updated_at']
    date_hierarchy = 'start_time'

@admin.register(RateMaster)
class RateMasterAdmin(admin.ModelAdmin):
    list_display = ['contractor', 'labour_type', 'rate', 'is_active', 'created_at']
    list_filter = ['labour_type', 'is_active', 'created_at']
    search_fields = ['contractor__name']
    readonly_fields = ['created_by', 'created_at', 'updated_at']

@admin.register(TransportDetail)
class TransportDetailAdmin(admin.ModelAdmin):
    list_display = ['vehicle', 'vehicle_number', 'operation', 'party_name', 'date', 'cost']
    list_filter = ['contract_type', 'date']
    search_fields = ['vehicle', 'vehicle_number', 'operation__operation_name', 'party_name']
    readonly_fields = ['cost', 'created_at', 'updated_at']
    date_hierarchy = 'date'

@admin.register(ContractorMaster)
class ContractorMasterAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name']
    readonly_fields = ['created_by', 'created_at']

@admin.register(LabourCost)
class LabourCostAdmin(admin.ModelAdmin):
    list_display = ['contractor', 'labour_type', 'shift', 'work_type', 'operation', 'date', 'amount', 'invoice_received', 'invoice_number']
    list_filter = ['labour_type', 'shift', 'work_type', 'date', 'invoice_received', 'contractor']
    search_fields = ['contractor__name', 'operation__operation_name', 'invoice_number']
    readonly_fields = ['amount', 'created_at', 'updated_at']
    date_hierarchy = 'date'

@admin.register(MiscellaneousCost)
class MiscellaneousCostAdmin(admin.ModelAdmin):
    list_display = ['cost_type', 'party', 'operation', 'date', 'total']
    list_filter = ['cost_type', 'date']
    search_fields = ['party', 'operation__operation_name']
    readonly_fields = ['total', 'created_at', 'updated_at']
    date_hierarchy = 'date'

@admin.register(RevenueStream)
class RevenueStreamAdmin(admin.ModelAdmin):
    list_display = ['service_type', 'party', 'operation', 'date', 'amount']
    list_filter = ['service_type', 'unit_type', 'date']
    search_fields = ['party', 'operation__operation_name']
    readonly_fields = ['amount', 'created_at', 'updated_at']
    date_hierarchy = 'date'
