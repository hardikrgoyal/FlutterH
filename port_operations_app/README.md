# Port Operations Management App

A comprehensive mobile-first solution for managing port operations, cargo handling, equipment tracking, and financial workflows. Built with Flutter frontend and Django REST API backend.

![Port Operations App](https://img.shields.io/badge/Status-MVP%20Complete-success)
![Flutter](https://img.shields.io/badge/Flutter-3.7.2-blue)
![Django](https://img.shields.io/badge/Django-4.2.21-green)
![Platform](https://img.shields.io/badge/Platform-Mobile%20First-orange)

## 🚀 Features Completed

### ✅ Backend (Django REST API) - **FULLY IMPLEMENTED**
- **Authentication System**: JWT-based authentication with role-based permissions
- **User Management**: Custom user model with 4 roles (Admin, Manager, Supervisor, Accountant)
- **Operations Module**: Cargo operations, equipment tracking, transport details, labor costs
- **Financial Module**: Digital wallet system, expense tracking, voucher management, Tally integration
- **Rate Master**: Configurable rate system for automatic cost calculations
- **Admin Interface**: Complete Django admin setup for all models
- **Demo Data**: Pre-populated database with sample data and test users

### ✅ Frontend (Flutter) - **FOUNDATION COMPLETE**
- **Authentication Flow**: Professional login screen with form validation
- **Role-based Dashboard**: Customized dashboard for each user role
- **Navigation System**: Drawer navigation with role-specific menu items
- **State Management**: Riverpod providers for authentication and app state
- **API Integration**: Dio HTTP client with automatic token refresh
- **Material Design**: Modern UI with comprehensive theming system
- **Responsive Design**: Mobile-first responsive layouts

## 🛠️ Tech Stack

### Backend
- **Django 4.2.21**: Web framework with REST API
- **Django REST Framework 3.16.0**: API development
- **Simple JWT 5.5.0**: Authentication
- **PostgreSQL/SQLite**: Database
- **Pillow**: Image handling
- **CORS Headers**: Cross-origin support

### Frontend
- **Flutter 3.7.2**: Mobile app framework
- **Riverpod 2.5.1**: State management
- **Dio 5.7.0**: HTTP client
- **GoRouter 14.6.1**: Navigation
- **Form Builder**: Form validation
- **Material Design**: UI components

## 📱 Screenshots & Demo

### Login Screen
- Professional design with role-based demo credentials
- Form validation and loading states
- Automatic navigation based on user role

### Dashboard Screens
- **Admin Dashboard**: System overview, user management, comprehensive stats
- **Manager Dashboard**: Operations management, approvals, equipment tracking
- **Supervisor Dashboard**: Wallet balance, equipment operations, expense submission
- **Accountant Dashboard**: Financial approvals, wallet management, Tally integration

### Navigation
- Role-based drawer navigation
- Quick action buttons for common tasks
- Seamless navigation between modules

## 🔧 Setup Instructions

### Prerequisites
- Python 3.9+
- Flutter 3.7.2+
- Git
- Virtual environment tools

### Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd port_operations_app/backend
   ```

2. **Create virtual environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run migrations**
   ```bash
   python manage.py migrate
   ```

5. **Create demo data**
   ```bash
   python create_demo_data.py
   ```

6. **Start server**
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd port_operations_app/frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Update API endpoint** (for physical device testing)
   - Edit `lib/core/constants/app_constants.dart`
   - Change `baseUrl` from `localhost` to your computer's IP address

5. **Run app**
   ```bash
   flutter run
   ```

## 👥 Demo Users

| Role | Username | Password | Permissions |
|------|----------|----------|-------------|
| **Admin** | `admin` | `admin123` | Full system access, user management |
| **Manager** | `manager1` | `manager123` | Operations, approvals, cost management |
| **Supervisor** | `supervisor1` | `supervisor123` | Field operations, equipment, expenses |
| **Accountant** | `accountant1` | `accountant123` | Financial approvals, wallet, Tally |

## 🔗 API Endpoints

### Authentication
- `POST /api/auth/login/` - User login
- `POST /api/auth/token/refresh/` - Refresh JWT token
- `GET /api/auth/profile/` - User profile
- `GET /api/auth/permissions/` - User permissions

### Operations
- `GET|POST /api/operations/cargo-operations/` - Cargo operations CRUD
- `GET|POST /api/operations/equipment/` - Equipment management
- `GET /api/operations/equipment/running/` - Running equipment
- `PATCH /api/operations/equipment/{id}/end/` - End equipment
- `GET /api/operations/dashboard/` - Dashboard data

### Financial
- `GET|POST /api/financial/port-expenses/` - Port expenses
- `GET|POST /api/financial/digital-vouchers/` - Digital vouchers
- `GET /api/financial/wallet/balance/` - Wallet balance
- `PATCH /api/financial/expenses/approve/{id}/` - Approve expenses

## 📊 Role-Based Features

### 👑 Admin
- User management and system settings
- Complete access to all operations
- System analytics and reporting
- Rate master configuration

### 👔 Manager
- Create and manage cargo operations
- Approve supervisor entries
- Equipment and transport management
- Cost tracking and rate configuration

### 👷 Supervisor
- Start/end equipment operations
- Field data entry and documentation
- Wallet management and expense submission
- Digital voucher submission with photos

### 💼 Accountant
- Financial record approvals
- Wallet top-up management
- Revenue stream tracking
- Tally system integration

## 🔄 Core Workflows

### Equipment Management
1. Supervisor starts equipment → Status: Running
2. System tracks time automatically
3. Supervisor ends equipment → Auto-calculate cost
4. Status updated to Completed

### Expense Approval
1. Supervisor submits expense → Status: Submitted
2. Manager reviews and approves → Status: Approved
3. Accountant finalizes → Status: Finalized
4. Auto-debit from supervisor's wallet

### Wallet System
- Automatic balance tracking
- Credit/debit transaction history
- Top-up management by accountants
- Integration with expense workflows

## 🗄️ Database Models

### Authentication
- Custom User model with roles
- JWT token management
- Permission-based access control

### Operations
- CargoOperation (central tracking)
- Equipment (with time/cost tracking)
- TransportDetail, LabourCost, MiscellaneousCost
- RateMaster (auto-calculation rates)
- RevenueStream (income tracking)

### Financial
- Wallet (transaction tracking)
- PortExpense (approval workflow)
- DigitalVoucher (photo uploads)
- WalletTopUp, TallyLog

## 🚀 Current Status

### ✅ Completed
- ✅ Complete Django backend with all models, APIs, and admin
- ✅ Flutter app foundation with authentication
- ✅ Role-based dashboard system
- ✅ Professional UI/UX design
- ✅ Navigation and state management
- ✅ Demo data and documentation

### 🚧 Next Steps (Future Enhancements)
- 📋 Operations screens (cargo management, equipment forms)
- 💰 Financial screens (expense forms, approval interfaces)
- 📊 Charts and analytics dashboards
- 📷 Camera integration for voucher photos
- 🔄 Real-time data refresh
- 📱 Push notifications
- 📈 Advanced reporting features

## 🧪 Testing

### Backend Testing
```bash
# Run Django server
python manage.py runserver

# Test API endpoints
curl http://localhost:8000/api/auth/login/ -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}'
```

### Frontend Testing
```bash
# Run Flutter app
flutter run

# Hot reload during development
r (in terminal)
```

### API Testing
- Django Admin: `http://localhost:8000/admin/`
- API Browser: `http://localhost:8000/api/`
- Use demo credentials for testing

## 📝 Development Notes

### Architecture
- **Backend**: Django REST API with JWT authentication
- **Frontend**: Flutter with Riverpod state management
- **Database**: SQLite (development), PostgreSQL (production)
- **Communication**: RESTful APIs with JSON

### Security
- JWT token-based authentication
- Role-based permission system
- Secure storage for tokens
- CORS configuration for mobile apps

### Performance
- Efficient state management with Riverpod
- Lazy loading and pagination
- Image optimization and caching
- Database query optimization

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is part of the Port Operations Management System.

## 🆘 Troubleshooting

### Connection Issues
- Ensure Django backend is running on `0.0.0.0:8000`
- For emulator testing, use `10.0.2.2:8000` instead of `localhost:8000`
- For physical device, use your computer's IP address

### Build Issues
- Run `flutter clean && flutter pub get`
- Regenerate code: `flutter packages pub run build_runner build --delete-conflicting-outputs`
- Check Flutter and Dart SDK versions

### Database Issues
- Delete `db.sqlite3` and run migrations again
- Recreate demo data with `python create_demo_data.py`

---

**Happy Coding! 🚢⚓** 

*Built with ❤️ for modern port operations management* 