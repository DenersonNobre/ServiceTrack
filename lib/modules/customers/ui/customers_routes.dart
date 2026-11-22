// Rotas e bindings Kortex do módulo de clientes.
//
// SRP: compor escopo/provider e navegação das telas de clientes/local.
// Não implementa regra de negócio nem conhece o shell do app.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../domain/ports/customer_repository_port.dart';
import '../domain/ports/service_location_repository_port.dart';
import '../domain/value_objects/customer.dart';
import '../domain/value_objects/service_location.dart';
import 'detail/customer_detail_controller.dart';
import 'detail/customer_detail_page.dart';
import 'form/customer_form_controller.dart';
import 'form/customer_form_page.dart';
import 'list/customer_list_controller.dart';
import 'list/customer_list_page.dart';
import 'locations/service_location_form_controller.dart';
import 'locations/service_location_form_page.dart';
import 'locations/service_location_list_controller.dart';
import 'locations/service_location_list_page.dart';

/// Bindings de navegação do bounded context de clientes.
final class CustomersRoutes {
  const CustomersRoutes({
    required this.customerRepository,
    required this.locationRepository,
  });

  final ICustomerRepositoryPort customerRepository;
  final IServiceLocationRepositoryPort locationRepository;

  /// Lista de clientes com atalhos para cadastro, detalhe e locais.
  Route<void> list() {
    return MaterialPageRoute<void>(
      builder: (context) => KortexScope(
        providers: [
          KortexProvider<CustomerListController>(
            create: (_) =>
                CustomerListController(repository: customerRepository),
            dispose: (controller) => controller.dispose(),
          ),
        ],
        child: Builder(
          builder: (scopeContext) {
            final list = scopeContext.readKortex<CustomerListController>();
            return CustomerListPage(
              onAdd: () => _push(context, form(onSaved: list.load)),
              onEdit: (customer) => _push(
                context,
                form(customerId: customer.id, onSaved: list.load),
              ),
              onLocations: (customer) => _push(context, locations(customer)),
              onDetail: (customer) => _push(context, detail(customer)),
            );
          },
        ),
      ),
    );
  }

  /// Cadastro/edição de cliente; ao salvar, fecha a rota e notifica o chamador.
  Route<void> form({String? customerId, VoidCallback? onSaved}) {
    return MaterialPageRoute<void>(
      builder: (context) => KortexScope(
        providers: [
          KortexProvider<CustomerFormController>(
            create: (_) => CustomerFormController(
              repository: customerRepository,
              customerId: customerId,
            ),
            dispose: (controller) => controller.dispose(),
          ),
        ],
        child: CustomerFormPage(
          onSaved: () {
            Navigator.of(context).pop();
            onSaved?.call();
          },
        ),
      ),
    );
  }

  /// Detalhe do cliente com atalhos de edição e locais.
  Route<void> detail(Customer customer) {
    return MaterialPageRoute<void>(
      builder: (context) => KortexScope(
        providers: [
          KortexProvider<CustomerDetailController>(
            create: (_) => CustomerDetailController(
              repository: customerRepository,
              customerId: customer.id,
            ),
            dispose: (controller) => controller.dispose(),
          ),
        ],
        child: Builder(
          builder: (scopeContext) {
            final detailController = scopeContext
                .readKortex<CustomerDetailController>();
            return CustomerDetailPage(
              onEdit: () => _push(
                context,
                form(customerId: customer.id, onSaved: detailController.load),
              ),
              onLocations: () => _push(context, locations(customer)),
            );
          },
        ),
      ),
    );
  }

  /// Lista de locais de atendimento do cliente.
  Route<void> locations(Customer customer) {
    return MaterialPageRoute<void>(
      builder: (context) => KortexScope(
        providers: [
          KortexProvider<ServiceLocationListController>(
            create: (_) => ServiceLocationListController(
              repository: locationRepository,
              customerId: customer.id,
            ),
            dispose: (controller) => controller.dispose(),
          ),
        ],
        child: Builder(
          builder: (scopeContext) {
            final list = scopeContext
                .readKortex<ServiceLocationListController>();
            return ServiceLocationListPage(
              customerName: customer.name.value,
              onAdd: () => _push(
                context,
                locationForm(customerId: customer.id, onSaved: list.load),
              ),
              onEdit: (location) => _push(
                context,
                locationForm(
                  customerId: customer.id,
                  locationId: location.id,
                  initial: location,
                  onSaved: list.load,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Cadastro/edição de local de atendimento.
  Route<void> locationForm({
    required String customerId,
    String? locationId,
    ServiceLocation? initial,
    VoidCallback? onSaved,
  }) {
    return MaterialPageRoute<void>(
      builder: (context) => KortexScope(
        providers: [
          KortexProvider<ServiceLocationFormController>(
            create: (_) => ServiceLocationFormController(
              repository: locationRepository,
              customerId: customerId,
              locationId: locationId,
              initial: initial,
            ),
            dispose: (controller) => controller.dispose(),
          ),
        ],
        child: ServiceLocationFormPage(
          onSaved: () {
            Navigator.of(context).pop();
            onSaved?.call();
          },
        ),
      ),
    );
  }

  void _push(BuildContext context, Route<void> route) {
    // ignore: discarded_futures
    Navigator.of(context).push(route);
  }
}
