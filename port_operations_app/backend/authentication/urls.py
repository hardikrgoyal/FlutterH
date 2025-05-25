from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    # Authentication
    path('login/', views.LoginView.as_view(), name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # User management (Admin only)
    path('users/', views.UserListCreateView.as_view(), name='user-list-create'),
    path('users/<int:pk>/', views.UserDetailView.as_view(), name='user-detail'),
    
    # User profile
    path('profile/', views.UserProfileView.as_view(), name='user-profile'),
    path('change-password/', views.change_password, name='change-password'),
    path('permissions/', views.user_permissions, name='user-permissions'),
] 