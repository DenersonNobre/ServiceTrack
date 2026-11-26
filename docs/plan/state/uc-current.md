# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-08.04` — Rate-limit de Credencial & Auditoria CVE
- **UC**: `UC-08.04`
- **Status**: `CONCLUÍDO (local; CI security-audit pendente no push)`
- **Dono**: `cod01@local001`
- **Épico**: `EPIC-08`
- **Gate 2.5 (Segurança)**: INVOKED — superfície auth/dependências: D-03 verificado por evidência (sem nova superfície de auth); D-02 adiciona workflow CI com instalação de osv-scanner e leitura de `pubspec.lock` (sem segredos, sem execução de código de dependência). Sem PII nova.
- **Última Atualização**: `2026-11-25`

## Contexto Atual
- **D-03 fechado por evidência**: `SecureCredentialStore.verifyPassword` já possui lockout/backoff exponencial (`passwordFailCountKey`, `passwordLockedUntilKey`, `maxAttempts`, `baseLockout`, `maxLockout`), limpa contadores em sucesso. Evidência: `lib/modules/auth/data/credential_store/secure_credential_store.dart`, `test/modules/auth/data/credential_recovery_test.dart` (`verifyPassword aplica rate-limit/backoff (A1)`, `lockout de senha expira (A1)`). `docs/DEBITOS.md` atualizado para Mitigado.
- **D-02 mitigado com rotina reproduzível**: `scripts/ci/security-audit.sh` (falha se `flutter pub outdated --json` sinalizar `isCurrentAffectedByAdvisory=true`; roda `osv-scanner` sobre `pubspec.lock` quando disponível; `REQUIRE_OSV_SCANNER=1` no CI). Workflow `.github/workflows/security-audit.yml` (push/PR/schedule/dispatch) instala osv-scanner e executa a rotina.
- **Verificação local**: `flutter analyze --fatal-infos` = No issues found; `flutter test` = **314/314 passed**; `flutter pub outdated --json` sem advisory atual.

## [EVIDENCIA]
- Leitura: `lib/modules/auth/data/credential_store/secure_credential_store.dart:57-60,190-230,424-447` → lockout/backoff de senha presente.
- Verificação: `dart pub audit` indisponível no Dart 3.13.5 (confirmado); `flutter pub outdated --json` sem `isCurrentAffectedByAdvisory=true`.
- Confirmação: `flutter analyze --fatal-infos` → No issues found; `flutter test` → 314/314 passed.

## Próximo passo
1. Commit atômico UC-08.04 + release claim.
2. Push com autorização explícita do PO + acompanhar CI (inclui `Security Audit`).
3. Priorizar próximo slice EPIC-08 (UC-08.01/08.02/08.03).

## Travas Vivas
- **Claims**: sem claim ativo.
- **Push**: somente com autorização explícita do PO + 3 evidências.
- **D-01/C-01 residual**: LGPD formal/full-db/iOS pendentes (EPIC-08).
