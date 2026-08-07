import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:controle_financeiro/providers/finance_provider.dart';
import 'package:controle_financeiro/screens/charts_screen.dart';

void main() {
  testWidgets('a tela de gráficos renderiza corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ],
        child: const MaterialApp(home: ChartsScreen()),
      ),
    );

    expect(find.text('Gráficos'), findsOneWidget);
  });
}
