from django.shortcuts import render
from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .models import User
from .serializers import UserSerializer, LoginSerializer, UserProfileSerializer
from .permissions import IsAdminUser

class LoginView(generics.GenericAPIView):
    """
    User login view with JWT token generation
    """
    serializer_class = LoginSerializer
    permission_classes = [permissions.AllowAny]
    
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = serializer.validated_data['user']
        refresh = RefreshToken.for_user(user)
        
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'role': user.role,
                'phone_number': user.phone_number,
                'employee_id': user.employee_id
            }
        })

class UserListCreateView(generics.ListCreateAPIView):
    """
    List all users or create a new user (Admin only)
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdminUser]
    
    def get_queryset(self):
        queryset = User.objects.all()
        role = self.request.query_params.get('role', None)
        if role is not None:
            queryset = queryset.filter(role=role)
        return queryset

class UserDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update or delete a user instance (Admin only)
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdminUser]
    
    def delete(self, request, *args, **kwargs):
        # Instead of deleting, deactivate the user
        user = self.get_object()
        user.is_active = False
        user.save()
        return Response({'message': 'User deactivated successfully'}, 
                       status=status.HTTP_200_OK)

class UserProfileView(generics.RetrieveUpdateAPIView):
    """
    View and update current user profile
    """
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def change_password(request):
    """
    Change password for authenticated user
    """
    user = request.user
    old_password = request.data.get('old_password')
    new_password = request.data.get('new_password')
    
    if not old_password or not new_password:
        return Response(
            {'error': 'Both old_password and new_password are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if not user.check_password(old_password):
        return Response(
            {'error': 'Invalid old password'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    user.set_password(new_password)
    user.save()
    
    return Response({'message': 'Password changed successfully'})

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_permissions(request):
    """
    Get current user's permissions based on role
    """
    user = request.user
    permissions = {
        'admin': [
            'manage_users', 'approve_data', 'configure_rates',
            'create_operations', 'manage_operations', 'enter_expenses',
            'field_data_entry', 'view_wallet', 'submit_vouchers',
            'approve_financial', 'topup_wallets', 'log_tally', 'enter_revenue',
            'manage_vehicle_documents', 'view_vehicle_documents'
        ],
        'manager': [
            'create_operations', 'manage_operations', 'approve_supervisor_entries',
            'enter_expenses', 'configure_rates', 'enter_revenue',
            'manage_vehicle_documents', 'view_vehicle_documents'
        ],
        'supervisor': [
            'field_data_entry', 'view_wallet', 'submit_vouchers',
            'start_equipment', 'end_equipment', 'view_vehicle_documents'
        ],
        'accountant': [
            'approve_financial', 'topup_wallets', 'log_tally', 'enter_revenue',
            'manage_vehicle_documents', 'view_vehicle_documents'
        ]
    }
    
    user_permissions = permissions.get(user.role, [])
    
    return Response({
        'user_id': user.id,
        'username': user.username,
        'role': user.role,
        'permissions': user_permissions
    })
