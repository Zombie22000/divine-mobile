// ABOUTME: Widget test for welcome screen authentication state handling
// ABOUTME: Verifies that welcome screen shows correct UI based on AuthState (checking, authenticating, authenticated, unauthenticated)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openvine/screens/welcome_screen.dart';
import 'package:openvine/providers/app_providers.dart';
import 'package:openvine/services/auth_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([AuthService])
import 'welcome_screen_auth_state_test.mocks.dart';

void main() {
  group('WelcomeScreen Auth State Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    testWidgets('shows loading indicator when auth state is checking',
        (tester) async {
      // Setup: Auth state is CHECKING
      when(mockAuthService.authState).thenReturn(AuthState.checking);
      when(mockAuthService.isAuthenticated).thenReturn(false);

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      // Use pump() instead of pumpAndSettle() because CircularProgressIndicator animates continuously
      await tester.pump();

      // Expect: Loading indicator shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Expect: Create/Import buttons NOT shown
      expect(find.text('Create New Identity'), findsNothing);
      expect(find.text('Import Existing Identity'), findsNothing);
    });

    testWidgets('shows loading indicator when auth state is authenticating',
        (tester) async {
      // Setup: Auth state is AUTHENTICATING
      when(mockAuthService.authState).thenReturn(AuthState.authenticating);
      when(mockAuthService.isAuthenticated).thenReturn(false);

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      // Use pump() instead of pumpAndSettle() because CircularProgressIndicator animates continuously
      await tester.pump();

      // Expect: Loading indicator shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Expect: Create/Import buttons NOT shown
      expect(find.text('Create New Identity'), findsNothing);
      expect(find.text('Import Existing Identity'), findsNothing);
    });

    testWidgets('shows Continue button when authenticated',
        (tester) async {
      // Setup: Auth state is AUTHENTICATED
      when(mockAuthService.authState).thenReturn(AuthState.authenticated);
      when(mockAuthService.isAuthenticated).thenReturn(true);

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expect: Continue button shown
      expect(find.text('Continue'), findsOneWidget);

      // Expect: Create/Import buttons NOT shown
      expect(find.text('Create New Identity'), findsNothing);
      expect(find.text('Import Existing Identity'), findsNothing);
    });

    testWidgets('shows error message when unauthenticated (auto-creation failed)',
        (tester) async {
      // Setup: Auth state is UNAUTHENTICATED (auto-creation failed)
      when(mockAuthService.authState).thenReturn(AuthState.unauthenticated);
      when(mockAuthService.isAuthenticated).thenReturn(false);
      when(mockAuthService.lastError).thenReturn('Failed to create identity');

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expect: Error message shown
      expect(find.text('Setup Error'), findsOneWidget);
      expect(find.textContaining('Failed to'), findsOneWidget);

      // Expect: Create/Import buttons NEVER shown
      expect(find.text('Create New Identity'), findsNothing);
      expect(find.text('Import Existing Identity'), findsNothing);

      // Expect: Continue button NOT shown
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('Continue button disabled when TOS not accepted',
        (tester) async {
      // Setup: Auth state is AUTHENTICATED
      when(mockAuthService.authState).thenReturn(AuthState.authenticated);
      when(mockAuthService.isAuthenticated).thenReturn(true);

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Continue button
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      expect(continueButton, findsOneWidget);

      // Verify button is disabled (onPressed is null) because TOS not accepted
      final ElevatedButton buttonWidget = tester.widget(continueButton);
      expect(buttonWidget.onPressed, isNull);
    });
  });
}
