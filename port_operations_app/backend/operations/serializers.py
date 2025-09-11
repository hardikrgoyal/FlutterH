from rest_framework import serializers
from .models import (
    CargoOperation, RateMaster, Equipment, EquipmentRateMaster, TransportDetail, 
    LabourCost, MiscellaneousCost, RevenueStream,
    VehicleType, WorkType, PartyMaster, ContractorMaster, ServiceTypeMaster, UnitTypeMaster,
    Vehicle, VehicleDocument,
    # Maintenance system models
    Vendor, WorkOrder, PurchaseOrder, POItem, Stock, IssueSlip, WorkOrderPurchaseLink, AuditTrail
)

class CargoOperationSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = CargoOperation
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class VehicleTypeSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = VehicleType
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class WorkTypeSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = WorkType
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class PartyMasterSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = PartyMaster
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class ContractorMasterSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = ContractorMaster
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class ServiceTypeMasterSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = ServiceTypeMaster
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class UnitTypeMasterSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = UnitTypeMaster
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class VehicleSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    vehicle_type_name = serializers.CharField(source='vehicle_type.name', read_only=True)
    ownership_display = serializers.CharField(source='get_ownership_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    active_documents_count = serializers.IntegerField(read_only=True)
    expired_documents_count = serializers.IntegerField(read_only=True)
    expiring_soon_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Vehicle
        fields = [
            'id', 'vehicle_number', 'vehicle_type', 'vehicle_type_name', 'ownership', 'ownership_display',
            'status', 'status_display', 'owner_name', 'owner_contact', 'capacity', 'make_model',
            'year_of_manufacture', 'chassis_number', 'engine_number', 'remarks', 'is_active',
            'active_documents_count', 'expired_documents_count', 'expiring_soon_count',
            'created_by', 'created_by_name', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class VehicleDocumentSerializer(serializers.ModelSerializer):
    added_by_name = serializers.CharField(source='added_by.username', read_only=True)
    updated_by_name = serializers.SerializerMethodField()
    renewed_by_name = serializers.SerializerMethodField()
    vehicle_number = serializers.CharField(source='vehicle.vehicle_number', read_only=True)
    vehicle_type_name = serializers.CharField(source='vehicle.vehicle_type.name', read_only=True)
    document_type_display = serializers.CharField(source='get_document_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    days_until_expiry = serializers.IntegerField(read_only=True)
    is_expiring_soon = serializers.BooleanField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    renewal_reference_document_number = serializers.CharField(source='renewal_reference.document_number', read_only=True)
    
    def get_updated_by_name(self, obj):
        return obj.updated_by.username if obj.updated_by else None
        
    def get_renewed_by_name(self, obj):
        return obj.renewed_by.username if obj.renewed_by else None
    
    class Meta:
        model = VehicleDocument
        fields = [
            'id', 'vehicle', 'vehicle_number', 'vehicle_type_name', 'document_type', 'document_type_display',
            'document_number', 'document_file', 'issue_date', 'expiry_date', 'status', 'status_display',
            'renewal_reference', 'renewal_reference_document_number', 'notes', 'days_until_expiry',
            'is_expiring_soon', 'is_expired', 'added_by', 'added_by_name', 'added_on', 
            'updated_by', 'updated_by_name', 'updated_at', 'renewed_by', 'renewed_by_name', 'renewed_on'
        ]
        read_only_fields = ['added_by', 'added_on', 'updated_by', 'updated_at', 'renewed_by', 'renewed_on', 
                           'status', 'days_until_expiry', 'is_expiring_soon', 'is_expired']
    
    def create(self, validated_data):
        validated_data['added_by'] = self.context['request'].user
        return super().create(validated_data)
    
    def update(self, instance, validated_data):
        validated_data['updated_by'] = self.context['request'].user
        return super().update(instance, validated_data)

class VehicleDocumentHistorySerializer(serializers.ModelSerializer):
    """Serializer for viewing document history with minimal fields"""
    added_by_name = serializers.CharField(source='added_by.username', read_only=True)
    updated_by_name = serializers.SerializerMethodField()
    renewed_by_name = serializers.SerializerMethodField()
    vehicle_number = serializers.CharField(source='vehicle.vehicle_number', read_only=True)
    vehicle_type_name = serializers.CharField(source='vehicle.vehicle_type.name', read_only=True)
    document_type_display = serializers.CharField(source='get_document_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    days_until_expiry = serializers.IntegerField(read_only=True)
    is_expiring_soon = serializers.BooleanField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    renewal_reference_document_number = serializers.CharField(source='renewal_reference.document_number', read_only=True)
    
    def get_updated_by_name(self, obj):
        return obj.updated_by.username if obj.updated_by else None
        
    def get_renewed_by_name(self, obj):
        return obj.renewed_by.username if obj.renewed_by else None
    
    class Meta:
        model = VehicleDocument
        fields = [
            'id', 'vehicle', 'vehicle_number', 'vehicle_type_name', 'document_type', 'document_type_display', 
            'document_number', 'document_file', 'issue_date', 'expiry_date', 'status', 'status_display', 
            'renewal_reference', 'renewal_reference_document_number', 'notes', 'days_until_expiry',
            'is_expiring_soon', 'is_expired', 'added_by', 'added_by_name', 'added_on', 
            'updated_by', 'updated_by_name', 'updated_at', 'renewed_by', 'renewed_by_name', 'renewed_on'
        ]

class EquipmentRateMasterSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    party_name = serializers.CharField(source='party.name', read_only=True)
    vehicle_type_name = serializers.CharField(source='vehicle_type.name', read_only=True)
    work_type_name = serializers.CharField(source='work_type.name', read_only=True)
    contract_type_display = serializers.CharField(source='get_contract_type_display', read_only=True)
    unit_display = serializers.CharField(read_only=True)
    validity_status = serializers.CharField(read_only=True)
    is_currently_valid = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = EquipmentRateMaster
        fields = [
            'id', 'party', 'party_name', 'vehicle_type', 'vehicle_type_name', 
            'work_type', 'work_type_name', 'contract_type', 'contract_type_display',
            'unit', 'unit_display', 'rate', 'effective_from', 'valid_until', 'notes',
            'validity_status', 'is_currently_valid', 'is_active', 'created_by', 
            'created_by_name', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class EquipmentSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    ended_by_name = serializers.CharField(source='ended_by.username', read_only=True)
    operation_name = serializers.CharField(source='operation.operation_name', read_only=True)
    vehicle_type_name = serializers.CharField(source='vehicle_type.name', read_only=True)
    work_type_name = serializers.CharField(source='work_type.name', read_only=True)
    party_name = serializers.CharField(source='party.name', read_only=True)
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    
    class Meta:
        model = Equipment
        fields = '__all__'
        read_only_fields = ['created_by', 'ended_by', 'created_at', 'updated_at', 'duration_hours', 'status', 'amount', 'total_amount']
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        request = self.context.get('request')
        
        # Hide cost and invoice fields from supervisors
        if request and hasattr(request, 'user') and request.user.is_authenticated:
            user = request.user
            if hasattr(user, 'role') and user.role == 'supervisor':
                # Remove cost and invoice fields for supervisors
                cost_fields = ['rate', 'amount', 'total_amount', 'invoice_number', 'invoice_received', 'invoice_date']
                for field in cost_fields:
                    if field in self.fields:
                        del self.fields[field]

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class RateMasterSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    contractor_name = serializers.CharField(source='contractor.name', read_only=True)
    labour_type_display = serializers.CharField(source='get_labour_type_display', read_only=True)
    
    class Meta:
        model = RateMaster
        fields = [
            'id', 'contractor', 'contractor_name', 'labour_type', 'labour_type_display',
            'rate', 'is_active', 'created_by', 'created_by_name', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class TransportDetailSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    operation_name = serializers.CharField(source='operation.operation_name', read_only=True)
    
    class Meta:
        model = TransportDetail
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at', 'cost']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class LabourCostSerializer(serializers.ModelSerializer):
    contractor_name = serializers.CharField(source='contractor.name', read_only=True)
    contractor_id = serializers.IntegerField(source='contractor.id', read_only=True)
    operation_name = serializers.CharField(source='operation.operation_name', read_only=True)
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    labour_type_display = serializers.CharField(source='get_labour_type_display', read_only=True)
    work_type_display = serializers.CharField(source='get_work_type_display', read_only=True)
    shift_display = serializers.CharField(source='get_shift_display', read_only=True)
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)

    class Meta:
        model = LabourCost
        fields = [
            'id', 'operation', 'operation_name', 'date', 'contractor', 'contractor_id', 'contractor_name',
            'labour_type', 'labour_type_display', 'work_type', 'work_type_display', 'shift', 'shift_display',
            'labour_count_tonnage', 'rate', 'amount', 'remarks',
            'invoice_number', 'invoice_received', 'invoice_date',
            'created_by', 'created_by_name', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at', 'amount']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        request = self.context.get('request')
        
        # Hide cost and invoice fields from supervisors
        if request and hasattr(request, 'user') and request.user.is_authenticated:
            user = request.user
            if hasattr(user, 'role') and user.role == 'supervisor':
                # Remove cost and invoice fields for supervisors
                cost_fields = ['rate', 'amount', 'invoice_number', 'invoice_received', 'invoice_date']
                for field in cost_fields:
                    if field in self.fields:
                        del self.fields[field]

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

    def validate(self, data):
        # Validate shift requirement for casual labour
        if data.get('labour_type') == 'casual' and not data.get('shift'):
            raise serializers.ValidationError({'shift': 'Shift is required for casual labour type'})
        elif data.get('labour_type') != 'casual' and data.get('shift'):
            raise serializers.ValidationError({'shift': 'Shift should only be specified for casual labour type'})
        
        return data

class MiscellaneousCostSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    operation_name = serializers.CharField(source='operation.operation_name', read_only=True)
    
    class Meta:
        model = MiscellaneousCost
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at', 'total']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class RevenueStreamSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    operation_name = serializers.CharField(source='operation.operation_name', read_only=True)
    service_type_name = serializers.CharField(source='service_type.name', read_only=True)
    service_type_code = serializers.CharField(source='service_type.code', read_only=True)
    unit_type_name = serializers.CharField(source='unit_type.name', read_only=True)
    unit_type_code = serializers.CharField(source='unit_type.code', read_only=True)
    
    class Meta:
        model = RevenueStream
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at', 'amount']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data) 


# === MAINTENANCE SYSTEM SERIALIZERS ===

class VendorSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = Vendor
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class WorkOrderPurchaseLinkSerializer(serializers.ModelSerializer):
    work_order_wo_id = serializers.CharField(source='work_order.wo_id', read_only=True)
    purchase_order_po_id = serializers.CharField(source='purchase_order.po_id', read_only=True)

    class Meta:
        model = WorkOrderPurchaseLink
        fields = ['id', 'work_order', 'purchase_order', 'work_order_wo_id', 'purchase_order_po_id', 'created_by', 'created_at']
        read_only_fields = ['created_by', 'created_at']


class WorkOrderSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    vendor_name = serializers.CharField(source='vendor.name', read_only=True)
    vehicle_number = serializers.CharField(source='vehicle.vehicle_number', read_only=True)
    linked_po_id = serializers.CharField(source='linked_po.po_id', read_only=True)
    linked_po_ids = serializers.SerializerMethodField()

    class Meta:
        model = WorkOrder
        fields = '__all__'
        read_only_fields = ['wo_id', 'created_by', 'created_at', 'updated_at']

    def get_linked_po_ids(self, obj):
        return [link.purchase_order.po_id for link in obj.po_links.all()]

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)
    
    def validate(self, data):
        # Ensure either vehicle or vehicle_other is provided
        if not data.get('vehicle') and not data.get('vehicle_other'):
            raise serializers.ValidationError("Either vehicle or vehicle_other must be provided")
        return data


class PurchaseOrderSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    vendor_name = serializers.CharField(source='vendor.name', read_only=True)
    vehicle_number = serializers.CharField(source='vehicle.vehicle_number', read_only=True)
    linked_wo_id = serializers.CharField(source='linked_wo.wo_id', read_only=True)
    linked_wo_ids = serializers.SerializerMethodField()
    duplicate_warning = serializers.SerializerMethodField()
    items_count = serializers.SerializerMethodField()
    total_amount = serializers.SerializerMethodField()

    class Meta:
        model = PurchaseOrder
        fields = '__all__'
        read_only_fields = ['po_id', 'created_by', 'created_at', 'updated_at']

    def get_linked_wo_ids(self, obj):
        return [link.work_order.wo_id for link in obj.wo_links.all()]

    def get_duplicate_warning(self, obj):
        if hasattr(obj, '_duplicate_warning'):
            return obj._duplicate_warning
        return obj.check_duplicate_po_warning()
    
    def get_items_count(self, obj):
        return obj.items.count()
    
    def get_total_amount(self, obj):
        return sum(item.amount for item in obj.items.all())
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        
        # Check for duplicate PO warning
        po = PurchaseOrder(**validated_data)
        duplicate_warning = po.check_duplicate_po_warning()
        if duplicate_warning:
            po._duplicate_warning = duplicate_warning
        
        return super().create(validated_data)
    
    def validate(self, data):
        # Ensure either vehicle, vehicle_other, or for_stock is specified
        if not data.get('for_stock'):
            if not data.get('vehicle') and not data.get('vehicle_other'):
                raise serializers.ValidationError("Either vehicle, vehicle_other, or for_stock must be specified")
        return data


class POItemSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    purchase_order_id = serializers.CharField(source='purchase_order.po_id', read_only=True)
    assigned_vehicle_number = serializers.CharField(source='assigned_vehicle.vehicle_number', read_only=True)
    quantity = serializers.DecimalField(max_digits=10, decimal_places=3)
    rate = serializers.DecimalField(max_digits=10, decimal_places=2)
    
    class Meta:
        model = POItem
        fields = '__all__'
        read_only_fields = ['amount', 'created_by', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class StockSerializer(serializers.ModelSerializer):
    source_po_id = serializers.CharField(source='source_po.po_id', read_only=True)
    source_po_item_name = serializers.CharField(source='source_po_item.item_name', read_only=True)
    vendor_name = serializers.CharField(source='source_po.vendor.name', read_only=True)
    
    class Meta:
        model = Stock
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


class IssueSlipSerializer(serializers.ModelSerializer):
    issued_by_name = serializers.CharField(source='issued_by.username', read_only=True)
    stock_item_name = serializers.CharField(source='stock_item.item_name', read_only=True)
    assigned_vehicle_number = serializers.CharField(source='assigned_vehicle.vehicle_number', read_only=True)
    
    class Meta:
        model = IssueSlip
        fields = '__all__'
        read_only_fields = ['slip_id', 'issued_by', 'issued_at']
    
    def create(self, validated_data):
        validated_data['issued_by'] = self.context['request'].user
        return super().create(validated_data)
    
    def validate(self, data):
        # Check if sufficient stock is available
        stock_item = data.get('stock_item')
        issued_quantity = data.get('issued_quantity')
        
        if stock_item and issued_quantity:
            if issued_quantity > stock_item.quantity_in_hand:
                raise serializers.ValidationError(
                    f"Insufficient stock. Available: {stock_item.quantity_in_hand}, Requested: {issued_quantity}"
                )
        
        # Ensure either assigned_vehicle or assigned_vehicle_other is provided
        if not data.get('assigned_vehicle') and not data.get('assigned_vehicle_other'):
            raise serializers.ValidationError("Either assigned_vehicle or assigned_vehicle_other must be provided")
        
        return data 


class AuditTrailSerializer(serializers.ModelSerializer):
    performed_by_name = serializers.CharField(source='performed_by.username', read_only=True)

    class Meta:
        model = AuditTrail
        fields = ['id', 'entity_type', 'entity_id', 'related_entity_type', 'related_entity_id', 'action', 'performed_by', 'performed_by_name', 'source', 'created_at']
        read_only_fields = ['created_at'] 