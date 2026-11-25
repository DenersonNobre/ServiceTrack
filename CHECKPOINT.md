# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, kortex_lib (pub.dev), SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-25)
- **Git local**: `main`; HEAD `2cc9d2a` sincronizado com `origin/main` (checagem local; não confirma CI).
- **Arquitetura & Shell**: `AppServices` composition root puro de infraestrutura/hardware; rotas em `lib/app/routes/app_pages.dart` com bindings por módulo (`*Routes.fromDatabase`).
- **Evolução Recente Concluída**:
  - `Settings`: persistência SQLite com `ConflictAlgorithm.replace`; jornada (`schedule_day_start/end/slot_interval`).
  - `Formulários & Máscaras`: `kortex_lib/brlib` em clientes (CPF/CNPJ, WhatsApp), locais (CEP) e OS (moeda R$, data dd/MM/yyyy, horários 30 min).
  - `Agenda (Schedule)`: calendário mensal 2D + agenda diária com timeline/ocupação e navegação para detalhe/novo agendamento.
- **EPIC-04 E2E (device M2010J19CG, Android 10)**: navegação home→clientes/OS destravada; espera de persistência do checklist trocada para wall-clock (`esperarConforme`). `flutter analyze`/296 testes verdes; revalidação E2E em device pendente.
- **Laudos (EPIC-05)**: gerador PDF/isolate, preview, share adapter e cache local por OS existem com testes; falta integrar `ReportsRoutes`/`onReport`, mapear `ReportData` real e histórico visual. Ver [status](docs/plan/epics/epic-05-laudo-pdf-share.md).
- **Suíte & Qualidade**: `flutter analyze --fatal-infos` limpo; `flutter test` headless 296/296 verdes (2026-11-25).
- **Travas Vivas & Governança**: claims obrigatórios; Coder TDD; Reviewer Gate 3; Gate 4 antes de commit; push só com autorização expressa.

## Próximo Passo Acionável
1. Investigar/fixar falha E2E EPIC-04 no checklist: item "Conferir local e infraestrutura elétrica" não persiste como `conforme` no device (fatia separada, TDD).
2. Integrar módulo de laudos ao fluxo de OS, montar `ReportData` real e histórico visual (EPIC-05).
