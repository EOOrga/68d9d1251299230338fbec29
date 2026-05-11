import 'package:bachelier_jean_luc/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('navigates between operations areas', (tester) async {
    await tester.pumpWidget(const BachelierApp(screenshotMode: true));
    await tester.pumpAndSettle();

    expect(find.text(appName), findsOneWidget);
    expect(find.text('Priority board'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-logs')));
    await tester.pumpAndSettle();
    expect(find.text('Attendance'), findsWidgets);
    expect(find.text('Morning clinical team'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-shipments')));
    await tester.pumpAndSettle();
    expect(find.text('Shipment JL-8842'), findsOneWidget);
  });

  testWidgets('creates and saves a local attendance record', (tester) async {
    SharedPreferences.setMockInitialValues({'records_v1': '[]'});

    await tester.pumpWidget(const BachelierApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-logs')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-record')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('field-title')),
      'Evening desk team',
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-owner')),
      'Reception',
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-details')),
      'Four staff confirmed for closing.',
    );
    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle();

    expect(find.text('Evening desk team'), findsOneWidget);
    expect(find.text('Reception - May 11, 2026'), findsOneWidget);
  });
}
