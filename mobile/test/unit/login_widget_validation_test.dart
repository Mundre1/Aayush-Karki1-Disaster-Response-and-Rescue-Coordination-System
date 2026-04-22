import 'package:disaster_response_mobile/features/auth/auth_provider.dart';
import 'package:disaster_response_mobile/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('UT-DART-04 Login widget validation messages appear on empty submit',
      (tester) async {
    print('[UT-DART-04] Starting login widget validation test');
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    print('[UT-DART-04] Completed successfully');
  });
}
