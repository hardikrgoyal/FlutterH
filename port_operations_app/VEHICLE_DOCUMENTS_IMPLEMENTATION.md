# Vehicle Document Manager Implementation

## Overview
A comprehensive vehicle document management system with renewal tracking, expiry alerts, and role-based access control.

## Features Implemented

### 🚗 Vehicle Master Data
- **Vehicle Model**: Central repository for all vehicle information
- **Fields**: Vehicle number, type, ownership, status, owner details, specifications
- **Auto-formatting**: Vehicle numbers automatically converted to uppercase
- **Document Counts**: Real-time counts of active, expired, and expiring documents

### 📄 Document Management
- **Document History**: Complete audit trail for all document versions
- **Document Types**: Insurance, PUC, RC, Fitness, Road Tax, Permit, FASTag, Commercial Permit, Goods Permit, Other
- **Auto Status Management**: Documents automatically marked as active/expired based on dates
- **Renewal Workflow**: New documents automatically expire old versions of the same type

### 🔔 Alert System
- **Expiring Soon**: Documents expiring within 30 days
- **Recently Expired**: Documents that expired in the last 7 days
- **Urgent Alerts**: Documents expiring within 7 days marked as urgent
- **Dashboard Integration**: Alerts displayed on all role dashboards

### 👥 Role-Based Access Control
- **Admin**: Full CRUD access to vehicles and documents
- **Manager**: Full CRUD access to vehicles and documents
- **Accountant**: Full CRUD access to vehicles and documents
- **Supervisor**: View-only access to vehicles and documents
- **Operator**: No access to vehicle documents

## Backend Implementation

### Models (`backend/operations/models.py`)
```python
class Vehicle(models.Model):
    vehicle_number = models.CharField(max_length=20, unique=True)
    vehicle_type = models.ForeignKey(VehicleType, on_delete=models.CASCADE)
    ownership = models.CharField(max_length=20, choices=OWNERSHIP_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES)
    # ... other fields ...
    
    @property
    def active_documents_count(self):
        return self.documents.filter(status='active').count()

class VehicleDocument(models.Model):
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='documents')
    document_type = models.CharField(max_length=50, choices=DOCUMENT_TYPE_CHOICES)
    document_number = models.CharField(max_length=100)
    expiry_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    renewal_reference = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True)
    # ... other fields ...
    
    def save(self, *args, **kwargs):
        # Auto-update status and handle renewals
        # ... implementation ...
```

### API Endpoints (`backend/operations/views.py`)
- **Vehicles**: `/api/operations/vehicles/`
  - `GET /api/operations/vehicles/` - List vehicles
  - `POST /api/operations/vehicles/` - Create vehicle
  - `GET /api/operations/vehicles/{id}/` - Get vehicle details
  - `PUT /api/operations/vehicles/{id}/` - Update vehicle
  - `DELETE /api/operations/vehicles/{id}/` - Delete vehicle
  - `GET /api/operations/vehicles/{id}/documents/` - Get vehicle documents grouped by type

- **Vehicle Documents**: `/api/operations/vehicle-documents/`
  - `GET /api/operations/vehicle-documents/` - List documents
  - `POST /api/operations/vehicle-documents/` - Create document
  - `GET /api/operations/vehicle-documents/{id}/` - Get document details
  - `PUT /api/operations/vehicle-documents/{id}/` - Update document
  - `DELETE /api/operations/vehicle-documents/{id}/` - Delete document
  - `GET /api/operations/vehicle-documents/expiring-soon/` - Get expiring documents
  - `GET /api/operations/vehicle-documents/expired/` - Get expired documents
  - `POST /api/operations/vehicle-documents/{id}/renew/` - Renew document
  - `GET /api/operations/vehicle-documents/document-types/` - Get document types

- **Dashboard**: `/api/operations/dashboard/`
  - Enhanced with `vehicle_alerts` data including expiring and expired documents

### Permissions
- **View Access**: Admin, Manager, Supervisor, Accountant
- **Edit Access**: Admin, Manager, Accountant only

## Frontend Implementation

