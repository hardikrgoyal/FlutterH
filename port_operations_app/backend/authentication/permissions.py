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

class HasWallet(BaseRolePermission):
    """
    Permission for users who have their own wallets (excludes accountants)
    """
    allowed_roles = ['admin', 'manager', 'supervisor', 'office']

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

class CanManageRevenue(BaseRolePermission):
    """
    Permission for users who can manage revenue streams
    Admin, Manager, and Accountant access
    """
    allowed_roles = ['admin', 'manager', 'accountant']

class CanManageVehicles(BaseRolePermission):
    """
    Permission for users who can manage vehicles and documents
    Admin, Manager, and Accountant access
    """
    allowed_roles = ['admin', 'manager', 'accountant']

class CanViewVehicles(BaseRolePermission):
    """
    Permission for users who can view vehicles
    All authenticated users can view vehicles and office
    """
    allowed_roles = ['supervisor', 'manager', 'admin', 'accountant', 'office']


# === MAINTENANCE SYSTEM PERMISSIONS ===

class CanCreateWorkOrders(BaseRolePermission):
    """
    Permission for creating work orders
    Admin, Manager, Supervisor and Office can create
    """
    allowed_roles = ['admin', 'manager', 'supervisor', 'office']


class CanManageWorkOrders(BaseRolePermission):
    """
    Permission for full work order management
    Admin, Manager and Office only
    """
    allowed_roles = ['admin', 'manager', 'office']


class CanCreatePurchaseOrders(BaseRolePermission):
    """
    Permission for creating purchase orders
    Admin, Manager, Supervisor and Office can create
    """
    allowed_roles = ['admin', 'manager', 'supervisor', 'office']


class CanManagePurchaseOrders(BaseRolePermission):
    """
    Permission for full purchase order management
    Admin, Manager and Office only
    """
    allowed_roles = ['admin', 'manager', 'office']


class CanManageVendors(BaseRolePermission):
    """
    Permission for managing vendors
    Admin and Manager only
    """
    allowed_roles = ['admin', 'manager']


class CanEnterBillNumbers(BaseRolePermission):
    """
    Permission for entering bill numbers
    Admin, Manager, Office can enter
    """
    allowed_roles = ['admin', 'manager', 'office']


class CanItemizePurchaseOrders(BaseRolePermission):
    """
    Permission for itemizing purchase orders
    Admin, Manager, Office can itemize
    """
    allowed_roles = ['admin', 'manager', 'office']


class CanManageStock(BaseRolePermission):
    """
    Permission for stock management
    Admin and Manager only
    """
    allowed_roles = ['admin', 'manager']


class CanViewStock(BaseRolePermission):
    """
    Permission for viewing stock
    Admin, Manager, Supervisor can view
    """
    allowed_roles = ['admin', 'manager', 'supervisor']


class CanCreateIssueSlips(BaseRolePermission):
    """
    Permission for creating issue slips
    Admin and Manager only
    """
    allowed_roles = ['admin', 'manager']


class CanItemizePurchaseOrders(BaseRolePermission):
    """
    Permission for itemizing purchase orders
    Admin, Manager, Office, and Office Boy can itemize
    """
    allowed_roles = ['admin', 'manager', 'office', 'office_boy'] 


class CanViewMaintenanceOrders(BaseRolePermission):
    """
    Permission for users who can view Work Orders and Purchase Orders
    Admin, Manager, Supervisor and Office can view
    """
    allowed_roles = ['admin', 'manager', 'supervisor', 'office'] 