import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/customers/data/memory_customer_repository.dart';
import 'package:service_track/modules/customers/domain/value_objects/customer.dart';
import 'package:service_track/modules/customers/ui/detail/customer_detail_controller.dart';
import 'package:service_track/modules/customers/ui/detail/customer_detail_page.dart';

void main() {
  testWidgets('UC-02.04 - exibe detalhes do cliente e histórico vazio', (tester) async {
    final repo = MemoryCustomerRepository();
    await repo.save(Customer.tryCreate(
      id: 'c1', name: 'Maria Silva', document: '52998224725',
      whatsapp: '11999998888', email: 'maria@exemplo.com', notes: 'Obs',
    ).getOrNull()!);

    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<CustomerDetailController>(
              create: (_) => CustomerDetailController(repository: repo, customerId: 'c1'),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const CustomerDetailPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.textContaining('11999998888'), findsOneWidget);
    expect(find.text('Histórico de Ordens de Serviço'), findsOneWidget);
    expect(find.text('Nenhuma OS emitida.'), findsOneWidget);
  });
}
