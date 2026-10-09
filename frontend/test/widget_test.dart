import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buyitbro/main.dart';

void main() {
  testWidgets('App renders correctly smoke test', (WidgetTester tester) async {
    // Set initial mock values for SharedPreferences
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BuyItBroApp());
    await tester.pumpAndSettle();

    // Verify that the BuyItBro branding appears on the Auth screen
    expect(find.text('BuyItBro'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
