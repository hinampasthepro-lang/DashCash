import 'package:flutter_test/flutter_test.dart';
import 'package:dashcash_mobile/main.dart';

void main() {
  testWidgets('DashCash app loads login screen test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DashCashApp());

    // Verify that the DASHCASH logo/header appears on startup
    expect(find.text('DASHCASH'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
  });
}
