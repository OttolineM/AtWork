import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('AtWork registration screen loads', (tester) async {
    await tester.pumpWidget(const AtWorkApp());

    expect(find.text('AtWork'), findsOneWidget);
    expect(find.text('Create your contributor account'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
