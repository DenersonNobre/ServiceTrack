# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-01.02` (Autenticação por Biometria / "Lembrar de Mim")
- **Status**: 🟢 Concluído (Gates 2.5/3/4 aprovados)
- **Agente Responsável**: `opc01@e03ff640`
- **Épico**: `EPIC-01`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: Biometria por porta/adapter local_auth, decisão fail-closed, boot gate (onboarding/lock/home), lock screen com PIN manual, sessão lembrada TTL 15min, re-lock background >5min, barrels `.index.dart`.
- **Gate 2.5 (Segurança)**: INVOKED — APROVADO Média (`ses_e0202af3fffeakXmm9SZDvGfxe`), A1-A5 aplicados. INV-SEC-08/09/10 propostas.
- **Gate 3 (Review)**: APROVADO Média (`ses_e01e4bd6cffePhcqTriKO5lbde`).
- **Gate 4 (QA)**: APROVADO Alta (`ses_e01e1ec65ffeZKAYpnSeV16dW5`) — laudo `docs/plan/reviews/qa-review-v0.4.0.md`.

## Evidência
- `flutter test` → **51/51 All tests passed**; `flutter analyze --fatal-infos` → **No issues found**.
- Gherkin UC-01.02: SUCESSO->ENTRADA_DIRETA_HOME, FALHA_LEITURA->SOLICITAR_PIN_MANUAL, CANCELADO->PERMANECER_TELA_PIN.
- Commits: `47c3f01` feat(auth) UC-01.02; `9186d4c` refactor(auth) barrels (reverificado).

## Observações (não bloqueantes)
- markUnlocked Failure ignorado em `_grantAccess`/callback onboarding (A1-QA).
- `_isLockVisible` mutado em build (A2-QA).
- `ValidationError.details` pode carregar `cause.toString()` (A3-QA).
- Toggle "Lembrar de Mim" sem UI (fora do Gherkin) (A4-QA).

## Próximo passo
1. Liberar claim `UC-01.02`.
2. Iniciar **UC-01.03** (Desbloqueio Rápido via Teclado de PIN Numérico) — novo claim, TDD; avaliar Gate 2.5 (superfície auth local/rate-limit já existente).