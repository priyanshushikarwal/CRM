import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/supabase_service.dart';

class AppDataRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state++;
  }
}

final appDataRefreshProvider =
    NotifierProvider<AppDataRefreshNotifier, int>(AppDataRefreshNotifier.new);

final periodicSyncProvider = Provider<void>((ref) {
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    if (!SupabaseService.isLoggedIn) return;
    ref.read(appDataRefreshProvider.notifier).bump();
  });

  ref.onDispose(timer.cancel);
});
