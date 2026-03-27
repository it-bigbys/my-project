import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:team_collab/providers/auth_provider.dart';
import 'package:team_collab/screens/profile/profile_screen.dart';

void main() {
  group('Password Change Tests', () {
    testWidgets('Profile screen shows change password button', (WidgetTester tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify change password button is present
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      print('✅ Change password button is visible in profile screen');
    });

    testWidgets('Change password dialog opens when button is tapped', (WidgetTester tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to make the button visible
      await tester.ensureVisible(find.text('Change Password'));
      await tester.pumpAndSettle();

      // Tap the change password button
      await tester.tap(find.text('Change Password').first);
      await tester.pumpAndSettle();

      // Verify dialog appears by checking for dialog-specific elements
      expect(find.text('Enter your current password and choose a new one.'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      print('✅ Change password dialog opens correctly');
    });

    testWidgets('Password form validation works', (WidgetTester tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to and open dialog
      await tester.ensureVisible(find.text('Change Password'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      // Try to submit empty form - find the button in the dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Change Password'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('This field cannot be empty'), findsWidgets);

      print('✅ Password form validation works correctly');
    });

    testWidgets('Password visibility toggles work', (WidgetTester tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to and open dialog
      await tester.ensureVisible(find.text('Change Password'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      // Check that visibility toggle icons are present
      expect(find.byIcon(Icons.visibility_off), findsNWidgets(3)); // One for each password field

      print('✅ Password visibility toggles are present');
    });
  });
}