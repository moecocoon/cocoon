
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cocoon/screens/admin_dashboard_screen.dart';

void main() {
  testWidgets('企業管理画面が表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboardScreen(),
      ),
    );

    expect(
      find.text('COCOON 企業管理画面'),
      findsOneWidget,
    );

    expect(
      find.text('従業員の心の傾向'),
      findsOneWidget,
    );

    expect(find.text('124件'), findsOneWidget);
    expect(find.text('62%'), findsOneWidget);
  });
}


