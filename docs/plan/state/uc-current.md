# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-02.01` (Cadastro e Edição de Cliente com Validação `brlib`)
- **Status**: 🟡 Em Progresso (Gate 3/4 pendentes)
- **Agente Responsável**: `opc01@e03ff640`
- **Épico**: `EPIC-02`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: Módulo `customers` com domain VOs/entity (Customer, CustomerName, BrazilianDocument CPF/CNPJ, CustomerPhone, CustomerEmail), port repo, SQLite repo+migration, UI list/form com Kortex, wiring no app/home e DB app. Validação brlib para documento e WhatsApp.
- **Gate 2.5 (Segurança)**: PULADO — CRUD local sem nova superfície sensível além de PII local já padrão do projeto; sem nova dependência, sem auth/sessão/upload/webhook/shell. Dados persistidos em SQLite local.
- **Gates 3/4**: pendentes.

## Evidência
- `flutter test` → **82/82 All tests passed**. `flutter analyze --fatal-infos` → **No issues found**.
- RED comprovado: `customer_test.dart` falhou por símbolos ausentes.
- Cobertura: domínio (CPF válido/inválido/sem doc), SQLite save/findAll, UI form salva cliente.

## Arquivos do slice
- `lib/app/database/app_database.dart`, `lib/main.dart`
- `lib/modules/customers/**`
- `test/modules/customers/**`
- `docs/plan/state/UC-CURRENT.md`

## Próximo passo
1. Gate 3 (review).
2. Gate 4 (QA) + laudo.
3. Consolidação e release claim UC-02.01.