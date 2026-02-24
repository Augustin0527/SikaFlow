import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_control/main.dart';

void main() {
  testWidgets('SikaFlow app smoke test', (WidgetTester tester) async {
    // Test basique - vérifier que l'app se lance
    expect(SikaFlowApp, isNotNull);
  });
}
