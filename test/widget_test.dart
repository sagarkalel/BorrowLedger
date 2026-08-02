import 'package:borrow_ledger/main.dart';
import 'package:borrow_ledger/presentation/screens/splash_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts on splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BorrowLedgerApp());

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
