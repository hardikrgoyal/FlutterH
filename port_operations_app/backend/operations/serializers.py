from rest_framework import serializers
from .models import (
    CargoOperation, RateMaster, Equipment, EquipmentRateMaster, TransportDetail, 
    LabourCost, MiscellaneousCost, RevenueStream,
    VehicleType, WorkType, PartyMaster, ContractorMaster
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

class EquipmentRateMasterSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    party_name = serializers.CharField(source='party.name', read_only=True)
    vehicle_type_name = serializers.CharField(source='vehicle_type.name', read_only=True)
    work_type_name = serializers.CharField(source='work_type.name', read_only=True)
    contract_type_display = serializers.CharField(source='get_contract_type_display', read_only=True)
    
    class Meta:
        model = EquipmentRateMaster
        fields = [
            'id', 'party', 'party_name', 'vehicle_type', 'vehicle_type_name', 
            'work_type', 'work_type_name', 'contract_type', 'contract_type_display',
            'rate', 'is_active', 'created_by', 'created_by_name', 'created_at', 'updated_at'
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
    
    class Meta:
        model = RevenueStream
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at', 'amount']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data) 