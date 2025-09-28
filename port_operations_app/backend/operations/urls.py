from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'cargo-operations', views.CargoOperationViewSet)
router.register(r'vehicle-types', views.VehicleTypeViewSet)
router.register(r'vehicles', views.VehicleViewSet)
router.register(r'vehicle-documents', views.VehicleDocumentViewSet)
router.register(r'work-types', views.WorkTypeViewSet)
router.register(r'party-master', views.PartyMasterViewSet)
router.register(r'contractor-master', views.ContractorMasterViewSet)
router.register(r'service-type-master', views.ServiceTypeMasterViewSet)
router.register(r'unit-type-master', views.UnitTypeMasterViewSet)
router.register(r'rate-master', views.RateMasterViewSet)
router.register(r'equipment-rate-master', views.EquipmentRateMasterViewSet)
router.register(r'equipment', views.EquipmentViewSet)
router.register(r'transport-details', views.TransportDetailViewSet)
router.register(r'labour-costs', views.LabourCostViewSet)
router.register(r'miscellaneous-costs', views.MiscellaneousCostViewSet)
router.register(r'revenue-streams', views.RevenueStreamViewSet)

# Maintenance system routes
router.register(r'vendors', views.VendorViewSet)
router.register(r'po-vendors', views.POVendorViewSet)
router.register(r'wo-vendors', views.WOVendorViewSet)
router.register(r'work-orders', views.WorkOrderViewSet)
router.register(r'purchase-orders', views.PurchaseOrderViewSet)
router.register(r'po-items', views.POItemViewSet)
router.register(r'stock', views.StockViewSet)
router.register(r'issue-slips', views.IssueSlipViewSet)
router.register(r'vendor-audit-logs', views.VendorAuditLogViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard/', views.DashboardView.as_view(), name='dashboard'),
] 