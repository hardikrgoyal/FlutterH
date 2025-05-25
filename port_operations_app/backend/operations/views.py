from django.shortcuts import render
from rest_framework import viewsets, generics, status
from rest_framework.response import Response
from rest_framework.decorators import action
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import datetime, timedelta

from .models import (
    CargoOperation, RateMaster, Equipment, TransportDetail, 
    LabourCost, MiscellaneousCost, RevenueStream,
    VehicleType, WorkType, PartyMaster
)
from .serializers import (
    CargoOperationSerializer, RateMasterSerializer, EquipmentSerializer,
    TransportDetailSerializer, LabourCostSerializer, MiscellaneousCostSerializer,
    RevenueStreamSerializer, VehicleTypeSerializer, WorkTypeSerializer, PartyMasterSerializer
)
from authentication.permissions import (
    CanCreateOperations, CanManageEquipment, IsManagerOrAdmin,
    IsSupervisorOrAbove, IsAccountantOrAdmin
)

class CargoOperationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing cargo operations
    """
    queryset = CargoOperation.objects.all()
    serializer_class = CargoOperationSerializer
    permission_classes = [IsSupervisorOrAbove]
    
    def get_permissions(self):
        """
        Supervisors can read operations, but only managers and admins can create/update/delete
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [CanCreateOperations]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        queryset = CargoOperation.objects.all()
        status = self.request.query_params.get('status', None)
        cargo_type = self.request.query_params.get('cargo_type', None)
        running_only = self.request.query_params.get('running_only', None)
        
        if status:
            queryset = queryset.filter(project_status=status)
        if cargo_type:
            queryset = queryset.filter(cargo_type=cargo_type)
        if running_only:
            # For equipment start form - only show running and pending operations
            queryset = queryset.filter(project_status__in=['pending', 'ongoing'])
            
        return queryset
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

class VehicleTypeViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing vehicle types
    """
    queryset = VehicleType.objects.filter(is_active=True)
    serializer_class = VehicleTypeSerializer
    permission_classes = [IsSupervisorOrAbove]
    
    def get_permissions(self):
        """
        Only managers and admins can create/update/delete vehicle types
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [IsManagerOrAdmin]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]

class WorkTypeViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing work types
    """
    queryset = WorkType.objects.filter(is_active=True)
    serializer_class = WorkTypeSerializer
    permission_classes = [IsSupervisorOrAbove]
    
    def get_permissions(self):
        """
        Only managers and admins can create/update/delete work types
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [IsManagerOrAdmin]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]

class PartyMasterViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing party master data
    """
    queryset = PartyMaster.objects.filter(is_active=True)
    serializer_class = PartyMasterSerializer
    permission_classes = [IsSupervisorOrAbove]
    
    def get_permissions(self):
        """
        Only managers and admins can create/update/delete parties
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [IsManagerOrAdmin]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]

class RateMasterViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing rate master
    """
    queryset = RateMaster.objects.all()
    serializer_class = RateMasterSerializer
    permission_classes = [IsManagerOrAdmin]
    
    def get_queryset(self):
        queryset = RateMaster.objects.all()
        category = self.request.query_params.get('category', None)
        is_active = self.request.query_params.get('is_active', None)
        
        if category:
            queryset = queryset.filter(category=category)
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')
            
        return queryset

class EquipmentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing equipment
    """
    queryset = Equipment.objects.all()
    serializer_class = EquipmentSerializer
    permission_classes = [CanManageEquipment]
    
    def get_queryset(self):
        queryset = Equipment.objects.all()
        status = self.request.query_params.get('status', None)
        operation_id = self.request.query_params.get('operation', None)
        running_only = self.request.query_params.get('running_only', None)
        
        if status:
            queryset = queryset.filter(status=status)
        if operation_id:
            queryset = queryset.filter(operation_id=operation_id)
        if running_only:
            queryset = queryset.filter(status='running')
            
        return queryset
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=False, methods=['get'], url_path='running')
    def running_equipment(self, request):
        """
        Get all running equipment
        """
        running_equipment = Equipment.objects.filter(status='running')
        serializer = self.get_serializer(running_equipment, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['patch'], url_path='end')
    def end_equipment(self, request, pk=None):
        """
        End equipment operation
        """
        equipment = self.get_object()
        
        if equipment.status != 'running':
            return Response(
                {'error': 'Equipment is not currently running'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        end_time = request.data.get('end_time')
        comments = request.data.get('comments', '')
        
        if not end_time:
            end_time = timezone.now()
        else:
            try:
                # Parse the datetime and make it timezone-aware
                if end_time.endswith('Z'):
                    end_time = end_time.replace('Z', '+00:00')
                
                # Parse the datetime
                parsed_time = datetime.fromisoformat(end_time)
                
                # If the parsed time is naive, make it timezone-aware
                if parsed_time.tzinfo is None:
                    end_time = timezone.make_aware(parsed_time)
                else:
                    end_time = parsed_time
                    
            except ValueError:
                return Response(
                    {'error': 'Invalid end_time format'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        equipment.end_time = end_time
        equipment.comments = comments
        equipment.ended_by = request.user
        equipment.save()  # This will trigger the duration calculation
        
        serializer = self.get_serializer(equipment)
        return Response(serializer.data)

class TransportDetailViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing transport details
    """
    queryset = TransportDetail.objects.all()
    serializer_class = TransportDetailSerializer
    permission_classes = [IsManagerOrAdmin]
    
    def get_queryset(self):
        queryset = TransportDetail.objects.all()
        operation_id = self.request.query_params.get('operation', None)
        
        if operation_id:
            queryset = queryset.filter(operation_id=operation_id)
            
        return queryset

class LabourCostViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing labour costs
    """
    queryset = LabourCost.objects.all()
    serializer_class = LabourCostSerializer
    permission_classes = [IsManagerOrAdmin]
    
    def get_queryset(self):
        queryset = LabourCost.objects.all()
        operation_id = self.request.query_params.get('operation', None)
        labour_type = self.request.query_params.get('labour_type', None)
        
        if operation_id:
            queryset = queryset.filter(operation_id=operation_id)
        if labour_type:
            queryset = queryset.filter(labour_type=labour_type)
            
        return queryset

class MiscellaneousCostViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing miscellaneous costs
    """
    queryset = MiscellaneousCost.objects.all()
    serializer_class = MiscellaneousCostSerializer
    permission_classes = [IsManagerOrAdmin]
    
    def get_queryset(self):
        queryset = MiscellaneousCost.objects.all()
        operation_id = self.request.query_params.get('operation', None)
        cost_type = self.request.query_params.get('cost_type', None)
        
        if operation_id:
            queryset = queryset.filter(operation_id=operation_id)
        if cost_type:
            queryset = queryset.filter(cost_type=cost_type)
            
        return queryset

class RevenueStreamViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing revenue streams
    """
    queryset = RevenueStream.objects.all()
    serializer_class = RevenueStreamSerializer
    permission_classes = [IsAccountantOrAdmin]
    
    def get_queryset(self):
        queryset = RevenueStream.objects.all()
        operation_id = self.request.query_params.get('operation', None)
        service_type = self.request.query_params.get('service_type', None)
        
        if operation_id:
            queryset = queryset.filter(operation_id=operation_id)
        if service_type:
            queryset = queryset.filter(service_type=service_type)
            
        return queryset

class DashboardView(generics.GenericAPIView):
    """
    Dashboard view with role-specific data
    """
    permission_classes = [IsSupervisorOrAbove]
    
    def get(self, request):
        user = request.user
        today = timezone.now().date()
        
        # Common data for all roles
        data = {
            'user': {
                'id': user.id,
                'username': user.username,
                'role': user.role,
                'full_name': f"{user.first_name} {user.last_name}".strip()
            },
            'date': today
        }
        
        if user.is_admin:
            # Admin dashboard data
            data.update({
                'total_operations': CargoOperation.objects.count(),
                'ongoing_operations': CargoOperation.objects.filter(project_status='ongoing').count(),
                'pending_operations': CargoOperation.objects.filter(project_status='pending').count(),
                'running_equipment': Equipment.objects.filter(status='running').count(),
                'total_revenue': RevenueStream.objects.aggregate(
                    total=Sum('amount'))['total'] or 0,
                'recent_operations': CargoOperationSerializer(
                    CargoOperation.objects.all()[:5], many=True
                ).data
            })
            
        elif user.is_manager:
            # Manager dashboard data
            data.update({
                'my_operations': CargoOperation.objects.filter(created_by=user).count(),
                'running_equipment': Equipment.objects.filter(status='running').count(),
                'transport_entries_today': TransportDetail.objects.filter(
                    date=today).count(),
                'labour_entries_today': LabourCost.objects.filter(
                    date=today).count(),
                'recent_equipment': EquipmentSerializer(
                    Equipment.objects.filter(status='running')[:5], many=True
                ).data
            })
            
        elif user.is_supervisor:
            # Supervisor dashboard data
            from financial.models import Wallet
            wallet_balance = Wallet.get_balance(user)
            
            data.update({
                'wallet_balance': wallet_balance,
                'running_equipment': Equipment.objects.filter(
                    created_by=user, status='running').count(),
                'equipment_today': Equipment.objects.filter(
                    created_by=user, created_at__date=today).count(),
                'recent_equipment': EquipmentSerializer(
                    Equipment.objects.filter(created_by=user, status='running')[:5], 
                    many=True
                ).data
            })
            
        elif user.is_accountant:
            # Accountant dashboard data
            from financial.models import PortExpense, DigitalVoucher
            
            data.update({
                'pending_expenses': PortExpense.objects.filter(
                    status='approved').count(),
                'pending_vouchers': DigitalVoucher.objects.filter(
                    status='approved').count(),
                'total_revenue': RevenueStream.objects.aggregate(
                    total=Sum('amount'))['total'] or 0,
                'expenses_today': PortExpense.objects.filter(
                    created_at__date=today).count()
            })
        
        return Response(data)
