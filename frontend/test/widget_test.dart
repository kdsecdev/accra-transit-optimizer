import 'package:accra_transit_optimizer/providers/transit_provider.dart';
import 'package:accra_transit_optimizer/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App loads tabs and analytics correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<TransitProvider>(
        create: (_) => TransitProvider(),
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Confirm Map tab appears
    expect(find.text('Accra Transit Optimizer'), findsOneWidget);

    // Navigate to Analytics tab
    await tester.tap(find.byIcon(Icons.analytics));
    await tester.pumpAndSettle();

    expect(find.textContaining('Recommendations'), findsOneWidget);

    // Navigate to Routes tab
    await tester.tap(find.byIcon(Icons.route));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.directions_bus), findsWidgets);
  });
}
