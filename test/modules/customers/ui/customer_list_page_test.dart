import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/customers/data/memory_customer_repository.dart';
import 'package:service_track/modules/customers/domain/value_objects/customer.dart';
import 'package:service_track/modules/customers/ui/list/customer_list_controller.dart';
import 'package:service_track/modules/customers/ui/list/customer_list_page.dart';

void main() {
  testWidgets('UC-02.05 - exclusão de cliente via DismissibleTile com confirmação', (tester) async {
    final repo = MemoryCustomerRepository();
    await repo.save(Customer.tryCreate(
      id: 'c1',
      name: 'Maria Silva',
      document: '52998224725',
      whatsapp: '11999998888',
      email: 'maria@exemplo.com',
      notes: 'Obs',
    ).getOrNull()!);

    final controller = CustomerListController(repository: repo);

    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<CustomerListController>(
              create: (_) => controller,
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const CustomerListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maria Silva'), findsOneWidget);

    // Arrasta para abrir o dismiss
    await tester.drag(find.text('Maria Silva'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Diálogo de confirmação deve aparecer
    expect(find.text('Excluir cliente?'), findsOneWidget);
    expect(
      find.text('Deseja realmente excluir o cliente "Maria Silva"? Esta ação removerá o cadastro e seus dados.'),
      findsOneWidget,
    );

    // Clica em Excluir no diálogo
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    // Item deve ter sido excluído e mensagem de sucesso exibida
    expect(find.text('Cliente excluído com sucesso'), findsOneWidget);
    expect(find.text('Maria Silva'), findsNothing);
    expect(find.text('Nenhum cliente cadastrado.'), findsOneWidget);
  });
}
