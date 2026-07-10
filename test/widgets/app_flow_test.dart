import 'package:flutter_test/flutter_test.dart';
import 'package:pacelens/app/app.dart';

void main() {
  testWidgets('home screen shows required actions and warning', (tester) async {
    await tester.pumpWidget(const PaceLensApp());
    await tester.pumpAndSettle();

    expect(find.text('PaceLens'), findsOneWidget);
    expect(find.text('Record delivery'), findsOneWidget);
    expect(find.text('Analyse existing video'), findsOneWidget);
    expect(find.text('Previous results'), findsOneWidget);
    expect(find.textContaining('not a certified radar-speed'), findsOneWidget);
  });
}
