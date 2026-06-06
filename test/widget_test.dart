import 'package:flutter_test/flutter_test.dart';

import 'package:smart_vision_assistant/app.dart';

void main() {
  testWidgets('shows Smart Vision Assistant title', (tester) async {
    await tester.pumpWidget(const SmartVisionAssistantApp());
    await tester.pump();

    expect(find.text('Smart Vision Assistant'), findsOneWidget);
  });
}
