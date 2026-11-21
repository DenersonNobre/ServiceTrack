# UC-CURRENT — UC-01.01 Onboarding Inicial & Registro de Credenciais

> Hand-off por UC (ponteiro vivo, detalhe abaixo do CHECKPOINT).

## Status
- **UC**: `UC-01.01` | **Épico**: EPIC-01 | **Owner**: `opc01@e03ff640`
- **Fase**: TASK-01/02/03 consolidadas. Gate 3 APROVADO (Alta, `ses_e02174665ffeDHfacAcd0q5HLu`) e Gate 4 APROVADO (Alta, `ses_e02154301ffeeDmsU19zDVzzWY`). Laudo `docs/plan/reviews/qa-review-v0.3.0.md`. Gate 2.5: PULADO (TASK-03 sem superfície nova; TASK-02 INVOKED — ver seção).
- **Claim**: `UC-01.01` ativo (lib/modules/auth/, test/, docs/plan/state/UC-CURRENT.md).

## Gate 2.5 (Segurança)
Gate 2.5: INVOKED — REPROVADO o esquema literal (C1: PIN com SHA-256 1 iteração é força-brutável; exigir PBKDF2-HMAC-SHA-256 p/ senha E PIN — INV-SEC-01). Condicionantes altas: A1 crypto direta pinada + lock (INV-SEC-02); A2 rate-limit persistente c/ bloqueio (INV-SEC-03); A3 comparação tempo-constante (INV-SEC-04). Médias: M1/M2 flags e user_id fora do cofre, flag nunca é prova de posse (INV-SEC-05); M3 sem segredo/PII em log + teste negativo (INV-SEC-06); M4 sem backup/sync do cofre (INV-SEC-07); M5 root = perda assumida (INV-SEC-08); M6 porta IAuthCredentialRepositoryPort + ERR_AUTH_* (SPEC atualizada). Baixa: B1 piso 8 chars aceito. Não auditado: CVEs (`pub audit` inexistente na toolchain + offline). Confiança: Alta. PO aprovou desvio do épico em 2026-11-21.

## Evidência (TASK-03)
- **Leitura**: `DESIGN.md` (Deep Petrol Green `#115E59`, alvos >=48dp, superfície `#FBF9F5`); ref estrutural canônica `kortex/poc/lib` (app/core/modules, domain/data/commands/features/ui).
- **Verificação (Red)**: `flutter test test/modules/auth/ui/onboarding_page_test.dart` → exit 1 (símbolos `OnboardingPage`/`OnboardingController` ausentes).
- **Confirmação (Green)**: `flutter test` → `All tests passed!` (33/33); `flutter analyze --fatal-infos` → `No issues found!`.
- **Migração estrutural**: `infrastructure/credential_store` → `data/credential_store`, `presentation/onboarding` → `ui/onboarding`, tokens em `lib/app/theme/app_colors.dart`, `main.dart` com injeção de repositório.
- **Gate 3**: APROVADO / Alta (`ses_e02174665ffeDHfacAcd0q5HLu`) — diff budget, DIP/Kortex/tokens/48dp, sem PII. Obs. baixas: gap semântico nome/e-mail vs persistência; 48dp explícito só no campo nome.
- **Gate 4**: APROVADO / Alta (`ses_e02154301ffeeDmsU19zDVzzWY`) — `flutter analyze --fatal-infos` No issues found (26.8s); `flutter test --reporter compact` 33/33 All tests passed; laudo `docs/plan/reviews/qa-review-v0.3.0.md`.

## Evidência (TASK-02)
- **Leitura**: `secure_credential_store.dart` + `credential_kdf.dart` + `flutter_secure_storage_backend.dart` (oráculo da API: cache Puro `flutter_secure_storage-9.2.4`, `platform_interface-1.1.2`).
- **Verificação (Red)**: `flutter test test/secure_credential_store_test.dart` → exit 1 (símbolos ausentes); 1ª GREEN parcial 12/13 — `StateError` (Error, não Exception) escapou do `on Exception`: dublê corrigido para `Exception` (fiel a `PlatformException` real).
- **Confirmação (Green)**: `flutter test` → `All tests passed!` (30/30: 15 VOs + 14 cofre + 1 smoke); `flutter analyze --fatal-infos` → `No issues found!`.
- **Gate 3**: Aprovado com confiança Alta — advisory UTF-8 corrigido em `20837d1`; risco `verifyPassword` sem rate-limit registrado (D-03).
- **Gate 4**: APROVADO (Alta) — laudo `docs/plan/reviews/qa-review-v0.2.0.md`.
- **Dependência**: `crypto: ^3.0.8` declarada direta, lock `transitive` → `"direct main"` via `flutter pub get --offline` (INV-SEC-02).
- **Dívidas descobertas (fora do slice, registrar em DEBITOS)**: (a) sem runners nativos (`android/`, `ios/` ausentes) — verificação de `allowBackup` e build em aparelho pendentes de scaffolding de plataforma; (b) `pub audit`/CVE sem toolchain (`audit` inexistente no Dart 3.13.5) + offline; (c) flags UX (`biometrics_enabled`, `remember_me`) e `user_id` ainda sem casa definitiva (INV-SEC-05: fora do cofre).

## Evidência (TASK-01)
- **Leitura**: `docs/plan/epics/epic-01-auth-perfil.md:57-93` → Gherkin UC-01.01 + 3 tasks.
- **Verificação (Red)**: `flutter test test/auth_credentials_test.dart` → exit 1 (`Undefined name 'SecurityPin'`).
- **Confirmação (Green)**: `flutter test test/auth_credentials_test.dart` → `All tests passed!` (15/15 no arquivo); `flutter test` (suíte) → `All tests passed!` (16/16 com o smoke); `flutter analyze --fatal-infos` → `No issues found!`.
- **Gate 3**: Aprovado com confiança Média (`ses_e03fa8903ffei3Nm02Hcu88hDT`) — sem defeito de código/escopo; ressalva documental sanada nesta revisão (contagem por escopo explicitada).

## Arquivos do slice
- `lib/app/theme/app_colors.dart`, `lib/main.dart`
- `lib/modules/auth/domain/{value_objects,ports,security}/*`
- `lib/modules/auth/data/credential_store/*` (migrou de infrastructure/)
- `lib/modules/auth/ui/onboarding/{onboarding_controller,onboarding_page}.dart`
- `test/{auth_credentials_test,secure_credential_store_test,smoke_test}.dart`, `test/helpers/fake_secure_backend.dart`, `test/modules/auth/ui/onboarding_page_test.dart`
- `docs/plan/state/UC-CURRENT.md`, `docs/plan/reviews/qa-review-v0.3.0.md`, `docs/architecture/SPEC.md`, `docs/plan/epics/epic-01-auth-perfil.md`

## Próximo passo
1. Liberar claim `UC-01.01` (commit de consolidação feito).
2. Iniciar **UC-01.02** (Autenticação por Biometria / "Lembrar de Mim") — novo claim, TDD, avaliar Gate 2.5 (superfície `local_auth`/biometria).
