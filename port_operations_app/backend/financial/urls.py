from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'port-expenses', views.PortExpenseViewSet)
router.register(r'digital-vouchers', views.DigitalVoucherViewSet)
router.register(r'wallet-topups', views.WalletTopUpViewSet)
router.register(r'tally-logs', views.TallyLogViewSet)

urlpatterns = [
    # Custom endpoints must come before router to avoid conflicts
    path('wallet/balance/', views.WalletBalanceView.as_view(), name='wallet-balance'),
    path('wallet/transactions/', views.WalletTransactionsView.as_view(), name='wallet-transactions'),
    path('wallet/holders/', views.WalletHoldersView.as_view(), name='wallet-holders'),
    path('port-expenses/all/', views.AllPortExpensesView.as_view(), name='all-port-expenses'),
    path('digital-vouchers/all/', views.AllDigitalVouchersView.as_view(), name='all-digital-vouchers'),
    path('port-expenses/<int:pk>/approve/', views.ApproveExpenseView.as_view(), name='approve-expense'),
    path('digital-vouchers/<int:pk>/approve/', views.ApproveVoucherView.as_view(), name='approve-voucher'),
    path('approvals/workflow/', views.ApprovalWorkflowView.as_view(), name='approval-workflow'),
    path('approvals/bulk/', views.BulkApprovalView.as_view(), name='bulk-approval'),
    path('reports/port-expenses/excel/', views.PortExpenseExcelExportView.as_view(), name='port-expenses-excel'),
    path('reports/digital-vouchers/excel/', views.DigitalVoucherExcelExportView.as_view(), name='digital-vouchers-excel'),
    # Router patterns come last
    path('', include(router.urls)),
] 