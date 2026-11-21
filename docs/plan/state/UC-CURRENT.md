# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-01.04` (Recuperação de Acesso Local & Fallback do SO)
- **Status**: 🟡 Em Progresso (Gate 3/4 pendentes)
- **Agente Responsável**: `opc01@e03ff640`
- **Épico**: `EPIC-01`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: "Esqueci meu PIN" na lock screen; fluxo de recuperação por senha mestre ou credencial do SO (device credential); `resetPin` dedicado preservando senha/identidade/dados; rate-limit/backoff em `verifyPassword` (A1); `authenticateDeviceCredential` separado (A3, fail-closed).
- **Gate 2.5 (Segurança)**: INVOKED — APROVADO condicionado (`ses_e01c667aeffeUPm0QH2zv7meTP`). Mitigações aplicadas: A1 `passwordLockedOut`+backoff persistido; A2 `resetPin` só toca pin hash+lockout PIN; A3 `authenticateDeviceCredential(biometricOnly:false)` separado; A4 estado/use case gateiam reset; A5 sem `clearAll`/`saveCredentials` no reset.
- **Gates 3/4**: pendentes.

## Evidência
- `flutter test` → **65/65 All tests passed**. `flutter analyze --fatal-infos` → **No issues found**.
- Gherkin UC-01.04: SENHA_MESTRE_VALIDA -> recadastra PIN; BIOMETRIA_OU_PADRAO_DO_SISTEMA_OPERACIONAL -> recadastra PIN (testes UI + use case + repo).
- RED comprovado: testes recovery falharam por símbolos ausentes (`resetPin`, `passwordLockedOut`, `PinRecoveryUseCase`).

## Arquivos do slice
- `lib/modules/auth/{data,domain,features,recovery,ui}` (recovery flow, ports, store, biometric adapter)
- `lib/main.dart` (rota recuperação)
- `test/modules/auth/{data/credential_recovery_test.dart,features/pin_recovery_test.dart,ui/pin_recovery_uc0104_test.dart}` + fakes atualizados
- `docs/plan/state/UC-CURRENT.md`

## Próximo passo
1. Gate 3 (review).
2. Gate 4 (QA) + laudo.
3. Consolidação e release claim UC-01.04.
