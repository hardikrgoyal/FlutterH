from rest_framework import serializers
from .models import Wallet, PortExpense, DigitalVoucher, WalletTopUp, TallyLog

class WalletSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)
    approved_by_name = serializers.CharField(source='approved_by.username', read_only=True)
    
    class Meta:
        model = Wallet
        fields = '__all__'
        read_only_fields = ['date', 'balance_after']

class PortExpenseSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)
    reviewed_by_name = serializers.CharField(source='reviewed_by.username', read_only=True)
    approved_by_name = serializers.CharField(source='approved_by.username', read_only=True)
    
    class Meta:
        model = PortExpense
        fields = '__all__'
        read_only_fields = ['user', 'road_tax_amount', 'total_amount', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)

class DigitalVoucherSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)
    approved_by_name = serializers.CharField(source='approved_by.username', read_only=True)
    logged_by_name = serializers.CharField(source='logged_by.username', read_only=True)
    
    class Meta:
        model = DigitalVoucher
        fields = '__all__'
        read_only_fields = ['user', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)

class WalletTopUpSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)
    topped_up_by_name = serializers.CharField(source='topped_up_by.username', read_only=True)
    
    class Meta:
        model = WalletTopUp
        fields = '__all__'
        read_only_fields = ['topped_up_by', 'created_at']
    
    def validate_user(self, value):
        """Validate that only wallet holders can be topped up"""
        if value.role == 'accountant':
            raise serializers.ValidationError("Accountants do not have wallets and cannot be topped up")
        return value
    
    def create(self, validated_data):
        validated_data['topped_up_by'] = self.context['request'].user
        return super().create(validated_data)

class TallyLogSerializer(serializers.ModelSerializer):
    logged_by_name = serializers.CharField(source='logged_by.username', read_only=True)
    
    class Meta:
        model = TallyLog
        fields = '__all__'
        read_only_fields = ['logged_by', 'logged_at']
    
    def create(self, validated_data):
        validated_data['logged_by'] = self.context['request'].user
        return super().create(validated_data) 