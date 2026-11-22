import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/customers/data/memory_customer_repository.dart';
import 'package:service_track/modules/customers/data/memory_service_location_repository.dart';
import 'package:service_track/modules/customers/domain/value_objects/customer.dart';
import 'package:service_track/modules/customers/ui/customers_routes.dart';

void main() {
  testWidgets(
    'OPS-APP-SHELL-DI - rota de clientes monta escopo Kortex e lista',
    (tester) async {
      final customerRepo = MemoryCustomerRepository();
      await customerRepo.save(
        Customer.tryCreate(
          id: 'c1',
          name: 'Maria Silva',
          document: '52998224725',
          whatsapp: '11999998888',
          email: 'maria@exemplo.com',
          notes: '',
        ).getOrNull()!,
      );
      final routes = CustomersRoutes(
        customerRepository: customerRepo,
        locationRepository: MemoryServiceLocationRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open-customers'),
                  onPressed: () {
                    unawaited(Navigator.of(context).push(routes.list()));
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-customers')));
      await tester.pumpAndSettle();

      expect(find.text('Clientes'), findsOneWidget);
      expect(find.text('Maria Silva'), findsOneWidget);
    },
  );
}
