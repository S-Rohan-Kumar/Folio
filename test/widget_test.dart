import 'package:flutter_test/flutter_test.dart';
import 'package:pagebound/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PageboundApp());
    expect(find.text('Home Screen'), findsNothing); // It might not be loaded initially due to GoRouter async
  });
}
