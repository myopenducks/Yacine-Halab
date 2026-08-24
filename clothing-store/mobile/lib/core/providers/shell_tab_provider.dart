import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom navigation indices (StatefulShellRoute.indexedStack).
abstract final class ShellTabs {
  static const int home = 0;
  static const int products = 1;
  static const int sale = 2;
  static const int history = 3;
  static const int profile = 4;
}

class ActiveShellTabNotifier extends Notifier<int> {
  @override
  int build() => ShellTabs.home;

  void setIndex(int index) {
    if (state == index) return;
    state = index;
  }
}

final activeShellTabIndexProvider =
    NotifierProvider<ActiveShellTabNotifier, int>(ActiveShellTabNotifier.new);
