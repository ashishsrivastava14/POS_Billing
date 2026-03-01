import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billing/app/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: POSBillingApp()),
    );

    // Verify the app renders
    expect(find.byType(POSBillingApp), findsOneWidget);
  });
}
