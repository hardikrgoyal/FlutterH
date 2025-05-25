# Port Operations Management Backend

A comprehensive Django REST API backend for managing port operations, cargo handling, equipment tracking, and financial workflows.

## 🚀 Features

### Authentication & Authorization
- JWT-based authentication using `djangorestframework-simplejwt`
- Role-based access control (Admin, Manager, Supervisor, Accountant)
- Custom user model with role-specific permissions

### Operational Modules
- **Cargo Operations**: Central management of cargo details and operations
- **Equipment Management**: Track equipment usage with start/end times and cost calculation
- **Transport Details**: Manage transport logistics and costs
- **Labour Cost Tracking**: Track labour expenses by type and contractor
- **Miscellaneous Costs**: Handle various operational expenses
- **Revenue Streams**: Track revenue from different services
- **Rate Master**: Configure rates for auto-calculation

### Financial Modules
- **Wallet System**: Digital wallet for supervisors with credit/debit tracking
- **Port Expense Tracking**: Manage in/out port expenses with approval workflow
- **Digital Vouchers**: Expense voucher system with photo uploads
- **Wallet Top-ups**: Accountant-managed wallet credit system
- **Tally Integration**: Log entries to Tally accounting system

## 🛠️ Tech Stack

- **Django 4.2.21**: Web framework
- **Django REST Framework 3.16.0**: API framework
- **Simple JWT 5.5.0**: JWT authentication
- **PostgreSQL/SQLite**: Database (SQLite for development)
- **Pillow**: Image handling
- **CORS Headers**: Cross-origin resource sharing
- **Python Decouple**: Environment configuration

## 📋 Prerequisites

- Python 3.9+
- pip (Python package manager)
- Virtual environment (recommended)

## 🔧 Installation & Setup

1. **Clone and navigate to backend directory**
   ```bash
   cd port_operations_app/backend
   ```

2. **Create and activate virtual environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Environment Configuration**
   Create a `.env` file in the backend directory:
   ```env
   DEBUG=True
   SECRET_KEY=your-secret-key-here
   DATABASE_NAME=port_operations_db
   DATABASE_USER=port_user
   DATABASE_PASSWORD=port_password
   DATABASE_HOST=localhost
   DATABASE_PORT=5432
   ALLOWED_HOSTS=localhost,127.0.0.1
   ```

5. **Database Setup**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

6. **Create Demo Data**
   ```bash
   python create_demo_data.py
   ```

7. **Run Development Server**
   ```bash
   python manage.py runserver
   ```

The API will be available at `http://localhost:8000/`

## 👥 Demo Users

| Role | Username | Password | Permissions |
|------|----------|----------|-------------|
| Admin | admin | admin123 | Full access to all modules |
| Manager | manager1 | manager123 | Create operations, manage costs, approve entries |
| Supervisor | supervisor1 | supervisor123 | Field data entry, equipment management, wallet access |
| Accountant | accountant1 | accountant123 | Financial approvals, wallet top-ups, Tally logging |

## 🔗 API Endpoints

### Authentication
- `POST /api/auth/login/` - User login
- `POST /api/auth/token/refresh/` - Refresh JWT token
- `GET /api/auth/profile/` - Get user profile
- `POST /api/auth/change-password/` - Change password
- `GET /api/auth/permissions/` - Get user permissions

### Operations
- `GET|POST /api/operations/cargo-operations/` - Cargo operations CRUD
- `GET|POST /api/operations/rate-master/` - Rate master configuration
- `GET|POST /api/operations/equipment/` - Equipment management
- `GET /api/operations/equipment/running/` - Get running equipment
- `PATCH /api/operations/equipment/{id}/end/` - End equipment operation
- `GET|POST /api/operations/transport-details/` - Transport details
- `GET|POST /api/operations/labour-costs/` - Labour cost tracking
- `GET|POST /api/operations/miscellaneous-costs/` - Miscellaneous costs
- `GET|POST /api/operations/revenue-streams/` - Revenue tracking
- `GET /api/operations/dashboard/` - Role-specific dashboard data

