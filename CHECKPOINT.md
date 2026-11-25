# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, kortex_lib (pub.dev), SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-25)
- **Git local**: `main`; HEAD `0f34808` (checagem local; não confirma CI). Árvore com alterações locais não commitadas desta fatia (EPIC-05 integração).
- **Arquitetura & Shell**: `AppServices` composition root puro de infraestrutura/hardware; rotas em `lib/app/routes/app_pages.dart` com bindings por módulo (`*Routes.fromDatabase`).
- **Evolução Recente Concluída**:
  - `Settings`: persistência SQLite com `ConflictAlgorithm.replace`; jornada (`schedule_day_start/end/slot_interval`).
  - `Formulários & Máscaras`: `kortex_lib/brlib` em clientes (CPF/CNPJ, WhatsApp), locais (CEP) e OS (moeda R$, data dd/MM/yyyy, horários 30 min).
  - `Agenda (Schedule)`: calendário mensal 2D + agenda diária com timeline/ocupação e navegação para detalhe/novo agendamento.
- **EPIC-04 E2E (device M2010J19CG, Android 10, 2026-11-25)**: **verde** (`01:52 +1: All tests passed`) — onboarding→cliente→OS→check-in IN_PROGRESS→checklist 3/3 conforme→conclusão COMPLETED. Fixes: nav drawer keys, `esperarConforme` wall-clock, `INSERT OR REPLACE` (SQLite 3.22/Android 10), `AlertDialog` content com `SizedBox(width: double.maxFinite)`.
- **EPIC-05 (2026-11-25)**: integração app + histórico visual dedicado implementados. `AppRoutes.reportPreview/reportHistory`, `ReportDataAssembler`, loader por OS, `onReport` em OS concluída, drawer "Histórico de Laudos" (`drawer-report-history`) abrindo preview por `workOrderId`. Cache/regeneração/reabertura por OS concluída. Códigos de carga de laudo/histórico padronizados em `ReportFailureCodes`/SPEC. Testes automatizados do PDF validam `%PDF-` e conteúdo das seções obrigatórias (extração zlib/latin1). **INV-05 validado em device alvo**: `flutter test -d 192.168.67.65:5555 test/modules/reports/data/pdf_report_generator_adapter_test.dart` (M2010J19CG, Android 10 / API 29) **3/3 passed**, incluindo caso 6 fotos com `elapsedMilliseconds < 2000`; ausência de congelamento de UI permanece observação qualitativa. Ver [status](docs/plan/epics/epic-05-laudo-pdf-share.md).
- **Suíte & Qualidade (2026-11-25, evidência local)**: `flutter analyze --fatal-infos` limpo (0 issues). `flutter test` completo: **310/310 passed** (`All tests passed!`). CI verde nos pushes `45679325088`, `45680872412`, `45686528255`.
- **Plano**: `docs/plan/README.md` e `docs/plan/epics/epic-04-checklists-evidencias.md` atualizados para refletir EPIC-05 concluído e EPIC-04 E2E device verde (D-01/C-01 permanece bloqueado por design).
- **Travas Vivas & Governança**: claim ativo `DOC-PLAN-COHERENCE-EPIC04-05` (coder-agent) para higiene documental. Push só com autorização expressa.

## Próximo Passo Acionável
1. Commit atômico da higiene do plano + release claim `DOC-PLAN-COHERENCE-EPIC04-05`.
2. Com autorização explícita do PO: push + CI verde.
3. **Decisão de PO/backlog**: D-01/C-01 (EPIC-04) bloqueado por design; não há EPIC-08 definido no plano — definir próximo épico/prioridade.
