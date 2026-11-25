// E2E de device do EPIC-04: onboarding -> cliente -> OS -> checklist -> conclusão.
//
// SRP: dirigir o app REAL (SQLite/prefs/plugins nativos) pelo fluxo ponta a ponta
// que o EPIC-04 declara entregue e falhar se qualquer elo não existir de fato.
// Não valida regra de negócio (isso é da suíte de unidade) e não usa screenshot:
// cada passo termina em asserção computada.
//
// Pré-requisito — estado limpo entre execuções (rota inicial depende do banco):
//   adb -s <device> shell pm clear com.servicetrack.service_track
//
// Rodar:
//   flutter test integration_test/epic04_flow.dart -d <device>
//
// Fica fora do glob de `flutter test` (sem sufixo `_test`) para o gate headless
// não tentar rodar um E2E sem plugin nativo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:service_track/main.dart' as app;
import 'package:service_track/modules/checklists/domain/entities/checklist_answer.dart';
import 'package:service_track/modules/checklists/ui/execution/checklist_item_widget.dart';
import 'package:service_track/modules/customers/ui/list/customer_list_page.dart';
import 'package:signature/signature.dart';

const _cliente = 'Cliente E2E';
const _descricao = 'Instalacao split E2E';
const _modelo = 'Instalação Split';
const _senhaMestre = 'SenhaMestre#2026';
const _pin = '4821';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EPIC-04: onboarding, cliente, OS, checklist e conclusão', (
    tester,
  ) async {
    app.main();
    await esperarPor(
      tester,
      _chave('onboarding-submit'),
      limite: const Duration(seconds: 90),
    );

    // 1. Onboarding: cria credenciais locais e cai na home.
    await preencher(tester, 'onboarding-name', 'Tecnico E2E');
    await preencher(
      tester,
      'onboarding-email',
      'tecnico.e2e@servicetrack.local',
    );
    await preencher(tester, 'onboarding-password', _senhaMestre);
    await preencher(tester, 'onboarding-pin', _pin);
    await tocar(tester, _chave('onboarding-submit'));
    await esperarPor(
      tester,
      _chave('home-new-work-order'),
      limite: const Duration(seconds: 90),
    );

    // 2. Cliente com WhatsApp válido (a VO rejeita shape inválido).
    await abrirDrawerETocar(tester, 'drawer-customers');
    await esperarPor(
      tester,
      find.byType(CustomerListPage),
      limite: const Duration(seconds: 60),
    );
    await tocar(tester, _chave('customer-add'));
    await esperarPor(tester, _chave('customer-name'));
    await preencher(tester, 'customer-name', _cliente);
    await preencher(tester, 'customer-whatsapp', '38999990000');
    await tocar(tester, _chave('customer-save'));
    await esperarPor(tester, find.text(_cliente));
    await voltar(tester);

    // 3. OS amarrada ao cliente e a um modelo de checklist (política exige).
    await esperarPor(
      tester,
      _chave('home-new-work-order'),
      limite: const Duration(seconds: 60),
    );
    await abrirDrawerETocar(tester, 'drawer-work-orders');
    await esperarPor(tester, _chave('wo-add'));
    await tocar(tester, _chave('wo-add'));
    await esperarPor(
      tester,
      _chave('wo-customer'),
      limite: const Duration(seconds: 60),
    );

    await tocar(tester, _chave('wo-customer'));
    await esperarPor(tester, find.text(_cliente));
    await tocar(tester, find.text(_cliente).last);

    await tocar(tester, _chave('wo-checklist-template'));
    await esperarPor(tester, find.text(_modelo));
    await tocar(tester, find.text(_modelo).last);

    await preencher(tester, 'wo-description', _descricao);
    await tocar(tester, _chave('wo-save'));
    await esperarPor(tester, find.text(_descricao));

    // 4. Check-in: GPS real, sem bypass (o bypass abriria diálogo e falharia aqui).
    await tocar(tester, _acoesDe(_descricao));
    await esperarPor(tester, find.text('Iniciar atendimento'));
    await tocar(tester, find.text('Iniciar atendimento').last);
    await esperarPor(
      tester,
      find.textContaining('IN_PROGRESS'),
      limite: const Duration(seconds: 90),
    );

    // 5. Checklist: responde todos os itens e confere a persistência.
    await tocar(tester, _acoesDe(_descricao));
    await esperarPor(tester, find.text('Checklist'));
    await tocar(tester, find.text('Checklist').last);
    await esperarPor(
      tester,
      find.byType(ChecklistItemWidget),
      limite: const Duration(seconds: 60),
    );

    final itens = tester
        .widgetList<ChecklistItemWidget>(find.byType(ChecklistItemWidget))
        .length;
    expect(
      itens,
      3,
      reason:
          'modelo "$_modelo" deve renderizar 3 itens. tela: ${tela(tester)}',
    );

    for (var i = 0; i < itens; i++) {
      await tocar(
        tester,
        find.descendant(
          of: find.byType(ChecklistItemWidget).at(i),
          matching: _chave('checklist-btn-conforme'),
        ),
      );
      await esperarConforme(tester, i);
    }

    final respondidos = tester
        .widgetList<ChecklistItemWidget>(find.byType(ChecklistItemWidget))
        .toList();
    for (final item in respondidos) {
      expect(
        item.selectedStatus,
        ChecklistAnswerStatus.conforme,
        reason: 'item "${item.title}" não persistiu como conforme',
      );
    }

    await voltar(tester);
    await esperarPor(tester, find.textContaining('IN_PROGRESS'));

    // 6. Conclusão: assinatura + GPS de check-out (sem bypass).
    await tocar(tester, _acoesDe(_descricao));
    await esperarPor(tester, find.text('Concluir OS'));
    await tocar(tester, find.text('Concluir OS').last);
    await esperarPor(tester, _chave('wo-complete-name'));
    await preencher(tester, 'wo-complete-name', 'Recebedor E2E');
    await assinar(tester);
    await tocar(tester, _chave('wo-complete-confirm'));
    await esperarPor(
      tester,
      find.textContaining('COMPLETED'),
      limite: const Duration(seconds: 120),
    );

    expect(tester.takeException(), isNull);
  });
}

