# 🔐 Demo Credentials for Port Operations App

## 🌐 Application URL
**https://app.globalseatrans.com**

## 👥 Demo User Accounts

### 🔴 Admin User
- **Username**: `admin`
- **Password**: `admin123`
- **Email**: admin@globalseatrans.com
- **Role**: Admin
- **Permissions**: Full system access, user management, all operations

### 🔵 Manager User  
- **Username**: `manager1`
- **Password**: `manager123`
- **Email**: manager1@globalseatrans.com
- **Role**: Manager
- **Permissions**: Create operations, manage operations, approve supervisor entries, configure rates

### 🟢 Supervisor User
- **Username**: `supervisor1`
- **Password**: `supervisor123`
- **Email**: supervisor1@globalseatrans.com
- **Role**: Supervisor  
- **Permissions**: Field data entry, view wallet, submit vouchers, equipment operations

### 🟤 Accountant User
- **Username**: `accountant1`
- **Password**: `accountant123`
- **Email**: accountant1@globalseatrans.com
- **Role**: Accountant
- **Permissions**: Approve financial records, wallet top-ups, revenue logging

## 🔑 Role-Based Permissions

### Admin Permissions
- ✅ Manage users
- ✅ Approve data  
- ✅ Configure rates
- ✅ Create & manage operations
- ✅ Enter expenses
- ✅ Field data entry
- ✅ View wallet
- ✅ Submit vouchers
- ✅ Approve financial records
- ✅ Top-up wallets
- ✅ Log tally
- ✅ Enter revenue

### Manager Permissions
- ✅ Create operations
- ✅ Manage operations
- ✅ Approve supervisor entries
- ✅ Enter expenses
- ✅ Configure rates
- ✅ Enter revenue

### Supervisor Permissions
- ✅ Field data entry
- ✅ View wallet
- ✅ Submit vouchers
- ✅ Start equipment
- ✅ End equipment

### Accountant Permissions
- ✅ Approve financial records
- ✅ Top-up wallets
- ✅ Log tally
- ✅ Enter revenue

## 🌐 Access Points

### Web Application
- **URL**: https://app.globalseatrans.com
- **Login**: Use any of the demo credentials above

### Django Admin Panel
- **URL**: https://app.globalseatrans.com/admin/
- **Login**: Use admin credentials for full access
- **Note**: Admin and staff users can access Django admin

### API Endpoints
- **Base URL**: https://app.globalseatrans.com/api/
- **Login Endpoint**: https://app.globalseatrans.com/api/auth/login/
- **Authentication**: JWT tokens (Bearer token in headers)

## 🧪 API Testing Examples

### Login via API
```bash
curl -X POST https://app.globalseatrans.com/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'
```

### Using JWT Token
```bash
# After login, use the access token from response
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  https://app.globalseatrans.com/api/auth/profile/
```

## ⚠️ Security Notes

1. **Change Passwords**: These are demo credentials for testing only
2. **Production Use**: Create new users with strong passwords for production
3. **Token Expiry**: JWT access tokens expire after 1 hour, refresh tokens after 30 days
4. **Role Security**: Each role has specific permissions - test accordingly

## 🔄 User Management

### Creating New Users
- Login as Admin → Users section → Add new user
- Or use Django admin panel at `/admin/`

### Modifying Permissions
- User permissions are role-based
- Change user role to modify their permissions
- Custom permissions can be added in the User model

## 📞 Support

If you encounter any login issues:
1. Verify the URL: https://app.globalseatrans.com
2. Check credentials are typed correctly (case-sensitive)
3. Try different user roles to test permissions
4. Check browser console for any errors

---

**Last Updated**: $(date)
**Status**: ✅ All credentials verified and working 