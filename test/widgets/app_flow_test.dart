import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pacelens/app/app.dart';

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'PaceLens',
      packageName: 'com.w3artists.pacelens',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('home screen shows required actions and warning', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PaceLensApp()));
    await tester.pumpAndSettle();

    expect(find.text('PaceLens'), findsOneWidget);
    expect(find.text('v1.0.0+1'), findsOneWidget);
    expect(find.text('Measure moving object'), findsOneWidget);
    expect(find.text('Analyse existing video'), findsOneWidget);
    expect(find.text('Previous results'), findsOneWidget);
    expect(find.textContaining('not a certified radar-speed'), findsOneWidget);
  });

  testWidgets('secondary screens can navigate back to home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PaceLensApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analyse existing video'));
    await tester.pumpAndSettle();

    expect(find.text('Video import'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('PaceLens'), findsOneWidget);
    expect(find.text('Analyse existing video'), findsOneWidget);
  });

  testWidgets('recording screen provides a way out', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PaceLensApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Measure moving object'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Open recording screen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Recording'), findsOneWidget);
    expect(find.text('Live speed test'), findsOneWidget);
    expect(find.text('Calibrated mph'), findsOneWidget);
    expect(find.text('AR depth mph'), findsOneWidget);
    expect(find.text('Pixel speed'), findsNothing);
    expect(
      find.text('Real distance between guide lines in metres'),
      findsOneWidget,
    );
    expect(find.text('Start speed test'), findsOneWidget);
  });
}
