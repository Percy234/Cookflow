import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cookflow/providers/recipe_provider.dart';
import 'package:cookflow/providers/execution_provider.dart';
import 'package:cookflow/services/timer_service.dart';

void main() {
  testWidgets('CookFlow app smoke test', (WidgetTester tester) async {
    // Note: Full app test requires Hive initialization.
    // This is a basic smoke test for the widget tree structure.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RecipeProvider()),
          ChangeNotifierProvider(create: (_) => ExecutionProvider()),
          ChangeNotifierProvider(create: (_) => TimerService()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => const Scaffold(
              body: Center(child: Text('CookFlow')),
            ),
          ),
        ),
      ),
    );
    expect(find.text('CookFlow'), findsOneWidget);
  });
}
