from django.shortcuts import render
from rest_framework import viewsets, generics, status
from rest_framework.response import Response
from rest_framework.decorators import action
from django.db.models import Sum
from django.utils import timezone

from .models import Wallet, PortExpense, DigitalVoucher, WalletTopUp, TallyLog
from .serializers import (
    WalletSerializer, PortExpenseSerializer, DigitalVoucherSerializer,
    WalletTopUpSerializer, TallyLogSerializer
)
from authentication.permissions import (
    IsSupervisorOrAbove, CanApproveFinancial, CanManageWallets,
    IsManagerOrAdmin, IsAccountantOrAdmin
)

class PortExpenseViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing port expenses
    """
    queryset = PortExpense.objects.all()
    serializer_class = PortExpenseSerializer
    permission_classes = [IsSupervisorOrAbove]
    
    def get_queryset(self):
        queryset = PortExpense.objects.all()
        user = self.request.user
        status_filter = self.request.query_params.get('status', None)
        
        # Supervisors can only see their own expenses
        if user.is_supervisor:
            queryset = queryset.filter(user=user)
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
            
        return queryset

class DigitalVoucherViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing digital vouchers
    """
    queryset = DigitalVoucher.objects.all()
    serializer_class = DigitalVoucherSerializer
    permission_classes = [IsSupervisorOrAbove]
    
    def get_queryset(self):
        queryset = DigitalVoucher.objects.all()
        user = self.request.user
        status_filter = self.request.query_params.get('status', None)
        
        # Supervisors can only see their own vouchers
        if user.is_supervisor:
            queryset = queryset.filter(user=user)
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
            
        return queryset

class WalletTopUpViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing wallet top-ups
    """
    queryset = WalletTopUp.objects.all()
    serializer_class = WalletTopUpSerializer
    permission_classes = [CanManageWallets]

class TallyLogViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing Tally logs
    """
    queryset = TallyLog.objects.all()
    serializer_class = TallyLogSerializer
    permission_classes = [IsAccountantOrAdmin]
    
    def get_queryset(self):
        queryset = TallyLog.objects.all()
        entry_type = self.request.query_params.get('entry_type', None)
        
        if entry_type:
            queryset = queryset.filter(entry_type=entry_type)
            
        return queryset

class WalletBalanceView(generics.GenericAPIView):
    """
    View to get current wallet balance for authenticated user
    """
    permission_classes = [IsSupervisorOrAbove]
    
    def get(self, request):
        user = request.user
        balance = Wallet.get_balance(user)
        
        return Response({
            'user_id': user.id,
            'username': user.username,
            'balance': balance,
            'last_updated': timezone.now()
        })

class WalletTransactionsView(generics.ListAPIView):
    """
    View to get wallet transactions for authenticated user
    """
    serializer_class = WalletSerializer
    permission_classes = [IsSupervisorOrAbove]
    
    def get_queryset(self):
        user = self.request.user
        
        # Supervisors can only see their own transactions
        if user.is_supervisor:
            return Wallet.objects.filter(user=user)
        
        # Managers and above can see all transactions
        return Wallet.objects.all()

class ApproveExpenseView(generics.UpdateAPIView):
    """
    View to approve/reject port expenses
    """
    queryset = PortExpense.objects.all()
    serializer_class = PortExpenseSerializer
    permission_classes = [IsManagerOrAdmin]
    
    def patch(self, request, *args, **kwargs):
        expense = self.get_object()
        user = request.user
        action = request.data.get('action')  # 'approve' or 'reject'
        comments = request.data.get('comments', '')
        
        if action not in ['approve', 'reject', 'finalize']:
            return Response(
                {'error': 'Action must be approve, reject, or finalize'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if action == 'approve' and user.is_manager:
            expense.status = 'approved'
            expense.reviewed_by = user
            expense.review_comments = comments
            
        elif action == 'finalize' and user.is_accountant:
            if expense.status != 'approved':
                return Response(
                    {'error': 'Expense must be approved before finalizing'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            expense.status = 'finalized'
            expense.approved_by = user
            
        elif action == 'reject':
            expense.status = 'rejected'
            expense.reviewed_by = user
            expense.review_comments = comments
            
        else:
            return Response(
                {'error': 'Insufficient permissions for this action'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        expense.save()
        serializer = self.get_serializer(expense)
        return Response(serializer.data)

class ApproveVoucherView(generics.UpdateAPIView):
    """
    View to approve/decline digital vouchers
    """
    queryset = DigitalVoucher.objects.all()
    serializer_class = DigitalVoucherSerializer
    permission_classes = [IsManagerOrAdmin]
    
    def patch(self, request, *args, **kwargs):
        voucher = self.get_object()
        user = request.user
        action = request.data.get('action')  # 'approve', 'decline', or 'log'
        comments = request.data.get('comments', '')
        tally_reference = request.data.get('tally_reference', '')
        
        if action not in ['approve', 'decline', 'log']:
            return Response(
                {'error': 'Action must be approve, decline, or log'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if action == 'approve' and (user.is_manager or user.is_admin):
            voucher.status = 'approved'
            voucher.approved_by = user
            voucher.approval_comments = comments
            
        elif action == 'log' and user.is_accountant:
            if voucher.status != 'approved':
                return Response(
                    {'error': 'Voucher must be approved before logging'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            voucher.status = 'logged'
            voucher.logged_by = user
            voucher.tally_reference = tally_reference
            
            # Create Tally log entry
            TallyLog.objects.create(
                entry_type='voucher',
                reference_id=str(voucher.id),
                tally_voucher_number=tally_reference,
                amount=voucher.amount,
                description=f"Digital voucher - {voucher.expense_category}",
                logged_by=user
            )
            
        elif action == 'decline':
            voucher.status = 'declined'
            voucher.approved_by = user
            voucher.approval_comments = comments
            
        else:
            return Response(
                {'error': 'Insufficient permissions for this action'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        voucher.save()
        serializer = self.get_serializer(voucher)
        return Response(serializer.data)
