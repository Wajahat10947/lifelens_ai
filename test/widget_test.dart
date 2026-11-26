
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelens_ai/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('LifeLens AI home screen test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('LifeLens AI'), findsOneWidget);
    expect(find.text('AI Learning'), findsOneWidget);
  });
}
