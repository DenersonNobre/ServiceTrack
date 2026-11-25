# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, kortex_lib (pub.dev), SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-25)
- **Branch**: `main`; remotos Gitea e GitHub sincronizados em `a4b5cbf` com CI verde no GitHub Actions (run `45536375511`).
- **Arquitetura & Shell**: `AppServices` composition root puro de infraestrutura/hardware; rotas em `lib/app/routes/app_pages.dart` com bindings por módulo (`*Routes.fromDatabase`).
- **Evolução Recente Concluída**:
  - `Settings`: Persistência corrigida com `ConflictAlgorithm.replace` no SQLite; suporte às configurações de jornada (`schedule_day_start`, `schedule_day_end`, `schedule_slot_interval`).
  - `Formulários & Máscaras`: Formatação ao digitar via `kortex_lib/brlib` em clientes (CPF/CNPJ e WhatsApp), locais (CEP) e OS (moeda R$, data dd/MM/yyyy e combobox de horários de 30 em 30 min).
  - `Agenda (Schedule)`: Calendário mensal full-screen com navegação 2D (meses na horizontal, anos na vertical); Agenda Diária (`ScheduleDayPage`) com timeline vertical, ocupação visual de tempo e navegação para detalhes/novo agendamento.
- **Suíte & Qualidade**:
  - `flutter analyze --fatal-infos`: 0 issues.
  - `flutter test`: 296/296 testes verdes (100% passing).
- **Travas Vivas & Governança**:
  - Governança de personas estrita: Orquestrador reivindica claims; Coder TDD Red-Before-Green; Reviewer Gate 3; Gate 4 antes de commit.
  - Push somente sob autorização expressa do usuário.

## Próximo Passo Acionável
1. Iniciar o planejamento e fatiamento do **EPIC-05** (Motor de Laudo PDF & Compartilhamento via WhatsApp).
2. Validação visual e testes E2E adicionais nas novas telas de agenda se solicitado.