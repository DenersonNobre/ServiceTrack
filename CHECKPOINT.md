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
- **EPIC-05 (integração app, 2026-11-25)**: `AppRoutes.reportPreview`, `ReportsRoutes` com loader por OS, `ReportDataAssembler` puro, `onReport` na lista de OS concluída. Cache/regeneração/reabertura por OS concluída; **histórico visual dedicado e validação de desempenho <2s em device alvo (INV-05) pendentes**. Ver [status](docs/plan/epics/epic-05-laudo-pdf-share.md).
- **Suíte & Qualidade (2026-11-25, evidência local)**: `flutter analyze --fatal-infos` limpo (0 issues). `flutter test` completo: **302/302 passed** (`All tests passed!`), incluindo reports/work_orders e o teste NFR <100ms do `report_storage_adapter` nesta execução.
- **Travas Vivas & Governança**: Gate 3 aprovado com ressalvas (corrigidas) e Gate 4 QA aprovado com ressalvas — laudo `docs/plan/reviews/qa-review-v0.22.0.md`. Claim `UC-05.INTEGRATION` (coder-agent) ativo até commit. Push só com autorização expressa.

## Próximo Passo Acionável
1. Commit atômico da fatia EPIC-05 + release claim `UC-05.INTEGRATION`.
2. UC-05.04 histórico visual dedicado + validação de desempenho/UX do PDF em device alvo (<2s, INV-05).
3. Com autorização explícita do PO: push + CI verde.
