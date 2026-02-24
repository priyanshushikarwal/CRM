import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase has not been initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  static bool get isInitialized => _client != null;

  // Auth methods
  static User? get currentUser => _client?.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Database methods
  static SupabaseQueryBuilder from(String table) => client.from(table);

  // Storage methods
  static SupabaseStorageClient get storage => client.storage;

  // Realtime methods
  static RealtimeChannel channel(String name) => client.channel(name);
}
