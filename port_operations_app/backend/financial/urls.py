from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'port-expenses', views.PortExpenseViewSet)
router.register(r'digital-vouchers', views.DigitalVoucherViewSet)
router.register(r'wallet-topups', views.WalletTopUpViewSet)
router.register(r'tally-logs', views.TallyLogViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('wallet/balance/', views.WalletBalanceView.as_view(), name='wallet-balance'),
    path('wallet/transactions/', views.WalletTransactionsView.as_view(), name='wallet-transactions'),
    path('expenses/approve/<int:pk>/', views.ApproveExpenseView.as_view(), name='approve-expense'),
    path('vouchers/approve/<int:pk>/', views.ApproveVoucherView.as_view(), name='approve-voucher'),
] 