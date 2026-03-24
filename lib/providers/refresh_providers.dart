import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppDataRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state++;
  }
}

final appDataRefreshProvider =
    NotifierProvider<AppDataRefreshNotifier, int>(AppDataRefreshNotifier.new);
