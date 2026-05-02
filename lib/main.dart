import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class DoonInfraApp extends ConsumerWidget {
  DoonInfraApp({super.key});

  final router = createAppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
