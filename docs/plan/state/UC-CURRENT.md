# UC-CURRENT — UC-01.01 Onboarding Inicial & Registro de Credenciais

> Hand-off por UC (ponteiro vivo, detalhe abaixo do CHECKPOINT).

## Status
- **UC**: `UC-01.01` | **Épico**: EPIC-01 | **Owner**: `opc01@e03ff640`
- **Fase**: TASK-01 concluída (Value Objects + testes); TASK-02/03 pendentes.
- **Claim**: `UC-01.01` ativo (lib/modules/auth/, test/, docs/plan/state/UC-CURRENT.md).

## Gate 2.5 (Segurança)
Gate 2.5: PULADO — TASK-01 é validação pura em memória (sem storage, sem sessão, sem dependência nova); TASK-02 (secure_storage) invocará security antes de implementar.

## Evidência (TASK-01)
- **Leitura**: `docs/plan/epics/epic-01-auth-perfil.md:57-93` → Gherkin UC-01.01 + 3 tasks.
- **Verificação (Red)**: `flutter test test/auth_credentials_test.dart` → exit 1 (`Undefined name 'SecurityPin'`).
- **Confirmação (Green)**: `flutter test` → `All tests passed!` (16/16); `flutter analyze --fatal-infos` → `No issues found!`.

## Arquivos do slice
- `lib/modules/auth/domain/value_objects/{technician_name,contact_email,master_password,security_pin,auth_credentials}.dart`
- `test/auth_credentials_test.dart`

## Próximo passo
1. Gate 3 (review do diff vs SPEC).
2. TASK-02: repositório seguro (`flutter_secure_storage`) — invocar Gate 2.5/security antes.