/// Aguarda um finder existir, bombeando frames por tempo real.
///
/// Não usa `pumpAndSettle` porque um spinner contínuo (boot, check-in) nunca
/// "assenta" e o teste morreria no timeout sem dizer em que tela parou.
/// O heartbeat via `debugPrint` aparece no logcat: se o host perder a conexão
/// com o device, o logcat ainda diz até onde o device chegou.
Future<void> esperarPor(
  WidgetTester tester,
  Finder alvo, {
  Duration limite = const Duration(seconds: 30),
}) async {
  debugPrint('[E2E] esperarPor $alvo (limite ${limite.inSeconds}s)');
  final fim = DateTime.now().add(limite);
  var ultimoBeat = DateTime.now();
  while (DateTime.now().isBefore(fim)) {
    if (alvo.evaluate().isNotEmpty) {
      debugPrint('[E2E] OK $alvo');
      return;
    }
    if (DateTime.now().difference(ultimoBeat).inSeconds >= 10) {
      ultimoBeat = DateTime.now();
      debugPrint('[E2E] ... aguardando $alvo. tela: ${tela(tester)}');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  debugPrint('[E2E] TIMEOUT $alvo. tela: ${tela(tester)}');
  fail(
    'timeout de ${limite.inSeconds}s esperando $alvo. tela: ${tela(tester)}',
  );
}

/// Aguarda o item de checklist no índice [index] persistir como [conforme].
///
/// Polling por tempo real (wall-clock + pump 100ms), como [esperarPor]:
/// o save é I/O real no SQLite e um único pump fixo não garante conclusão.
/// Retenta o tap uma vez após 5s se o status ainda for null (hit-test miss).
Future<void> esperarConforme(
  WidgetTester tester,
  int index, {
  Duration limite = const Duration(seconds: 30),
}) async {
  debugPrint(
    '[E2E] esperarConforme index=$index (limite ${limite.inSeconds}s)',
  );
  final inicio = DateTime.now();
  final fim = inicio.add(limite);
  var ultimoBeat = inicio;
  var retapFeito = false;
  while (DateTime.now().isBefore(fim)) {
    final widgets = tester
        .widgetList<ChecklistItemWidget>(find.byType(ChecklistItemWidget))
        .toList();
    if (index < widgets.length &&
        widgets[index].selectedStatus == ChecklistAnswerStatus.conforme) {
      debugPrint(
        '[E2E] OK conforme index=$index "${widgets[index].title}"',
      );
      return;
    }
    final atualStatus =
        index < widgets.length ? widgets[index].selectedStatus : null;
    if (!retapFeito &&
        atualStatus == null &&
        DateTime.now().difference(inicio).inSeconds >= 5) {
      retapFeito = true;
      debugPrint(
        '[E2E] retap conforme index=$index (status ainda null após 5s)',
      );
      final alvo = find.descendant(
        of: find.byType(ChecklistItemWidget).at(index),
        matching: _chave('checklist-btn-conforme'),
      );
      if (alvo.evaluate().isNotEmpty) {
        await tester.ensureVisible(alvo);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(alvo, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 400));
      }
    }
    if (DateTime.now().difference(ultimoBeat).inSeconds >= 10) {
      ultimoBeat = DateTime.now();
      final atual = index < widgets.length
          ? '${widgets[index].selectedStatus} "${widgets[index].title}"'
          : 'index fora de alcance (${widgets.length} widgets)';
      debugPrint(
        '[E2E] ... aguardando conforme index=$index ($atual). '
        'tela: ${tela(tester)}',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  final widgets = tester
      .widgetList<ChecklistItemWidget>(find.byType(ChecklistItemWidget))
      .toList();
  final atual = index < widgets.length
      ? '${widgets[index].selectedStatus} "${widgets[index].title}"'
      : 'index fora de alcance (${widgets.length} widgets)';
  debugPrint(
    '[E2E] TIMEOUT conforme index=$index ($atual). tela: ${tela(tester)}',
  );
  fail(
    'timeout de ${limite.inSeconds}s esperando item $index conforme '
    '(atual: $atual). tela: ${tela(tester)}',
  );
}

/// Toque com o foco fechado: o teclado virtual desloca o alvo em device real.
///
/// Fecha o teclado e espera a animação de dismiss terminar antes de mirar:
/// sem isso o tap cai na coordenada deslocada e acerta outro widget (ou nada).
Future<void> tocar(WidgetTester tester, Finder alvo) async {
  FocusManager.instance.primaryFocus?.unfocus();
  try {
    await tester.pumpAndSettle(const Duration(seconds: 2));
  } on FlutterError catch (e) {
    debugPrint('[E2E] settle interrompido (animação contínua?), segue: $e');
    await tester.pump(const Duration(milliseconds: 500));
  }
  if (alvo.evaluate().isEmpty) {
    debugPrint('[E2E] alvo sumiu após fechar o teclado: $alvo');
  }
  await tester.ensureVisible(alvo);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(alvo);
  await tester.pump(const Duration(milliseconds: 400));
}

/// Digita sem exigir que o campo esteja visível (o page é um scroll único).
Future<void> preencher(WidgetTester tester, String chave, String valor) async {
  await tester.enterText(_chave(chave), valor);
  await tester.pump(const Duration(milliseconds: 200));
}

/// Volta pelo tipo: `pageBack()` procura o tooltip "Back" e quebra em pt-BR.
Future<void> voltar(WidgetTester tester) async {
  final botao = find.byType(BackButton);
  expect(
    botao,
    findsWidgets,
    reason: 'AppBar deveria ter botão de voltar. tela: ${tela(tester)}',
  );
  await tester.tap(botao.first);
  await tester.pump(const Duration(milliseconds: 500));
}

/// Abre o drawer da Home e toca no item identificado pela chave.
///
/// Usa `ScaffoldState.openDrawer()` para evitar dependência de tooltip/localização
/// do botão hambúrguer. O drawer fecha ao navegar (`_navigate` faz pop + action).
Future<void> abrirDrawerETocar(WidgetTester tester, String chave) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 200));
  final scaffoldFinder = find.byWidgetPredicate(
    (w) => w is Scaffold && w.drawer != null,
  );
  await esperarPor(
    tester,
    scaffoldFinder,
    limite: const Duration(seconds: 30),
  );
  tester.state<ScaffoldState>(scaffoldFinder.first).openDrawer();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await esperarPor(tester, _chave(chave));
  await tocar(tester, _chave(chave));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Traço no canvas de assinatura (a conclusão rejeita assinatura vazia).
Future<void> assinar(WidgetTester tester) async {
  final canvas = find.byType(Signature);
  await tester.ensureVisible(canvas);
  await tester.pump(const Duration(milliseconds: 300));
  final centro = tester.getCenter(canvas);
  final gesto = await tester.startGesture(centro - const Offset(40, 0));
  for (var i = 0; i < 8; i++) {
    await gesto.moveBy(const Offset(10, 6));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesto.up();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Menu de ações da linha da OS identificada pela descrição.
Finder _acoesDe(String descricao) {
  final linha = find
      .ancestor(of: find.text(descricao), matching: find.byType(ListTile))
      .first;
  return find.descendant(
    of: linha,
    matching: find.byType(PopupMenuButton<String>),
  );
}

Finder _chave(String valor) => find.byKey(Key(valor));

/// Texto visível — vai no `reason` para a falha dizer onde o fluxo parou.
String tela(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data)
    .whereType<String>()
    .join(' | ');
