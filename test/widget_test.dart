import 'package:flutter_test/flutter_test.dart';

import 'package:clippi/main.dart';

void main() {
  testWidgets('ClippiApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ClippiApp());

    expect(find.text('Clippi'), findsOneWidget);
  });
}
