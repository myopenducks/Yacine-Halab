import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clothing_store_mobile/features/auth/auth_provider.dart';
import 'package:clothing_store_mobile/main.dart';

/// Avoids real secure-storage / network during widget smoke test.
class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(status: AuthStatus.unauthenticated);

  @override
  Future<void> bootstrap() async {
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

void main() {
  testWidgets('App shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_TestAuthNotifier.new),
        ],
        child: const ClothingStoreApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
