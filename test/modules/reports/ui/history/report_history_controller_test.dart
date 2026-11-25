import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/kortex_lib.dart';
import 'package:service_track/modules/reports/domain/models/report_history_item.dart';
import 'package:service_track/modules/reports/ui/history/report_history_controller.dart';

void main() {
  group('ReportHistoryController', () {
    test('carrega histórico concluído com sucesso', () async {
      final items = [
        const ReportHistoryItem(
          workOrderId: 'OS-2',
          serviceDescription: 'Manutenção',
          scheduledDateFormatted: '25/11/2026 10:00',
          completedDateFormatted: '25/11/2026 11:00',
          customerName: 'Cliente B',
          status: 'COMPLETED',
        ),
        const ReportHistoryItem(
          workOrderId: 'OS-1',
          serviceDescription: 'Instalação',
          scheduledDateFormatted: '24/11/2026 09:00',
          completedDateFormatted: '24/11/2026 10:00',
          customerName: 'Cliente A',
          status: 'COMPLETED',
        ),
      ];
      var calls = 0;
      final controller = ReportHistoryController(
        loadHistory: () async {
          calls++;
          return Success(items);
        },
      );

      expect(controller.loading.value, isTrue);
      expect(controller.items.value, isEmpty);
      expect(controller.error.value, isNull);

      await controller.load();

      expect(calls, 1);
      expect(controller.loading.value, isFalse);
      expect(controller.error.value, isNull);
      expect(controller.items.value, hasLength(2));
      expect(controller.items.value.first.workOrderId, 'OS-2');

      controller.dispose();
    });

    test('expõe lista vazia quando não há laudos elegíveis', () async {
      final controller = ReportHistoryController(
        loadHistory: () async =>
            const Success<List<ReportHistoryItem>, ValidationError>([]),
      );

      await controller.load();

      expect(controller.loading.value, isFalse);
      expect(controller.error.value, isNull);
      expect(controller.items.value, isEmpty);

      controller.dispose();
    });

    test('expõe erro amigável quando loader falha', () async {
      final controller = ReportHistoryController(
        loadHistory: () async => const Failure(
          ValidationError(
            code: 'REPORT_HISTORY_LOAD_FAILED',
            message: 'Não foi possível carregar o histórico de laudos.',
          ),
        ),
      );

      await controller.load();

      expect(controller.loading.value, isFalse);
      expect(controller.items.value, isEmpty);
      expect(controller.error.value, 'Não foi possível carregar o histórico de laudos.');

      controller.dispose();
    });

    test('ensureLoaded carrega apenas uma vez', () async {
      var calls = 0;
      final controller = ReportHistoryController(
        loadHistory: () async {
          calls++;
          return const Success<List<ReportHistoryItem>, ValidationError>([]);
        },
      );

      await controller.ensureLoaded();
      await controller.ensureLoaded();

      expect(calls, 1);

      controller.dispose();
    });
  });
}
