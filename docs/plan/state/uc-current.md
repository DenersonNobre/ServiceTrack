# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-02.01` (Cadastro e Edição de Cliente com Validação `brlib`)
- **Status**: 🟢 Concluído (Gates 2.5/3/4)
- **Agente Responsável**: `opc01@e03ff640`
- **Épico**: `EPIC-02`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: Módulo `customers` com VOs/entity (Customer, CustomerName, BrazilianDocument CPF/CNPJ, CustomerPhone, CustomerEmail), port repo, SQLite repo+migration, UI list/form Kortex, wiring no app/home e DB app. Validação brlib para documento e WhatsApp.
- **Gate 2.5**: PULADO — CRUD local, sem nova superfície sensível além de PII local padrão; sem nova dep; sem auth/sessão/upload/webhook/shell.
- **Gate 3**: APROVADO Alta (re-review `ses_e0145ed3affeVg886ZFzcgDrn9`).
- **Gate 4**: APROVADO COM RESSALVAS Alta (re-QA `ses_e0145ed3affda6s6lEe9yiNk9f`) — laudo `docs/plan/reviews/qa-review-v0.8.0.md`.

## Evidência
- `flutter test` → **82/82 All tests passed**. `flutter analyze --fatal-infos` → **No issues found**.
- Commits: `637456b`, `45fe4aa`.

## Observações (não bloqueantes)
- M1: faltam testes de regressão para caminhos corrigidos em 45fe4aa (edit load null/failure; onSaved single-fire).
- A1: Epic-02 sem Gherkin/fixtures detalhados por UC.
- A2: Sync de edição no form depende de `name/whatsapp` não vazios.

## Próximo passo
1. Liberar claim `UC-02.01`.
2. Iniciar **UC-02.02** (Gestão de Endereços e Locais de Atendimento) com pré-flight, claim, TDD e Gate 2.5 conforme superfície.
