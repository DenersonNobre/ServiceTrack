# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-01.04` (Recuperação de Acesso Local & Fallback do SO)
- **Status**: 🟢 Concluído (Gates 2.5/3/4)
- **Agente Responsável**: `opc01@e03ff640`
- **Épico**: `EPIC-01`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: "Esqueci meu PIN" + recuperação por senha mestre ou credencial do SO; `resetPin` dedicado preservando identidade/senha/dados; rate-limit/backoff `verifyPassword`; `authenticateDeviceCredential` separado fail-closed.
- **Gate 2.5**: INVOKED/APROVADO condicionado (`ses_e01c667aeffeUPm0QH2zv7meTP`), A1-A5 aplicados.
- **Gate 3**: APROVADO Alta (`ses_e01b016f4ffe8jSvhfiKqnDGJS`, após fix 48dp em `bac9c9e`).
- **Gate 4**: APROVADO Alta (`ses_e01b016f4ffdhPOP4ULedX6gSz`) — laudo `docs/plan/reviews/qa-review-v0.6.0.md`.

## Evidência
- `flutter test` → **65/65 All tests passed**. `flutter analyze --fatal-infos` → **No issues found**.
- Gherkin UC-01.04: SENHA_MESTRE_VALIDA e BIOMETRIA_OU_PADRAO_DO_SISTEMA_OPERACIONAL -> recadastra PIN sem apagar histórico.
- Commits: `bfed04a` (feat), `bac9c9e` (fix 48dp).

## Observações (não bloqueantes)
- `ERR_RECUPERACAO_NAO_AUTORIZADA` ausente da SPEC §6.
- Fixture `docs/plan/fixtures/uc-01-04-recovery.json` ausente.
- Preservação de histórico OS evidenciada indiretamente.

## Próximo passo
1. Liberar claim `UC-01.04`.
2. Iniciar **UC-01.05** (Edição de Perfil Comercial do Técnico) com claim, TDD e Gate 2.5 conforme superfície.