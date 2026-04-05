import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/config/app_mode.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/app_providers.dart';
import 'services/supabase_service.dart';

void main() async {
  await bootstrapApp(AppMode.full);
}

Future<void> bootstrapApp(AppMode mode) async {
  WidgetsFlutterBinding.ensureInitialized();

  AppModeConfig.setMode(mode);
  await SupabaseService.initialize();
  runApp(ProviderScope(child: DoonInfraApp()));
}

class DoonInfraApp extends ConsumerWidget {
  DoonInfraApp({super.key});

  final router = createAppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(realtimeSyncProvider);

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
