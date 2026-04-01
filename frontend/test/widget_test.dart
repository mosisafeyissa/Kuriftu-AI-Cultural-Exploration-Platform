import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('App renders welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CulturalWhispererApp());
    expect(find.text('KURIFTU'), findsOneWidget);
    expect(find.text('BEGIN JOURNEY'), findsOneWidget);
  });
}
