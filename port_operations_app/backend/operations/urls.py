from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'cargo-operations', views.CargoOperationViewSet)
router.register(r'vehicle-types', views.VehicleTypeViewSet)
router.register(r'work-types', views.WorkTypeViewSet)
router.register(r'party-master', views.PartyMasterViewSet)
router.register(r'rate-master', views.RateMasterViewSet)
router.register(r'equipment', views.EquipmentViewSet)
router.register(r'transport-details', views.TransportDetailViewSet)
router.register(r'labour-costs', views.LabourCostViewSet)
router.register(r'miscellaneous-costs', views.MiscellaneousCostViewSet)
router.register(r'revenue-streams', views.RevenueStreamViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard/', views.DashboardView.as_view(), name='dashboard'),
] 