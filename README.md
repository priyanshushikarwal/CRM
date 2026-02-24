# DoonInfra Solar Manager

A comprehensive desktop application for managing solar rooftop installation applications, inspired by the PM Surya Ghar: Muft Bijli Yojana National Portal.

## Features

✅ **Dashboard** - Overview of all applications with statistics
✅ **Application List** - View, search, filter, and manage applications
✅ **Application Details** - Complete view of each application with all details
✅ **Progress Tracking** - 9-stage workflow tracking for each application
✅ **Document Management** - Upload and view documents per application
✅ **Multi-user Authentication** - Secure login with Supabase
✅ **Cloud Sync** - Real-time data sync across devices
✅ **Export Options** - Export to Excel and MIS reports

## Application Workflow Stages

1. **Consumer Registration** - Initial consumer registration
2. **Consumer Application** - Application submission
3. **Discom Feasibility** - Feasibility assessment by Discom
4. **Consumer Vendor Selection** - Vendor selection by consumer
5. **Vendor Upload Agreement** - Agreement upload by vendor
6. **Vendor Installation** - Installation by vendor
7. **Discom Inspection** - Inspection by Discom
8. **Project Commissioning** - Project commissioning
9. **Consumer Subsidy Request** - Subsidy disbursement

## Tech Stack

- **Framework**: Flutter (Desktop - Windows, macOS, Linux)
- **State Management**: Riverpod 3.x
- **Navigation**: GoRouter
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **UI Components**: Syncfusion Flutter
- **Fonts**: Google Fonts (Inter)

## Setup Instructions

### 1. Prerequisites

- Flutter SDK 3.x+
- Windows/macOS/Linux development environment
- Supabase account (free tier works)

### 2. Clone and Install Dependencies

```bash
cd dooninfra_app
flutter pub get
```

### 3. Configure Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Copy your project URL and anon key
3. Update `lib/core/constants/app_constants.dart`:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

4. Run the SQL schema in your Supabase SQL Editor (see `supabase_schema.sql`)

### 4. Enable Supabase Initialization

Uncomment the Supabase initialization in `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Uncomment this line:
  await SupabaseService.initialize();
  
  runApp(const ProviderScope(child: DoonInfraApp()));
}
```

### 5. Run the Application

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Web (for testing)
flutter run -d chrome
```

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart    # App configuration
│   ├── router/
│   │   └── app_router.dart       # Navigation routes
│   └── theme/
│       └── app_theme.dart        # UI theme
├── models/
│   ├── application_model.dart    # Application data model
│   ├── document_model.dart       # Document data model
│   └── user_model.dart           # User data model
├── providers/
│   └── app_providers.dart        # Riverpod state providers
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── applications/
│   │   ├── add_application_screen.dart
│   │   ├── application_details_screen.dart
│   │   └── applications_list_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   └── splash_screen.dart
├── services/
│   ├── application_service.dart  # CRUD operations
│   └── supabase_service.dart     # Supabase client
└── main.dart                     # Entry point
```

## User Roles

| Role | Permissions |
|------|-------------|
| Admin | Full access - create, edit, delete, manage users |
| Vendor | Create, edit own applications |
| Operator | Create, edit applications |
| Viewer | Read-only access |

## Screenshots

The application replicates the PM Surya Ghar National Portal design with:
- Professional blue theme
- Responsive sidebar navigation
- Application progress tracker
- Data tables with search and filters
- Document management system

## License

This project is proprietary software developed for Doon Infrapower Projects Pvt. Ltd.

## Support

For issues or feature requests, contact the development team.
