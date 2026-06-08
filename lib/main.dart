import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_mode.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/app_providers.dart';
import 'providers/refresh_providers.dart';
import 'services/supabase_service.dart';

void main() async {
  await bootstrapApp(AppMode.full);
}

Future<void> bootstrapApp(AppMode mode) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent GoogleFonts from fetching over the network in release builds
  GoogleFonts.config.allowRuntimeFetching = !kReleaseMode;

  // Catch Flutter framework errors gracefully
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  AppModeConfig.setMode(mode);

  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  runApp(ProviderScope(child: DoonInfraApp()));
}

class DoonInfraApp extends ConsumerStatefulWidget {
  const DoonInfraApp({super.key});

  @override
  ConsumerState<DoonInfraApp> createState() => _DoonInfraAppState();
}

class _DoonInfraAppState extends ConsumerState<DoonInfraApp> {
  late final GoRouter router;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    router = createAppRouter();

    _authSubscription = SupabaseService.authStateChanges.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        debugPrint('DEBUG: Password recovery event triggered. Routing to /update-password');
        router.go('/update-password');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeSyncProvider);
    ref.watch(periodicSyncProvider);

    return MaterialApp.router(
      title: AppModeConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.lightTheme.textTheme),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.darkTheme.textTheme),
      ),
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
