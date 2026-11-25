import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/customers/data/memory_service_location_repository.dart';
import 'package:service_track/modules/customers/domain/value_objects/service_location.dart';
import 'package:service_track/modules/customers/ui/locations/service_location_list_controller.dart';
import 'package:service_track/modules/customers/ui/locations/service_location_list_page.dart';

void main() {
  testWidgets('UC-02.05 - exclusão de local de atendimento via DismissibleTile com confirmação', (tester) async {
    final repo = MemoryServiceLocationRepository();
    await repo.save(ServiceLocation.tryCreate(
      id: 'l1',
      customerId: 'c1',
      label: 'Sede Principal',
      street: 'Av Paulista',
      number: '1000',
      neighborhood: 'Bela Vista',
      city: 'São Paulo',
      state: 'SP',
      cep: '01310100',
      reference: '',
    ).getOrNull()!);

    final controller = ServiceLocationListController(repository: repo, customerId: 'c1');

    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<ServiceLocationListController>(
              create: (_) => controller,
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const ServiceLocationListPage(customerName: 'Cliente Teste'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sede Principal'), findsOneWidget);

    // Garante que o IconButton trailing de lixeira não está mais solto no ListTile
    expect(find.byKey(const Key('location-delete-l1')), findsNothing);

    // Arrasta para abrir o dismiss
    await tester.drag(find.text('Sede Principal'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Diálogo de confirmação
    expect(find.text('Excluir local de atendimento?'), findsOneWidget);
    expect(find.text('Deseja realmente remover o local "Sede Principal"?'), findsOneWidget);

    // Clica em Excluir
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Local de atendimento removido com sucesso'), findsOneWidget);
    expect(find.text('Sede Principal'), findsNothing);
    expect(find.text('Nenhum local cadastrado.'), findsOneWidget);
  });
}
