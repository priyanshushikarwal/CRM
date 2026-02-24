class AppConstants {
  // App Info
  static const String appName = 'DoonInfra Solar Manager';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Doon Infrapower Projects Pvt. Ltd.';

  // Supabase Configuration
  // TODO: Replace with your actual Supabase credentials
  static const String supabaseUrl = 'https://mclanssbjbmcelunhpip.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1jbGFuc3NiamJtY2VsdW5ocGlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4MjAzMTEsImV4cCI6MjA4MTM5NjMxMX0.DeISAs5HhnOoSyZY0brJO9K17tx1QBY2SkRdhCKqsU4';

  // Table Names
  static const String applicationsTable = 'applications';
  static const String documentsTable = 'documents';
  static const String usersTable = 'users';
  static const String statusHistoryTable = 'status_history';

  // Storage Buckets
  static const String documentsBucket = 'documents';

  // Application Status Types
  static const List<String> applicationStatuses = [
    'Consumer Registration',
    'Consumer Application',
    'Discom Feasibility',
    'Consumer Vendor Selection',
    'Vendor Upload Agreement',
    'Vendor Installation',
    'Discom Inspection',
    'Project Commissioning',
    'Consumer Subsidy Request',
  ];

  // Document Types
  static const List<String> documentTypes = [
    'Application Acknowledgement',
    'EToken',
    'Feasibility Document',
    'Net Metering Agreement',
    'Electricity Bill',
    'ID Proof',
    'Address Proof',
    'Bank Statement',
    'Installation Photo',
    'Meter Photo',
    'Other',
  ];

  // States of India
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  // Category Types
  static const List<String> categoryTypes = [
    'Residential',
    'Commercial',
    'Industrial',
    'Institutional',
  ];

  // Gender Options
  static const List<String> genderOptions = ['Male', 'Female', 'Other'];

  // Loan Status Options
  static const List<String> loanStatusOptions = [
    'Not Applied',
    'Applied',
    'Under Review',
    'Approved',
    'Rejected',
    'Disbursed',
  ];

  // Feasibility Status Options
  static const List<String> feasibilityStatusOptions = [
    'Pending',
    'Under Review',
    'Approved with Applied Capacity',
    'Approved with Reduced Capacity',
    'Rejected',
  ];
}
