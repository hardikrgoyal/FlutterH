from rest_framework import permissions

class BaseRolePermission(permissions.BasePermission):
    """
    Base permission class for role-based access
    """
    allowed_roles = []
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        return request.user.role in self.allowed_roles

class IsAdminUser(BaseRolePermission):
    """
    Permission for Admin users only
    """
    allowed_roles = ['admin']

class IsManagerOrAdmin(BaseRolePermission):
    """
    Permission for Manager and Admin users
    """
    allowed_roles = ['manager', 'admin']

class IsSupervisorOrAbove(BaseRolePermission):
    """
    Permission for Supervisor, Manager, and Admin users
    """
    allowed_roles = ['supervisor', 'manager', 'admin']

class IsAccountantOrAdmin(BaseRolePermission):
    """
    Permission for Accountant and Admin users
    """
    allowed_roles = ['accountant', 'admin']

class CanCreateOperations(BaseRolePermission):
    """
    Permission for users who can create operations
    """
    allowed_roles = ['manager', 'admin']

class CanManageEquipment(BaseRolePermission):
    """
    Permission for users who can manage equipment
    """
    allowed_roles = ['supervisor', 'manager', 'admin']

class CanEnterExpenses(BaseRolePermission):
    """
    Permission for users who can enter expenses
    """
    allowed_roles = ['manager', 'admin']

class CanApproveFinancial(BaseRolePermission):
    """
    Permission for users who can approve financial records
    """
    allowed_roles = ['accountant', 'admin']

class CanManageWallets(BaseRolePermission):
    """
    Permission for users who can manage wallets
    """
    allowed_roles = ['accountant', 'admin']

class CanAccessLabourCosts(permissions.BasePermission):
    """
    Custom permission for labour costs:
    - Supervisors: Can create and view only
    - Managers/Admins: Full access (create, view, edit, delete)
    - Accountants: Can view and edit (for invoice tracking)
    """
    
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Allow access for supervisor, manager, admin, and accountant
        allowed_roles = ['supervisor', 'manager', 'admin', 'accountant']
        return request.user.role in allowed_roles
    
    def has_object_permission(self, request, view, obj):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Supervisors can only view (GET) - no edit/delete
        if request.user.role == 'supervisor':
            return request.method in ['GET']
        
        # Managers and Admins have full access
        if request.user.role in ['manager', 'admin']:
            return True
        
        # Accountants can view and edit (for invoice tracking)
        if request.user.role == 'accountant':
            return request.method in ['GET', 'PUT', 'PATCH']
        
        return False 