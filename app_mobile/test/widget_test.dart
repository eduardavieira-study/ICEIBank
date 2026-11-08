import 'package:flutter_test/flutter_test.dart';
import 'package:app_mobile/main.dart';

void main() {
  testWidgets('tela inicial lista as 3 agências', (tester) async {
    await tester.pumpWidget(const IceiBankApp());

    expect(find.text('ICEIBank'), findsOneWidget);
    expect(find.text('Agência 0'), findsOneWidget);
    expect(find.text('Agência 1'), findsOneWidget);
    expect(find.text('Agência 2'), findsOneWidget);
  });
}
