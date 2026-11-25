import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/customers/data/memory_customer_repository.dart';
import 'package:service_track/modules/customers/domain/value_objects/customer.dart';
import 'package:service_track/modules/work_orders/data/memory_work_order_repository.dart';
import 'package:service_track/modules/work_orders/ui/form/work_order_form_controller.dart';
import 'package:service_track/modules/work_orders/ui/form/work_order_form_page.dart';

void main() {
  testWidgets('formata moeda, data e permite seleção de horário', (tester) async {
    final woRepo = MemoryWorkOrderRepository();
    final custRepo = MemoryCustomerRepository();
    await custRepo.save(
      Customer.tryCreate(
        id: 'c1',
        name: 'Cliente Teste',
        document: '52998224725',
        whatsapp: '11999998888',
        email: 'cliente@teste.com',
        notes: '',
      ).getOrNull()!,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<WorkOrderFormController>(
              create: (_) => WorkOrderFormController(
                repository: woRepo,
                customerRepository: custRepo,
              ),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const WorkOrderFormPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Testa máscara de valor (CurrencyInputFormatter)
    final valueFinder = find.byKey(const Key('wo-value'));
    await tester.enterText(valueFinder, '15000');
    await tester.pumpAndSettle();

    final valueField = tester.widget<TextField>(valueFinder);
    expect(valueField.controller?.text, '150,00');

    // 2. Testa máscara de data
    final dateFinder = find.byKey(const Key('wo-date'));
    expect(dateFinder, findsOneWidget);
    await tester.enterText(dateFinder, '25112026');
    await tester.pumpAndSettle();

    final dateField = tester.widget<TextField>(dateFinder);
    expect(dateField.controller?.text, '25/11/2026');

    // 3. Testa dropdown de horários
    final timeFinder = find.byKey(const Key('wo-time'));
    expect(timeFinder, findsOneWidget);
  });
}
