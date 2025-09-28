from django.shortcuts import render
from rest_framework import viewsets, generics, status
from rest_framework.response import Response
from rest_framework.decorators import action
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import datetime, timedelta

from .models import (
    CargoOperation, RateMaster, Equipment, EquipmentRateMaster, TransportDetail, 
    LabourCost, MiscellaneousCost, RevenueStream,
    VehicleType, WorkType, PartyMaster, ContractorMaster, ServiceTypeMaster, UnitTypeMaster,
    Vehicle, VehicleDocument,
    # List management models
    ListTypeMaster, ListItemMaster, ListItemAuditLog,
    # Maintenance system models
    Vendor, POVendor, WOVendor, WorkOrder, PurchaseOrder, POItem, Stock, IssueSlip, WorkOrderPurchaseLink, AuditTrail, VendorAuditLog
)
from .signals import create_list_item_audit_log, create_audit_log
from .serializers import (
    VendorAuditLogSerializer,
    CargoOperationSerializer, RateMasterSerializer, EquipmentSerializer, EquipmentRateMasterSerializer,
    TransportDetailSerializer, LabourCostSerializer, MiscellaneousCostSerializer,
    RevenueStreamSerializer, VehicleTypeSerializer, WorkTypeSerializer, 
    PartyMasterSerializer, ContractorMasterSerializer, ServiceTypeMasterSerializer, UnitTypeMasterSerializer,
    VehicleSerializer, VehicleDocumentSerializer, VehicleDocumentHistorySerializer,
    # List management serializers
    ListTypeMasterSerializer, ListItemMasterSerializer, ListItemMasterSimpleSerializer, ListItemAuditLogSerializer,
    # Maintenance system serializers
    VendorSerializer, POVendorSerializer, WOVendorSerializer, WorkOrderSerializer, PurchaseOrderSerializer, POItemSerializer,
    StockSerializer, IssueSlipSerializer, WorkOrderPurchaseLinkSerializer, AuditTrailSerializer
)
from authentication.permissions import (
    CanCreateOperations, CanManageEquipment, IsManagerOrAdmin,
    IsSupervisorOrAbove, IsAccountantOrAdmin, CanAccessLabourCosts, CanManageRevenue,
    CanManageVehicles, CanViewVehicles,
    # Maintenance system permissions
    CanCreateWorkOrders, CanManageWorkOrders, CanCreatePurchaseOrders, CanManagePurchaseOrders,
    CanManageVendors, CanEnterBillNumbers, CanManageStock, CanViewStock, CanCreateIssueSlips,
    CanItemizePurchaseOrders
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
        cargo_type = self.request.query_params.get('cargo_type', None)
        
        if cargo_type:
            queryset = queryset.filter(cargo_type=cargo_type)
            
        return queryset
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

class VehicleTypeViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing vehicle types
    """
    queryset = VehicleType.objects.filter(is_active=True)
    serializer_class = VehicleTypeSerializer
    permission_classes = [CanViewVehicles]
    pagination_class = None  # Disable pagination for master data
    
    def get_permissions(self):
        """
        All authenticated users can view vehicle types, only managers and admins can create/update/delete
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [IsManagerOrAdmin]
        else:
            permission_classes = [CanViewVehicles]
        return [permission() for permission in permission_classes]

class WorkTypeViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing work types
    """
    queryset = WorkType.objects.filter(is_active=True)
    serializer_class = WorkTypeSerializer
    permission_classes = [IsSupervisorOrAbove]
    pagination_class = None  # Disable pagination for master data
    
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
    pagination_class = None  # Disable pagination for master data
    
    def get_permissions(self):
        """
        Only managers and admins can create/update/delete parties
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [IsManagerOrAdmin]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]

class ContractorMasterViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing contractor master data
    """
    queryset = ContractorMaster.objects.filter(is_active=True)
    serializer_class = ContractorMasterSerializer
    permission_classes = [IsSupervisorOrAbove]
    pagination_class = None  # Disable pagination for master data
    
    def get_permissions(self):
        """
        Only managers and admins can create/update/delete contractors
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [IsManagerOrAdmin]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]

class ServiceTypeMasterViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing service type master data
    """
    queryset = ServiceTypeMaster.objects.filter(is_active=True)
    serializer_class = ServiceTypeMasterSerializer
    permission_classes = [IsSupervisorOrAbove]
    pagination_class = None  # Disable pagination for master data
    
    def get_permissions(self):
        """
        Supervisors can read, but only managers and admins can create/update/delete
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [IsManagerOrAdmin]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]

class UnitTypeMasterViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing unit type master data
    """
    queryset = UnitTypeMaster.objects.filter(is_active=True)
    serializer_class = UnitTypeMasterSerializer
    permission_classes = [IsSupervisorOrAbove]
    pagination_class = None  # Disable pagination for master data
    
    def get_permissions(self):
        """
        Supervisors can read, but only managers and admins can create/update/delete
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [IsManagerOrAdmin]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]

class VehicleViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing vehicles
    """
    queryset = Vehicle.objects.filter(is_active=True)
    serializer_class = VehicleSerializer
    permission_classes = [CanViewVehicles]
    
    def get_permissions(self):
        """
        All authenticated users can view vehicles, but only Admin/Manager/Accountant can edit
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [CanManageVehicles]
        else:
            permission_classes = [CanViewVehicles]
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        queryset = Vehicle.objects.filter(is_active=True)
        vehicle_type = self.request.query_params.get('vehicle_type', None)
        status = self.request.query_params.get('status', None)
        ownership = self.request.query_params.get('ownership', None)
        
        if vehicle_type:
            queryset = queryset.filter(vehicle_type_id=vehicle_type)
        if status:
            queryset = queryset.filter(status=status)
        if ownership:
            queryset = queryset.filter(ownership=ownership)
            
        return queryset
    
    @action(detail=True, methods=['get'], url_path='documents')
    def get_vehicle_documents(self, request, pk=None):
        """
        Get all documents for a specific vehicle grouped by type
        """
        vehicle = self.get_object()
        documents = VehicleDocument.objects.filter(vehicle=vehicle)
        
        # Group documents by type
        grouped_docs = {}
        for doc in documents:
            doc_type = doc.document_type
            if doc_type not in grouped_docs:
                grouped_docs[doc_type] = {
                    'type': doc_type,
                    'type_display': doc.get_document_type_display(),
                    'current': None,
                    'history': []
                }
            
            doc_data = VehicleDocumentHistorySerializer(doc).data
            if doc.status == 'active':
                grouped_docs[doc_type]['current'] = doc_data
            grouped_docs[doc_type]['history'].append(doc_data)
        
        return Response(list(grouped_docs.values()))
    
    @action(detail=False, methods=['get'], url_path='expiring-documents')
    def expiring_documents(self, request):
        """
        Get vehicles with documents expiring soon
        """
        from datetime import date, timedelta
        thirty_days_from_now = date.today() + timedelta(days=30)
        
        vehicles_with_expiring_docs = Vehicle.objects.filter(
            documents__status='active',
            documents__expiry_date__lte=thirty_days_from_now,
            documents__expiry_date__gte=date.today(),
            is_active=True
        ).distinct()
        
        result = []
        for vehicle in vehicles_with_expiring_docs:
            expiring_docs = vehicle.documents.filter(
                status='active',
                expiry_date__lte=thirty_days_from_now,
                expiry_date__gte=date.today()
            )
            
            vehicle_data = VehicleSerializer(vehicle).data
            vehicle_data['expiring_documents'] = VehicleDocumentHistorySerializer(expiring_docs, many=True).data
            result.append(vehicle_data)
        
        return Response(result)

class VehicleDocumentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing vehicle documents
    """
    queryset = VehicleDocument.objects.all()
    serializer_class = VehicleDocumentSerializer
    permission_classes = [CanViewVehicles]
    
    def get_permissions(self):
        """
        All authenticated users can view documents, but only Admin/Manager/Accountant can edit
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [CanManageVehicles]
        else:
            permission_classes = [CanViewVehicles]
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        queryset = VehicleDocument.objects.all()
        vehicle_id = self.request.query_params.get('vehicle', None)
        document_type = self.request.query_params.get('document_type', None)
        status = self.request.query_params.get('status', None)
        expiring_soon = self.request.query_params.get('expiring_soon', None)
        
        if vehicle_id:
            queryset = queryset.filter(vehicle_id=vehicle_id)
        if document_type:
            queryset = queryset.filter(document_type=document_type)
        if status:
            queryset = queryset.filter(status=status)
        if expiring_soon == 'true':
            from datetime import date, timedelta
            thirty_days_from_now = date.today() + timedelta(days=30)
            queryset = queryset.filter(
                status='active',
                expiry_date__lte=thirty_days_from_now,
                expiry_date__gte=date.today()
            )
            
        return queryset
    
    @action(detail=False, methods=['get'], url_path='expiring-soon')
    def expiring_soon(self, request):
        """
        Get all documents expiring within 30 days
        """
        from datetime import date, timedelta
        thirty_days_from_now = date.today() + timedelta(days=30)
        
        expiring_docs = VehicleDocument.objects.filter(
            status='active',
            expiry_date__lte=thirty_days_from_now,
            expiry_date__gte=date.today()
        ).order_by('expiry_date')
        
        serializer = self.get_serializer(expiring_docs, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], url_path='expired')
    def expired_documents(self, request):
        """
        Get all expired documents
        """
        expired_docs = VehicleDocument.objects.filter(status='expired').order_by('-expiry_date')
        serializer = self.get_serializer(expired_docs, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'], url_path='renew')
    def renew_document(self, request, pk=None):
        """
        Renew a document by creating a new version
        """
        old_document = self.get_object()
        
        # Create new document data
        new_data = request.data.copy()
        new_data['vehicle'] = old_document.vehicle.id
        new_data['document_type'] = old_document.document_type
        new_data['renewal_reference'] = old_document.id
        
        # Create the new document
        serializer = self.get_serializer(data=new_data)
        if serializer.is_valid():
            from django.utils import timezone
            
            # Save new document with renewal tracking
            new_document = serializer.save(
                added_by=request.user,
                renewed_by=request.user,
                renewed_on=timezone.now()
            )
            
            # Mark old document as expired and track who renewed it
            old_document.status = 'expired'
            old_document.renewed_by = request.user
            old_document.renewed_on = timezone.now()
            old_document.save()
            
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'], url_path='document-types')
    def document_types(self, request):
        """
        Get available document types
        """
        return Response([
            {'value': choice[0], 'label': choice[1]} 
            for choice in VehicleDocument.DOCUMENT_TYPE_CHOICES
        ])

class RateMasterViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing contractor rate master data
    """
    queryset = RateMaster.objects.filter(is_active=True)
    serializer_class = RateMasterSerializer
    permission_classes = [IsManagerOrAdmin]  # Only managers and admins can manage rates
    pagination_class = None  # Disable pagination for master data
    
    def get_queryset(self):
        queryset = super().get_queryset()
        contractor_id = self.request.query_params.get('contractor', None)
        labour_type = self.request.query_params.get('labour_type', None)
        
        if contractor_id:
            queryset = queryset.filter(contractor_id=contractor_id)
        if labour_type:
            queryset = queryset.filter(labour_type=labour_type)
            
        return queryset

class EquipmentRateMasterViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing equipment rate master data
    """
    queryset = EquipmentRateMaster.objects.filter(is_active=True)
    serializer_class = EquipmentRateMasterSerializer
    permission_classes = [IsManagerOrAdmin]  # Only managers and admins can manage rates
    pagination_class = None  # Disable pagination for master data
    
    def get_queryset(self):
        queryset = super().get_queryset()
        party_id = self.request.query_params.get('party', None)
        vehicle_type_id = self.request.query_params.get('vehicle_type', None)
        work_type_id = self.request.query_params.get('work_type', None)
        contract_type = self.request.query_params.get('contract_type', None)
        
        if party_id:
            queryset = queryset.filter(party_id=party_id)
        if vehicle_type_id:
            queryset = queryset.filter(vehicle_type_id=vehicle_type_id)
        if work_type_id:
            queryset = queryset.filter(work_type_id=work_type_id)
        if contract_type:
            queryset = queryset.filter(contract_type=contract_type)
            
        return queryset

class EquipmentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing equipment
    """
    queryset = Equipment.objects.all()
    serializer_class = EquipmentSerializer
    permission_classes = [CanManageEquipment]
    
    def get_permissions(self):
        """
        Instantiate and return the list of permissions required for this view.
        """
        permission_classes = [CanManageEquipment]
        return [permission() for permission in permission_classes]
    
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
    
    def create(self, request, *args, **kwargs):
        """
        Custom create method to handle supervisor restrictions
        """
        # Supervisors can create but without billing tracking fields
        if request.user.role == 'supervisor':
            # Remove billing tracking fields from supervisor requests
            data = request.data.copy()
            data.pop('rate', None)
            data.pop('invoice_number', None)
            data.pop('invoice_received', None)
            data.pop('invoice_date', None)
            request._full_data = data
        
        return super().create(request, *args, **kwargs)
    
    def update(self, request, *args, **kwargs):
        """
        Custom update method to handle supervisor restrictions
        """
        # Supervisors cannot edit equipment records
        if request.user.role == 'supervisor':
            return Response(
                {'error': 'Supervisors do not have edit permissions'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().update(request, *args, **kwargs)
    
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
        quantity = request.data.get('quantity')
        
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
        
        # Handle quantity for tonnes contract type
        if equipment.contract_type == 'tonnes':
            if not quantity:
                return Response(
                    {'error': 'Quantity is required for tonnes contract type'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            try:
                quantity_decimal = float(quantity)
                if quantity_decimal <= 0:
                    return Response(
                        {'error': 'Quantity must be greater than 0'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                equipment.quantity = quantity_decimal
            except (ValueError, TypeError):
                return Response(
                    {'error': 'Invalid quantity format'}, 
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
    permission_classes = [CanAccessLabourCosts]
    
    def get_permissions(self):
        """
        Instantiate and return the list of permissions required for this view.
        """
        permission_classes = [CanAccessLabourCosts]
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        queryset = LabourCost.objects.all()
        operation_id = self.request.query_params.get('operation', None)
        labour_type = self.request.query_params.get('labour_type', None)
        invoice_received = self.request.query_params.get('invoice_received', None)
        
        if operation_id:
            queryset = queryset.filter(operation_id=operation_id)
        if labour_type:
            queryset = queryset.filter(labour_type=labour_type)
        if invoice_received is not None:
            # Convert string parameter to boolean
            if invoice_received.lower() == 'true':
                queryset = queryset.filter(invoice_received=True)
            elif invoice_received.lower() == 'false':
                queryset = queryset.filter(invoice_received=False)
            elif invoice_received.lower() == 'null':
                queryset = queryset.filter(invoice_received__isnull=True)
            
        return queryset
    
    def create(self, request, *args, **kwargs):
        """
        Custom create method to handle supervisor restrictions
        """
        # Supervisors can create but without invoice tracking fields
        if request.user.role == 'supervisor':
            # Remove invoice tracking fields from supervisor requests
            data = request.data.copy()
            data.pop('invoice_number', None)
            data.pop('invoice_received', None)
            data.pop('invoice_date', None)
            request._full_data = data
        
        return super().create(request, *args, **kwargs)
    
    def update(self, request, *args, **kwargs):
        """
        Custom update method to handle supervisor restrictions
        """
        # Supervisors cannot edit
        if request.user.role == 'supervisor':
            return Response(
                {'error': 'Supervisors do not have edit permissions'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().update(request, *args, **kwargs)
    
    def partial_update(self, request, *args, **kwargs):
        """
        Custom partial update method to handle supervisor restrictions
        """
        # Supervisors cannot edit
        if request.user.role == 'supervisor':
            return Response(
                {'error': 'Supervisors do not have edit permissions'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().partial_update(request, *args, **kwargs)
    
    def destroy(self, request, *args, **kwargs):
        """
        Custom destroy method to handle supervisor restrictions
        """
        # Supervisors cannot delete
        if request.user.role == 'supervisor':
            return Response(
                {'error': 'Supervisors do not have delete permissions'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().destroy(request, *args, **kwargs)

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
    permission_classes = [CanManageRevenue]
    
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
        thirty_days_from_now = today + timedelta(days=30)
        
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
        
        # Vehicle document alerts for all users
        expiring_docs = VehicleDocument.objects.filter(
            status='active',
            expiry_date__lte=thirty_days_from_now,
            expiry_date__gte=today
        ).select_related('vehicle', 'vehicle__vehicle_type').order_by('expiry_date')[:5]
        
        expired_docs = VehicleDocument.objects.filter(
            status='expired',
            expiry_date__gte=today - timedelta(days=7)  # Show recently expired
        ).select_related('vehicle', 'vehicle__vehicle_type').order_by('-expiry_date')[:5]
        
        data['vehicle_alerts'] = {
            'expiring_soon': [
                {
                    'vehicle_number': doc.vehicle.vehicle_number,
                    'document_type': doc.get_document_type_display(),
                    'document_number': doc.document_number,
                    'expiry_date': doc.expiry_date,
                    'days_until_expiry': doc.days_until_expiry,
                    'is_urgent': doc.days_until_expiry <= 7,
                } for doc in expiring_docs
            ],
            'recently_expired': [
                {
                    'vehicle_number': doc.vehicle.vehicle_number,
                    'document_type': doc.get_document_type_display(),
                    'document_number': doc.document_number,
                    'expiry_date': doc.expiry_date,
                    'days_since_expiry': abs(doc.days_until_expiry),
                } for doc in expired_docs
            ],
            'total_expiring_count': VehicleDocument.objects.filter(
                status='active',
                expiry_date__lte=thirty_days_from_now,
                expiry_date__gte=today
            ).count(),
            'total_expired_count': VehicleDocument.objects.filter(status='expired').count(),
        }
        
        if user.is_admin:
            # Admin dashboard data
            data.update({
                'total_operations': CargoOperation.objects.count(),
                'running_equipment': Equipment.objects.filter(status='running').count(),
                'total_revenue': RevenueStream.objects.aggregate(
                    total=Sum('amount'))['total'] or 0,
                'recent_operations': CargoOperationSerializer(
                    CargoOperation.objects.all()[:5], many=True
                ).data,
                'total_vehicles': Vehicle.objects.filter(is_active=True).count(),
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
                ).data,
                'total_vehicles': Vehicle.objects.filter(is_active=True).count(),
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
                    created_at__date=today).count(),
                'total_vehicles': Vehicle.objects.filter(is_active=True).count(),
            })
        
        return Response(data)


# === MAINTENANCE SYSTEM VIEWSETS ===

class VendorViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing vendors
    """
    queryset = Vendor.objects.filter(is_active=True)
    serializer_class = VendorSerializer
    permission_classes = [CanManageVendors]
    pagination_class = None  # Disable pagination for master data
    
    def get_permissions(self):
        """
        Only managers and admins can create/update/delete vendors
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [CanManageVendors]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]




class POVendorViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing Purchase Order vendors
    """
    queryset = POVendor.objects.filter(is_active=True)
    serializer_class = POVendorSerializer
    permission_classes = [CanManageVendors]
    pagination_class = None  # Disable pagination for master data
    
    def get_permissions(self):
        """
        Only managers and admins can create/update/delete vendors
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [CanManageVendors]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]
    
    def perform_create(self, serializer):
        """Override to manually create audit log with request context"""
        instance = serializer.save()
        
        # Create audit log manually with request context
        changes = {
            'action': 'created',
            'fields': {
                'name': {'new': instance.name},
                'contact_person': {'new': instance.contact_person},
                'phone_number': {'new': instance.phone_number},
                'email': {'new': instance.email},
                'address': {'new': instance.address},
                'is_active': {'new': instance.is_active},
            }
        }
        create_audit_log(instance, 'created', changes, self.request)
    
    def perform_update(self, serializer):
        """Override to manually create audit log with request context"""
        # Get original values before update
        original_instance = self.get_object()
        original_data = {
            'name': original_instance.name,
            'contact_person': original_instance.contact_person,
            'phone_number': original_instance.phone_number,
            'email': original_instance.email,
            'address': original_instance.address,
            'is_active': original_instance.is_active,
        }
        
        # Save the updated instance
        instance = serializer.save()
        
        # Compare and create audit log
        changed_fields = {}
        for field in ['name', 'contact_person', 'phone_number', 'email', 'address', 'is_active']:
            old_value = original_data.get(field)
            new_value = getattr(instance, field)
            
            if old_value != new_value:
                changed_fields[field] = {
                    'old': old_value,
                    'new': new_value
                }
        
        if changed_fields:
            changes = {
                'action': 'updated',
                'fields': changed_fields
            }
            create_audit_log(instance, 'updated', changes, self.request)


class WOVendorViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing Work Order vendors
    """
    queryset = WOVendor.objects.filter(is_active=True)
    serializer_class = WOVendorSerializer
    permission_classes = [CanManageVendors]
    pagination_class = None  # Disable pagination for master data
    
    def get_permissions(self):
        """
        Only managers and admins can create/update/delete vendors
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [CanManageVendors]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]
    
    def perform_create(self, serializer):
        """Override to manually create audit log with request context"""
        instance = serializer.save()
        
        # Create audit log manually with request context
        changes = {
            'action': 'created',
            'fields': {
                'name': {'new': instance.name},
                'contact_person': {'new': instance.contact_person},
                'phone_number': {'new': instance.phone_number},
                'email': {'new': instance.email},
                'address': {'new': instance.address},
                'is_active': {'new': instance.is_active},
            }
        }
        create_audit_log(instance, 'created', changes, self.request)
    
    def perform_update(self, serializer):
        """Override to manually create audit log with request context"""
        # Get original values before update
        original_instance = self.get_object()
        original_data = {
            'name': original_instance.name,
            'contact_person': original_instance.contact_person,
            'phone_number': original_instance.phone_number,
            'email': original_instance.email,
            'address': original_instance.address,
            'is_active': original_instance.is_active,
        }
        
        # Save the updated instance
        instance = serializer.save()
        
        # Compare and create audit log
        changed_fields = {}
        for field in ['name', 'contact_person', 'phone_number', 'email', 'address', 'is_active']:
            old_value = original_data.get(field)
            new_value = getattr(instance, field)
            
            if old_value != new_value:
                changed_fields[field] = {
                    'old': old_value,
                    'new': new_value
                }
        
        if changed_fields:
            changes = {
                'action': 'updated',
                'fields': changed_fields
            }
            create_audit_log(instance, 'updated', changes, self.request)


class WorkOrderViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing work orders
    """
    queryset = WorkOrder.objects.all()
    serializer_class = WorkOrderSerializer
    
    def get_permissions(self):
        """
        Create: Admin, Manager, Supervisor
        Full management: Admin, Manager only
        """
        if self.action in ['create']:
            permission_classes = [CanCreateWorkOrders]
        elif self.action in ['update', 'partial_update', 'destroy', 'link_po', 'unlink_po']:
            permission_classes = [CanManageWorkOrders]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]
    
    def perform_update(self, serializer):
        instance = serializer.save()
        try:
            AuditTrail.objects.create(
                entity_type='work_order', entity_id=instance.id,
                related_entity_type='-', related_entity_id=0,
                action='update', performed_by=self.request.user, source='API'
            )
        except Exception:
            pass
        return instance
    
    @action(detail=True, methods=['patch'], permission_classes=[CanEnterBillNumbers])
    def update_bill_number(self, request, pk=None):
        """
        Special endpoint for updating bill number by office staff
        """
        work_order = self.get_object()
        bill_no = request.data.get('bill_no')
        
        if not bill_no:
            return Response({'error': 'Bill number is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check for duplicate bill numbers
        if WorkOrder.objects.filter(bill_no=bill_no).exclude(pk=work_order.pk).exists():
            return Response({'error': 'Bill number already exists'}, status=status.HTTP_400_BAD_REQUEST)
        
        work_order.bill_no = bill_no
        work_order.save()
        
        return Response({'message': 'Bill number updated successfully'})
    
    @action(detail=True, methods=['patch'], permission_classes=[CanManageWorkOrders])
    def close_work_order(self, request, pk=None):
        """
        Close a work order
        """
        work_order = self.get_object()
        work_order.status = 'closed'
        work_order.save()
        # Auto-close all linked POs
        linked_pos = PurchaseOrder.objects.filter(wo_links__work_order=work_order, status='open').distinct()
        updated = 0
        for po in linked_pos:
            po.status = 'closed'
            po.save(update_fields=['status'])
            AuditTrail.objects.create(
                entity_type='purchase_order', entity_id=po.id,
                related_entity_type='work_order', related_entity_id=work_order.id,
                action='update', performed_by=request.user, source='auto-close:wo-closed'
            )
            updated += 1
        AuditTrail.objects.create(
            entity_type='work_order', entity_id=work_order.id,
            related_entity_type='-', related_entity_id=0,
            action='update', performed_by=request.user, source=f'closed; auto-closed-pos={updated}'
        )
        
        return Response({'message': 'Work order closed successfully', 'pos_closed': updated})

    @action(detail=True, methods=['post'])
    def link_po(self, request, pk=None):
        work_order = self.get_object()
        po_id = request.data.get('purchase_order') or request.data.get('po_id') or request.data.get('po')
        if not po_id:
            return Response({'error': 'purchase_order is required'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            purchase_order = PurchaseOrder.objects.get(pk=po_id)
        except PurchaseOrder.DoesNotExist:
            return Response({'error': 'Purchase order not found'}, status=status.HTTP_404_NOT_FOUND)
        if work_order.status == 'closed':
            return Response({'error': 'Cannot link a closed work order'}, status=status.HTTP_400_BAD_REQUEST)
        if purchase_order.status == 'closed':
            return Response({'error': 'Cannot link a closed purchase order'}, status=status.HTTP_400_BAD_REQUEST)
        # Ensure the PO is not already linked to another WO
        if WorkOrderPurchaseLink.objects.filter(purchase_order=purchase_order).exists():
            return Response({'error': 'This PO is already linked to a work order'}, status=status.HTTP_400_BAD_REQUEST)
        link, created = WorkOrderPurchaseLink.objects.get_or_create(
            work_order=work_order,
            purchase_order=purchase_order,
            defaults={'created_by': request.user}
        )
        # Audit
        AuditTrail.objects.create(
            entity_type='work_order', entity_id=work_order.id,
            related_entity_type='purchase_order', related_entity_id=purchase_order.id,
            action='link', performed_by=request.user, source=request.data.get('source') or 'API'
        )
        serializer = WorkOrderPurchaseLinkSerializer(link)
        return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def unlink_po(self, request, pk=None):
        work_order = self.get_object()
        po_id = request.data.get('purchase_order')
        if not po_id:
            return Response({'error': 'purchase_order is required'}, status=status.HTTP_400_BAD_REQUEST)
        deleted = WorkOrderPurchaseLink.objects.filter(work_order=work_order, purchase_order_id=po_id)
        if deleted.exists():
            AuditTrail.objects.create(
                entity_type='work_order', entity_id=work_order.id,
                related_entity_type='purchase_order', related_entity_id=int(po_id),
                action='unlink', performed_by=request.user, source=request.data.get('source') or 'API'
            )
        deleted.delete()
        return Response({'message': 'Unlinked successfully'})

    @action(detail=True, methods=['get'])
    def audits(self, request, pk=None):
        work_order = self.get_object()
        audits = AuditTrail.objects.filter(entity_type='work_order', entity_id=work_order.id)[:50]
        return Response(AuditTrailSerializer(audits, many=True).data)


class PurchaseOrderViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing purchase orders
    """
    queryset = PurchaseOrder.objects.all()
    serializer_class = PurchaseOrderSerializer
    
    def get_permissions(self):
        """
        Create: Admin, Manager, Supervisor
        Full management: Admin, Manager only
        """
        if self.action in ['create']:
            permission_classes = [CanCreatePurchaseOrders]
        elif self.action in ['update', 'partial_update', 'destroy', 'link_wo', 'unlink_wo']:
            permission_classes = [CanManagePurchaseOrders]
        else:
            permission_classes = [IsSupervisorOrAbove]
        return [permission() for permission in permission_classes]
    
    def perform_update(self, serializer):
        instance = serializer.save()
        try:
            AuditTrail.objects.create(
                entity_type='purchase_order', entity_id=instance.id,
                related_entity_type='-', related_entity_id=0,
                action='update', performed_by=self.request.user, source='API'
            )
        except Exception:
            pass
        return instance
    
    @action(detail=False, methods=['get'])
    def duplicate_check(self, request):
        """
        Check for duplicate PO before creation
        """
        vendor_id = request.GET.get('vendor_id')
        vehicle_id = request.query_params.get('vehicle_id')
        vehicle_other = request.query_params.get('vehicle_other')
        for_stock = request.query_params.get('for_stock') == 'true'
        
        if not vendor_id:
            return Response({'warning': None})
        
        # Check for POs created in last 24 hours
        last_24_hours = timezone.now() - timedelta(hours=24)
        query_conditions = Q(vendor_id=vendor_id, created_at__gte=last_24_hours)
        
        if vehicle_id:
            query_conditions &= Q(vehicle_id=vehicle_id)
        elif vehicle_other:
            query_conditions &= Q(vehicle_other=vehicle_other)
        elif for_stock:
            query_conditions &= Q(for_stock=True)
        
        existing_pos = PurchaseOrder.objects.filter(query_conditions)
        
        if existing_pos.exists():
            return Response({
                'warning': 'PO already exists for this vehicle/vendor today. Continue?',
                'existing_pos': [po.po_id for po in existing_pos[:3]]
            })
        
        return Response({'warning': None})
    
    @action(detail=True, methods=['patch'], permission_classes=[CanEnterBillNumbers])
    def update_bill_number(self, request, pk=None):
        """
        Special endpoint for updating bill number by office staff
        """
        purchase_order = self.get_object()
        bill_no = request.data.get('bill_no')
        
        if not bill_no:
            return Response({'error': 'Bill number is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check for duplicate bill numbers
        if PurchaseOrder.objects.filter(bill_no=bill_no).exclude(pk=purchase_order.pk).exists():
            return Response({'error': 'Bill number already exists'}, status=status.HTTP_400_BAD_REQUEST)
        
        purchase_order.bill_no = bill_no
        purchase_order.save()
        
        return Response({'message': 'Bill number updated successfully'})
    
    @action(detail=True, methods=['patch'], permission_classes=[CanManagePurchaseOrders])
    def close_purchase_order(self, request, pk=None):
        """
        Close a purchase order
        """
        purchase_order = self.get_object()
        purchase_order.status = 'closed'
        purchase_order.save()
        
        return Response({'message': 'Purchase order closed successfully'})

    @action(detail=True, methods=['post'])
    def link_wo(self, request, pk=None):
        purchase_order = self.get_object()
        wo_id = request.data.get('work_order') or request.data.get('wo_id') or request.data.get('wo')
        if not wo_id:
            return Response({'error': 'work_order is required'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            work_order = WorkOrder.objects.get(pk=wo_id)
        except WorkOrder.DoesNotExist:
            return Response({'error': 'Work order not found'}, status=status.HTTP_404_NOT_FOUND)
        if work_order.status == 'closed':
            return Response({'error': 'Cannot link a closed work order'}, status=status.HTTP_400_BAD_REQUEST)
        if purchase_order.status == 'closed':
            return Response({'error': 'Cannot link a closed purchase order'}, status=status.HTTP_400_BAD_REQUEST)
        # Ensure the PO is not already linked to another WO
        if WorkOrderPurchaseLink.objects.filter(purchase_order=purchase_order).exists():
            return Response({'error': 'This PO is already linked to a work order'}, status=status.HTTP_400_BAD_REQUEST)
        link, created = WorkOrderPurchaseLink.objects.get_or_create(
            work_order=work_order,
            purchase_order=purchase_order,
            defaults={'created_by': request.user}
        )
        # Audit
        AuditTrail.objects.create(
            entity_type='purchase_order', entity_id=purchase_order.id,
            related_entity_type='work_order', related_entity_id=work_order.id,
            action='link', performed_by=request.user, source=request.data.get('source') or 'API'
        )
        serializer = WorkOrderPurchaseLinkSerializer(link)
        return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def unlink_wo(self, request, pk=None):
        purchase_order = self.get_object()
        wo_id = request.data.get('work_order')
        if not wo_id:
            return Response({'error': 'work_order is required'}, status=status.HTTP_400_BAD_REQUEST)
        deleted = WorkOrderPurchaseLink.objects.filter(work_order_id=wo_id, purchase_order=purchase_order)
        if deleted.exists():
            AuditTrail.objects.create(
                entity_type='purchase_order', entity_id=purchase_order.id,
                related_entity_type='work_order', related_entity_id=int(wo_id),
                action='unlink', performed_by=request.user, source=request.data.get('source') or 'API'
            )
        deleted.delete()
        return Response({'message': 'Unlinked successfully'})

    @action(detail=True, methods=['get'])
    def audits(self, request, pk=None):
        purchase_order = self.get_object()
        audits = AuditTrail.objects.filter(entity_type='purchase_order', entity_id=purchase_order.id)[:50]
        return Response(AuditTrailSerializer(audits, many=True).data)


class POItemViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing PO items (itemization)
    """
    queryset = POItem.objects.all()
    serializer_class = POItemSerializer
    permission_classes = [CanItemizePurchaseOrders]
    
    def get_queryset(self):
        """
        Filter items by purchase order if specified
        """
        queryset = super().get_queryset()
        po_id = self.request.query_params.get('purchase_order', None)
        if po_id:
            queryset = queryset.filter(purchase_order_id=po_id)
        return queryset
    
    def perform_create(self, serializer):
        """
        Set the created_by field when creating POItem
        """
        serializer.save(created_by=self.request.user)


class StockViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing stock
    """
    queryset = Stock.objects.all()
    serializer_class = StockSerializer
    
    def get_permissions(self):
        """
        View: Admin, Manager, Supervisor
        Manage: Admin, Manager only
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [CanManageStock]
        else:
            permission_classes = [CanViewStock]
        return [permission() for permission in permission_classes]
    
    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """
        Get items with low stock (less than 5 units)
        """
        low_stock_items = Stock.objects.filter(quantity_in_hand__lt=5)
        serializer = self.get_serializer(low_stock_items, many=True)
        return Response(serializer.data)


class IssueSlipViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing issue slips
    """
    queryset = IssueSlip.objects.all()
    serializer_class = IssueSlipSerializer
    permission_classes = [CanCreateIssueSlips]
    
    def get_queryset(self):
        """
        Filter by vehicle or stock item if specified
        """
        queryset = super().get_queryset()
        vehicle_id = self.request.query_params.get('vehicle', None)
        stock_item_id = self.request.query_params.get('stock_item', None)
        
        if vehicle_id:
            queryset = queryset.filter(assigned_vehicle_id=vehicle_id)
        if stock_item_id:
            queryset = queryset.filter(stock_item_id=stock_item_id)
            
        return queryset
    
    @action(detail=False, methods=['get'])
    def by_vehicle(self, request):
        """
        Get issue slips grouped by vehicle
        """
        vehicle_id = request.query_params.get('vehicle_id')
        if not vehicle_id:
            return Response({'error': 'vehicle_id parameter required'}, status=status.HTTP_400_BAD_REQUEST)
        
        issue_slips = IssueSlip.objects.filter(assigned_vehicle_id=vehicle_id)
        serializer = self.get_serializer(issue_slips, many=True)
        return Response(serializer.data)

class VendorAuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = VendorAuditLog.objects.all()
    """
    ViewSet for retrieving vendor audit logs
    """
    serializer_class = VendorAuditLogSerializer
    permission_classes = [IsManagerOrAdmin]  # Only managers and admins can view audit logs
    
    def get_queryset(self):
        vendor_type = self.request.GET.get('vendor_type')
        vendor_id = self.request.GET.get('vendor_id')
        
        queryset = VendorAuditLog.objects.all()
        
        if vendor_type:
            queryset = queryset.filter(vendor_type=vendor_type)
        
        if vendor_id:
            queryset = queryset.filter(vendor_id=vendor_id)
        
        return queryset.order_by('-created_at')
    
    @action(detail=False, methods=['get'])
    def by_vendor(self, request):
        """
        Get audit logs for a specific vendor
        """
        vendor_type = request.GET.get('vendor_type')
        vendor_id = request.GET.get('vendor_id')
        
        if not vendor_type or not vendor_id:
            return Response(
                {'error': 'vendor_type and vendor_id are required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            vendor_id = int(vendor_id)
        except ValueError:
            return Response(
                {'error': 'vendor_id must be a valid integer'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        audit_logs = VendorAuditLog.objects.filter(
            vendor_type=vendor_type,
            vendor_id=vendor_id
        ).order_by('-created_at')
        
        from .serializers import VendorAuditLogSerializer
        serializer = VendorAuditLogSerializer(audit_logs, many=True)
        return Response(serializer.data)

# List Management Views
class ListTypeMasterViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing list types
    """
    queryset = ListTypeMaster.objects.all()
    serializer_class = ListTypeMasterSerializer
    permission_classes = [IsManagerOrAdmin]
    
    @action(detail=True, methods=['get'])
    def items(self, request, pk=None):
        """Get all items for a specific list type"""
        list_type = self.get_object()
        items = ListItemMaster.objects.filter(
            list_type=list_type, 
            is_active=True
        ).order_by('sort_order', 'name')
        
        serializer = ListItemMasterSimpleSerializer(items, many=True)
        return Response(serializer.data)

class ListItemMasterViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing list items
    """
    queryset = ListItemMaster.objects.all()
    serializer_class = ListItemMasterSerializer
    permission_classes = [IsManagerOrAdmin]
    
    def get_queryset(self):
        queryset = ListItemMaster.objects.all()
        list_type_code = self.request.query_params.get('list_type', None)
        if list_type_code:
            queryset = queryset.filter(list_type__code=list_type_code)
        return queryset.order_by('sort_order', 'name')
    
    def perform_create(self, serializer):
        """Override to manually create audit log with request context"""
        instance = serializer.save()
        
        # Create audit log manually with request context
        changes = {
            'action': 'created',
            'fields': {
                'name': {'new': instance.name},
                'code': {'new': instance.code},
                'description': {'new': instance.description},
                'sort_order': {'new': instance.sort_order},
                'is_active': {'new': instance.is_active},
            }
        }
        create_list_item_audit_log(instance, 'created', changes, self.request)
    
    def perform_update(self, serializer):
        """Override to manually create audit log with request context"""
        # Get original values before update
        original_instance = self.get_object()
        original_data = {
            'name': original_instance.name,
            'code': original_instance.code,
            'description': original_instance.description,
            'sort_order': original_instance.sort_order,
            'is_active': original_instance.is_active,
        }
        
        # Save the updated instance
        instance = serializer.save()
        
        # Compare and create audit log
        changed_fields = {}
        for field in ['name', 'code', 'description', 'sort_order', 'is_active']:
            old_value = original_data.get(field)
            new_value = getattr(instance, field)
            
            if old_value != new_value:
                changed_fields[field] = {
                    'old': old_value,
                    'new': new_value
                }
        
        if changed_fields:
            changes = {
                'action': 'updated',
                'fields': changed_fields
            }
            create_list_item_audit_log(instance, 'updated', changes, self.request)

class ListDataAPIView(generics.GenericAPIView):
    """
    API to get list data by list type code for dropdowns
    """
    permission_classes = [IsSupervisorOrAbove]
    
    def get(self, request, list_type_code):
        """Get active items for a specific list type"""
        try:
            list_type = ListTypeMaster.objects.get(code=list_type_code, is_active=True)
            items = ListItemMaster.objects.filter(
                list_type=list_type,
                is_active=True
            ).order_by('sort_order', 'name')
            
            serializer = ListItemMasterSimpleSerializer(items, many=True)
            return Response({
                'list_type': list_type.name,
                'items': serializer.data
            })
        except ListTypeMaster.DoesNotExist:
            return Response(
                {'error': 'List type not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )

class AllListsAPIView(generics.GenericAPIView):
    """
    API to get all list types and their items for the lists management screen
    """
    permission_classes = [IsManagerOrAdmin]
    
    def get(self, request):
        """Get all list types with their items"""
        list_types = ListTypeMaster.objects.filter(is_active=True).order_by('name')
        
        result = []
        for list_type in list_types:
            items = ListItemMaster.objects.filter(
                list_type=list_type,
                is_active=True
            ).order_by('sort_order', 'name')
            
            result.append({
                'id': list_type.id,
                'name': list_type.name,
                'code': list_type.code,
                'description': list_type.description,
                'items_count': items.count(),
                'items': ListItemMasterSimpleSerializer(items, many=True).data
            })
        
        return Response(result)

class ListItemAuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for retrieving list item audit logs
    """
    queryset = ListItemAuditLog.objects.all()
    serializer_class = ListItemAuditLogSerializer
    permission_classes = [IsManagerOrAdmin]  # Only managers and admins can view audit logs
    
    def get_queryset(self):
        list_type_code = self.request.GET.get('list_type_code')
        item_id = self.request.GET.get('item_id')
        
        queryset = ListItemAuditLog.objects.all()
        
        if list_type_code:
            queryset = queryset.filter(list_type_code=list_type_code)
        
        if item_id:
            queryset = queryset.filter(item_id=item_id)
        
        return queryset.order_by('-created_at')
    
    @action(detail=False, methods=['get'])
    def by_item(self, request):
        """
        Get audit logs for a specific list item
        """
        list_type_code = request.GET.get('list_type_code')
        item_id = request.GET.get('item_id')
        
        if not list_type_code or not item_id:
            return Response(
                {'error': 'list_type_code and item_id are required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            item_id = int(item_id)
        except ValueError:
            return Response(
                {'error': 'item_id must be a valid integer'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        audit_logs = ListItemAuditLog.objects.filter(
            list_type_code=list_type_code,
            item_id=item_id
        ).order_by('-created_at')
        
        serializer = ListItemAuditLogSerializer(audit_logs, many=True)
        return Response(serializer.data)
