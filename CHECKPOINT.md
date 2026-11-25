# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, kortex_lib (pub.dev), SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-25)
- **Git local**: `main`, árvore limpa, sem divergência com `origin/main`; HEAD `ce20712`. Esta checagem local não confirma sincronização com Gitea/GitHub nem CI para este HEAD.
- **Arquitetura & Shell**: `AppServices` composition root puro de infraestrutura/hardware; rotas em `lib/app/routes/app_pages.dart` com bindings por módulo (`*Routes.fromDatabase`).
- **Evolução Recente Concluída**:
  - `Settings`: Persistência corrigida com `ConflictAlgorithm.replace` no SQLite; suporte às configurações de jornada (`schedule_day_start`, `schedule_day_end`, `schedule_slot_interval`).
  - `Formulários & Máscaras`: Formatação ao digitar via `kortex_lib/brlib` em clientes (CPF/CNPJ e WhatsApp), locais (CEP) e OS (moeda R$, data dd/MM/yyyy e combobox de horários de 30 em 30 min).
  - `Agenda (Schedule)`: Calendário mensal full-screen com navegação 2D (meses na horizontal, anos na vertical); Agenda Diária (`ScheduleDayPage`) com timeline vertical, ocupação visual de tempo e navegação para detalhes/novo agendamento.
- **Laudos (EPIC-05)**: gerador PDF em isolate, preview, adaptador de compartilhamento e cache local por OS já existem com testes de módulo. Ainda falta integrar `ReportsRoutes`/`onReport` em `AppPages`, mapear dados reais para `ReportData` e criar uma tela de histórico; ver [status detalhado](docs/plan/epics/epic-05-laudo-pdf-share.md).
- **Suíte & Qualidade**:
  - Última evidência registrada no checkpoint: `flutter analyze --fatal-infos` sem issues e `flutter test` com 296/296 testes verdes. Essa execução não foi repetida nesta atualização documental.
- **Travas Vivas & Governança**:
  - Governança de personas estrita: Orquestrador reivindica claims; Coder TDD Red-Before-Green; Reviewer Gate 3; Gate 4 antes de commit.
  - Push somente sob autorização expressa do usuário.

## Próximo Passo Acionável
1. Integrar o módulo de laudos ao fluxo de OS, montar `ReportData` com dados reais e implementar o histórico visual (EPIC-05).
2. Validação visual e testes E2E adicionais nas novas telas de agenda se solicitado.
