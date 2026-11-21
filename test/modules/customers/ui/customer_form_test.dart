import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/customers/data/memory_customer_repository.dart';
import 'package:service_track/modules/customers/ui/form/customer_form_controller.dart';
import 'package:service_track/modules/customers/ui/form/customer_form_page.dart';

void main() {
  testWidgets('UC-02.01 - cadastra cliente válido', (tester) async {
    final repo = MemoryCustomerRepository();
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<CustomerFormController>(
              create: (_) => CustomerFormController(repository: repo),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: CustomerFormPage(onSaved: () => saved = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('customer-name')), 'Maria Silva');
    await tester.enterText(find.byKey(const Key('customer-document')), '52998224725');
    await tester.enterText(find.byKey(const Key('customer-whatsapp')), '11999998888');
    await tester.tap(find.byKey(const Key('customer-save')));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    final all = await repo.findAll();
    expect(all.getOrNull()!.length, 1);
    expect(all.getOrNull()!.first.name.value, 'Maria Silva');
  });
}
