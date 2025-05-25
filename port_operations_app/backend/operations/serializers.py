from rest_framework import serializers
from .models import (
    CargoOperation, RateMaster, Equipment, TransportDetail, 
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
    class Meta:
        model = ContractorMaster
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at']
    
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
    
    class Meta:
        model = Equipment
        fields = '__all__'
        read_only_fields = ['created_by', 'ended_by', 'created_at', 'updated_at', 'duration_hours', 'status']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

class RateMasterSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = RateMaster
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at']
    
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
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    operation_name = serializers.CharField(source='operation.operation_name', read_only=True)
    contractor_name = serializers.CharField(source='contractor.name', read_only=True)
    contractor_id = serializers.IntegerField(source='contractor.id', read_only=True)
    
    class Meta:
        model = LabourCost
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at', 'amount']
    
    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)

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