### Financial
- `GET|POST /api/financial/port-expenses/` - Port expense management
- `GET|POST /api/financial/digital-vouchers/` - Digital voucher system
- `GET|POST /api/financial/wallet-topups/` - Wallet top-up management
- `GET|POST /api/financial/tally-logs/` - Tally integration logs
- `GET /api/financial/wallet/balance/` - Get wallet balance
- `GET /api/financial/wallet/transactions/` - Get wallet transactions
- `PATCH /api/financial/expenses/approve/{id}/` - Approve/reject expenses
- `PATCH /api/financial/vouchers/approve/{id}/` - Approve/decline vouchers

## 🔐 Permission System

### Role Hierarchy
1. **Admin**: Full system access
2. **Manager**: Operations and cost management
3. **Supervisor**: Field operations and equipment
4. **Accountant**: Financial operations and approvals

### Permission Matrix
| Module | Admin | Manager | Supervisor | Accountant |
|--------|-------|---------|------------|------------|
| User Management | ✅ | ❌ | ❌ | ❌ |
| Cargo Operations | ✅ | ✅ | ❌ | ❌ |
| Equipment Management | ✅ | ✅ | ✅ | ❌ |
| Transport/Labour | ✅ | ✅ | ❌ | ❌ |
| Revenue Streams | ✅ | ✅ | ❌ | ✅ |
| Port Expenses | ✅ | ✅ | ✅ | ❌ |
| Wallet Management | ✅ | ❌ | View Only | ✅ |
| Financial Approvals | ✅ | Partial | ❌ | ✅ |

## 📊 Data Models

### Core Models
- **User**: Custom user with role-based permissions
- **CargoOperation**: Central operation tracking
- **Equipment**: Equipment usage and cost tracking
- **RateMaster**: Rate configuration for auto-calculation

### Financial Models
- **Wallet**: Digital wallet transaction tracking
- **PortExpense**: Port expense management with approval workflow
- **DigitalVoucher**: Expense voucher system
- **TallyLog**: Integration with Tally accounting

## 🔄 Workflows

### Equipment Management
1. Supervisor starts equipment → Status: Running
2. Supervisor ends equipment → Auto-calculate cost → Status: Completed

### Expense Approval
1. Supervisor submits expense → Status: Submitted
2. Manager reviews/approves → Status: Approved
3. Accountant finalizes → Status: Finalized → Auto-debit wallet

### Voucher Processing
1. User submits voucher → Status: Submitted
2. Manager/Admin approves → Status: Approved
3. Accountant logs to Tally → Status: Logged

## 🧪 Testing

Run the development server and test endpoints using:
- Django Admin: `http://localhost:8000/admin/`
- API Browser: `http://localhost:8000/api/`
- Postman/curl for API testing

## 📁 Project Structure

```
backend/
├── authentication/          # User management and auth
├── operations/             # Operational modules
├── financial/              # Financial modules
├── port_operations_backend/ # Django project settings
├── media/                  # Uploaded files
├── staticfiles/           # Static files
├── requirements.txt       # Python dependencies
├── create_demo_data.py   # Demo data script
└── manage.py             # Django management script
```

## 🚀 Production Deployment

1. **Environment Variables**
   - Set `DEBUG=False`
   - Configure PostgreSQL database
   - Set secure `SECRET_KEY`
   - Configure `ALLOWED_HOSTS`

2. **Database Migration**
   ```bash
   python manage.py migrate
   python manage.py collectstatic
   ```

3. **Web Server**
   - Use Gunicorn/uWSGI for WSGI
   - Configure Nginx for static files
   - Set up SSL certificates

## 📝 API Documentation

The API follows REST conventions with:
- JSON request/response format
- JWT authentication in headers
- Standard HTTP status codes
- Pagination for list endpoints
- Filtering and search capabilities

## 🤝 Contributing

1. Follow Django coding standards
2. Add proper docstrings and comments
3. Write tests for new features
4. Update documentation for API changes

## 📄 License

This project is part of the Port Operations Management System. 