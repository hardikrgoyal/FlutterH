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