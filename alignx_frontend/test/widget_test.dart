import 'package:flutter_test/flutter_test.dart';
import 'package:alignx_frontend/main.dart';

void main() {
  testWidgets('AlignX app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AlignXApp());

    // Verify that the title AlignX is present
    expect(find.text('AlignX'), findsOneWidget);
  });
}
