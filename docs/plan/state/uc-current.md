# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-03.03` (Check-in de Atendimento & Georreferenciamento)
- **Status**: CONCLUIDO (Gates 2.5/3/4)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-03`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: GeoPoint VO, startService com LocationCapture tipada (INV-SEC-17), transição SCHEDULED->IN_PROGRESS (INV-01), ILocationServicePort + adapter geolocator foreground (INV-SEC-19/21), SQLite v4 check-in, UI iniciar atendimento com bypass auditável explícito.
- **Gate 2.5 (Segurança)**: Gate 2.5: INVOKED — APROVADO COM CONDICIONANTES (Média, `ses_dfff9c294ffeKsUX0t27vzhOvX`); INV-SEC-17..21 atendidos. A6/D-02 advisory.
- **Gate 3**: APROVADO Média (`ses_dffe177bdffe0N1BwZgzIjdto3`).
- **Gate 4**: APROVADO COM RESSALVAS Alta (`ses_dffe177bdffdyxYsCRZuI7yspo`) — laudo `docs/plan/reviews/qa-review-v0.14.0.md`.

## [EVIDENCIA]
- Leitura: `docs/plan/epics/epic-03-ordens-servico.md` UC-03.03, `docs/architecture/SPEC.md` INV-01/INV-02/RN-02, Gate 2.5.
- Verifica: `flutter analyze --fatal-infos` -> No issues found (exit 0). `flutter test` completo Gate 4 -> +100 -2 (2 flakies `credential_recovery_test.dart` UC-01.04, fora do slice); rerun isolado `00:30 +4 All tests passed` (exit 0).
- Confirma: RED domain/data tests falharam por símbolos ausentes; após implementação verde.

## Observações (não bloqueantes)
- M1: 2 flakies auth/credential_recovery_test.dart fora do slice (rerun isolado verde).
- A1-A4: cobertura adicional controller/widget/sqlite bypass/adapter recomendada.
- A5: confirmar plugin geolocator sem background contínuo.

## Próximo passo
1. Liberar claim `UC-03.03`.
2. Iniciar **UC-03.04** (Pausa e Cancelamento com Justificativa) com pré-flight, claim, TDD e Gate 2.5 conforme superfície.
