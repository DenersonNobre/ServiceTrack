// Controller do histórico visual de laudos (UC-05.04).
//
// SRP: carregar e expor estado reativo da lista de OS concluídas elegíveis.
// Não acessa SQLite diretamente; recebe loader injetado.

import 'package:kortex_lib/kortex_lib.dart';

import '../../domain/models/report_history_item.dart';

/// Carrega itens do histórico de laudos.
typedef ReportHistoryLoader =
    Future<IResult<List<ReportHistoryItem>, ValidationError>> Function();

/// Controller Kortex para a tela de histórico de laudos.
final class ReportHistoryController extends IKortexController {
  ReportHistoryController({required this.loadHistory});

  final ReportHistoryLoader loadHistory;

  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  final KortexSignal<List<ReportHistoryItem>> items =
      KortexSignal<List<ReportHistoryItem>>(const []);

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    await load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final result = await loadHistory();
    loading.value = false;
    switch (result) {
      case Success<List<ReportHistoryItem>, ValidationError>(:final value):
        items.value = value;
      case Failure<List<ReportHistoryItem>, ValidationError>(:final value):
        error.value = value.message;
        items.value = const [];
    }
  }

  @override
  void onDispose() {
    loading.dispose();
    error.dispose();
    items.dispose();
  }
}