### Screens
1. **Vehicle Documents Screen** (`vehicle_documents_screen.dart`)
   - Tabbed interface: All Vehicles, Expiring Soon, Document Overview
   - Filter options for status and ownership
   - Vehicle cards with document count badges

2. **Add Vehicle Screen** (`add_vehicle_screen.dart`)
   - Form for creating new vehicles
   - Vehicle type dropdown integration

3. **Vehicle Detail Screen** (`vehicle_detail_screen.dart`)
   - Vehicle information tab
   - Documents tab with grouped display (current + history)
   - Add/Edit/Renew document options

4. **Add Document Screen** (`add_document_screen.dart`)
   - Multi-mode: Add new, Edit existing, Renew expired
   - Document type dropdown
   - Date pickers for issue and expiry dates

### Dashboard Integration
- **Vehicle Alerts Card**: Displays expiring and expired documents
- **All Roles**: Vehicle alerts shown at the top of each dashboard
- **Navigation**: Direct link to vehicle documents from alerts

### Services
- **VehicleService**: Complete API integration for vehicles and documents
- **DashboardService**: Fetches dashboard data including vehicle alerts

## Database Schema

### Vehicle Table
- `id` (Primary Key)
- `vehicle_number` (Unique, Uppercase)
- `vehicle_type_id` (Foreign Key to VehicleType)
- `ownership` (Owned/Hired)
- `status` (Active/Inactive/Under Maintenance)
- `owner_name`, `owner_contact`
- `capacity`, `make_model`, `year_of_manufacture`
- `chassis_number`, `engine_number`
- `remarks`, `is_active`
- `created_by_id`, `created_at`, `updated_at`

### VehicleDocument Table
- `id` (Primary Key)
- `vehicle_id` (Foreign Key to Vehicle)
- `document_type` (Choice field)
- `document_number`
- `document_file` (File upload)
- `issue_date`, `expiry_date`
- `status` (Active/Expired - Auto-calculated)
- `renewal_reference_id` (Self-referential Foreign Key)
- `notes`
- `added_by_id`, `added_on`, `updated_at`

## Usage Examples

### Adding a New Vehicle
1. Navigate to Vehicle Documents
2. Click "+" button (Admin/Manager/Accountant only)
3. Fill vehicle details form
4. Submit to create vehicle master record

### Adding Documents
1. Go to Vehicle Detail screen
2. Switch to Documents tab
3. Click "Add Document" button
4. Select document type, enter details
5. Submit to create document record

### Renewing Documents
1. Find document in Vehicle Detail screen
2. Click "Renew" button on current active document
3. Form pre-fills with document type
4. Enter new document details
5. Submit - old document marked expired, new one active

### Viewing Alerts
- Dashboard shows expiring/expired documents at the top
- Click "View All" to go to Vehicle Documents screen
- "Expiring Soon" tab shows all documents needing attention

## Demo Data
Run the management command to create sample data:
```bash
python manage.py add_demo_vehicles
```

This creates:
- 10 sample vehicles with different types and ownership
- Multiple documents per vehicle (active, expiring, expired)
- Document renewal history examples

## Navigation
- **Menu**: "Vehicle Documents" available in app drawer for all roles
- **Dashboard**: Vehicle alerts card with direct navigation
- **Permissions**: Edit capabilities restricted by role

## Technical Notes
- **File Uploads**: Basic file field implemented (PDF/JPG support)
- **Status Auto-calculation**: Document status updated automatically on save
- **Data Integrity**: Only one active document per type per vehicle
- **History Preservation**: All document versions retained for audit trails
- **Performance**: Optimized queries with select_related and prefetch_related

## Future Enhancements
- Advanced file upload handling with progress indicators
- Document preview/download functionality
- Email notifications for expiring documents
- Bulk document upload capabilities
- Document verification workflow
- Integration with external document verification services

## Testing
The system includes comprehensive demo data and can be tested by:
1. Creating vehicles through the UI
2. Adding documents with various expiry dates
3. Testing renewal workflow
4. Verifying role-based access restrictions
5. Checking alert system functionality 