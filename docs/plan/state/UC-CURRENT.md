# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-01.02` (Autenticação por Biometria / "Lembrar de Mim")
- **Status**: 🟡 Em Progresso (aguardando Gate 3/4)
- **Agente Responsável**: `opc01@e03ff640`
- **Épico**: `EPIC-01`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: UC-01.02 implementado com TDD (biometria por porta/adapter local_auth 2.3.0, decisão fail-closed, boot gate, lock screen com PIN manual, flags biometria/remember-me, sessão lembrada com TTL, re-lock em background >5min).
- **Fase**: Gates 3/4 pendentes.
- **Gate 2.5 (Segurança)**: INVOKED — APROVADO (confiança Média, `ses_e0202af3fffeakXmm9SZDvGfxe`), condicionado a A1-A5. Mitigações aplicadas: A1 TTL 15min + sem bypass permanente (cold start -> lock); A2 `IBiometricAuthPort` + enum tipado + mapeamento `LocalAuthException` fail-closed; A3 re-lock no resume após background >5min; A4 `canAuthenticate()` antes do prompt; A5 boot fail-closed para lock em erro/ambíguo. A6/A7: sem log de segredo, lockfile mantido. INV-SEC propostas: INV-SEC-08/09/10.

## Evidência
- **Baseline**: `flutter test` 33/33 verde antes da UC.
- **RED**: testes novos falharam por símbolos ausentes (`BiometricUnlockUseCase`/`UnlockDecision`/`ResolveInitialRouteUseCase`/`LockController`/`LockPage`).
- **GREEN**: `flutter test` → **51/51 All tests passed**. `flutter analyze --fatal-infos` → **No issues found**.
- **Cobertura Gherkin UC-01.02**: SUCESSO->`grantHome`/onUnlocked; FALHA_LEITURA->PIN manual; CANCELADO->permanece PIN. Fail-closed extra: indisponível/lockout/erro->PIN; biometria desabilitada->PIN; boot erro credenciais->lock.

## Arquivos do slice
- `lib/main.dart`, `lib/app/theme/app_colors.dart`
- `lib/modules/auth/domain/ports/{auth_credential_repository_port,biometric_auth_port}.dart`
- `lib/modules/auth/domain/value_objects/biometric_auth_result.dart`
- `lib/modules/auth/data/biometric/local_auth_biometric_adapter.dart`
- `lib/modules/auth/data/credential_store/secure_credential_store.dart`
- `lib/modules/auth/features/{biometric_unlock,app_entry}/*.dart`
- `lib/modules/auth/ui/{lock,onboarding}/*.dart`
- `test/**` (novos/ajustados), `pubspec.yaml`, `pubspec.lock`, `docs/plan/state/UC-CURRENT.md`

## Próximo passo
1. Gate 3 (review do diff UC-01.02 vs SPEC/DESIGN/Gate 2.5).
2. Gate 4 (QA) + laudo.
3. Consolidação e release claim UC-01.02.