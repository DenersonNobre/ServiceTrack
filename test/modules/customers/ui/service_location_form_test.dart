import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/customers/data/memory_service_location_repository.dart';
import 'package:service_track/modules/customers/ui/locations/service_location_form_controller.dart';
import 'package:service_track/modules/customers/ui/locations/service_location_form_page.dart';

void main() {
  testWidgets('UC-02.02 - cadastra local válido', (tester) async {
    final repo = MemoryServiceLocationRepository();
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<ServiceLocationFormController>(
              create: (_) => ServiceLocationFormController(repository: repo, customerId: 'c1'),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: ServiceLocationFormPage(onSaved: () => saved = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('location-label')), 'Casa');
    await tester.enterText(find.byKey(const Key('location-street')), 'Rua A');
    await tester.enterText(find.byKey(const Key('location-city')), 'São Paulo');
    await tester.enterText(find.byKey(const Key('location-cep')), '01001000');
    await tester.ensureVisible(find.byKey(const Key('location-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('location-save')));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    final all = await repo.findByCustomerId('c1');
    expect(all.getOrNull()!.length, 1);
    expect(all.getOrNull()!.first.label.value, 'Casa');
  });
}
