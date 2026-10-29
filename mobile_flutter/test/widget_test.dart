import 'package:flutter_test/flutter_test.dart';
import 'package:sarkari_job_alert/main.dart';

void main() {
  testWidgets('SarkariJobAlertApp loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SarkariJobAlertApp());
    expect(find.text('Sarkari Job Alert'), findsWidgets);
  });
}
