# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-02.02` (Gestão de Endereços e Locais de Atendimento)
- **Status**: EM ANDAMENTO (Gate 3/4 pendentes)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-02`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: ServiceLocation VO/entity (label, endereço, CEP brlib opcional, referência), port repo, SQLite migration v2 + repo, memory repo, UI list/form Kortex, wiring no app/home (acesso por cliente).
- **Gate 2.5 (Segurança)**: PULADO — CRUD local SQLite, PII de endereço local padrão, sem nova dependência/superfície sensível.
- **Gates 3/4**: pendentes.

## [EVIDENCIA]
- Leitura: `docs/plan/epics/epic-02-clientes.md` UC-02.02 e `docs/architecture/SPEC.md` glossário Customer; escopo de locais vinculados a cliente validado.
- Verifica: `flutter test` -> 87/87 All tests passed; `flutter analyze --fatal-infos` -> No issues found.
- Confirma: RED `service_location_test.dart` falhou por símbolo ausente; após implementação domínio/data/UI verdes.

## Arquivos do slice
- `lib/app/database/app_database.dart`, `lib/main.dart`
- `lib/modules/customers/**` (domain/data/ui service_location)
- `test/modules/customers/**`
- `docs/plan/state/uc-current.md`

## Próximo passo
1. Gate 3 (review).
2. Gate 4 (QA) + laudo.
3. Consolidação e release claim UC-02.02.
