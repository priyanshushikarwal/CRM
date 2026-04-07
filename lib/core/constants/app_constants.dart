class AppConstants {
  static const String appName = 'DoonInfra Solar Manager';
  static const String appVersion = '1.0.19';
  static const String companyName = 'Doon Infrapower Projects Pvt. Ltd.';

  static const String supabaseUrl = 'https://mclanssbjbmcelunhpip.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1jbGFuc3NiamJtY2VsdW5ocGlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4MjAzMTEsImV4cCI6MjA4MTM5NjMxMX0.DeISAs5HhnOoSyZY0brJO9K17tx1QBY2SkRdhCKqsU4';

  static const String applicationsTable = 'applications';
  static const String documentsTable = 'documents';
  static const String usersTable = 'users';
  static const String statusHistoryTable = 'status_history';
  static const String inventoryTable = 'solar_inventory';
  static const String inventoryAssignmentsTable = 'solar_inventory_assignments';
  
  // New Inventory v2 Tables
  static const String inventoryInvoicesTable = 'inventory_invoices';
  static const String panelItemsTable = 'panel_items';
  static const String inverterItemsTable = 'inverter_items';
  static const String meterItemsTable = 'meter_items';
  static const String inventoryAllotmentsTable = 'inventory_allotments';

  static const String documentsBucket = 'documents';
  static const String paymentReceiptsFolder = 'payment-receipts';

  static const List<String> applicationStatuses = [
    'Application Received',
    'Documents Verified',
    'Site Survey Pending',
    'Site Survey Completed',
    'Solar Demand Pending',
    'Solar Demand Deposit',
    'Meter Tested',
    'Installation Scheduled',
    'Installation Completed',
    'Subsidy Process',
  ];

  static const List<String> documentTypes = [
    'Aadhar Card',
    'Electricity Bill',
    'Property Proof',
    'Cancel Cheque',
    'Final Amount Receipt',
    'Final Solar Project File',
  ];

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

  static const List<String> categoryTypes = [
    'Domestic',
    'Commercial',
  ];

  static const List<String> genderOptions = ['Male', 'Female', 'Other'];

  static const List<String> loanStatusOptions = [
    'Not Applied',
    'Applied',
    'Under Review',
    'Approved',
    'Rejected',
    'Disbursed',
  ];

  static const List<String> feasibilityStatusOptions = [
    'Pending',
    'Under Review',
    'Approved with Applied Capacity',
    'Approved with Reduced Capacity',
    'Rejected',
  ];
}
