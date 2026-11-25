import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/customers/data/memory_customer_repository.dart';
import 'package:service_track/modules/customers/ui/form/customer_form_controller.dart';
import 'package:service_track/modules/customers/ui/form/customer_form_page.dart';

void main() {
  testWidgets('aplica máscaras de formatação em CPF/CNPJ e Telefone', (tester) async {
    final repo = MemoryCustomerRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<CustomerFormController>(
              create: (_) => CustomerFormController(repository: repo),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const CustomerFormPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final docFinder = find.byKey(const Key('customer-document'));
    await tester.enterText(docFinder, '52998224725');
    await tester.pumpAndSettle();

    final docField = tester.widget<TextField>(docFinder);
    expect(docField.controller?.text, '529.982.247-25');

    final phoneFinder = find.byKey(const Key('customer-whatsapp'));
    await tester.enterText(phoneFinder, '11999998888');
    await tester.pumpAndSettle();

    final phoneField = tester.widget<TextField>(phoneFinder);
    expect(phoneField.controller?.text, '(11) 99999-8888');
  });
}
