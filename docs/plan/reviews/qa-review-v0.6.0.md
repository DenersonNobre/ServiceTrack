# QA Review — v0.6.0

> **Data**: 2026-11-21  
> **Commit funcional**: `bfed04a` — `feat(auth): add pin recovery flow for UC-01.04`  
> **Commit auditado (HEAD)**: `bac9c9e` — `fix(auth): enforce 48dp touch targets on recovery back/cancel buttons`  
> **Escopo**: UC-01.04 — Recuperação de Acesso Local & Fallback do SO  
> **Gate 2.5**: INVOKED/APROVADO condicionado (`ses_e01c667aeffeUPm0QH2zv7meTP`) — A1-A5 aplicados  
> **Gate 3**: APROVADO Alta (`ses_e01b5dbc1ffexCemgZkXD5qVGx`, rejeição inicial por 48dp; re-review `ses_e01b016f4ffe8jSvhfiKqnDGJS` aprovado após `bac9c9e`)  
> **Gate 4**: APROVADO Alta (`ses_e01b5dbc1ffd7EwiXQw5Yp3Mxk` em `bfed04a`; rerun `ses_e01b016f4ffdhPOP4ULedX6gSz` em `bac9c9e`)

## Evidência empírica (rerun Gate 4, HEAD bac9c9e)

| Comando | Resultado | Evidência |
|---|---|---|
| `flutter test` | PASSOU | `01:04 +65: All tests passed!` (exit 0) |
| `flutter analyze --fatal-infos` | PASSOU | `No issues found! (ran in 10.9s)` (exit 0) |

## Rastreabilidade UC-01.04 (Gherkin `epic-01-auth-perfil.md:165-174`)

| Cenário | Resultado esperado | Cobertura | Resultado |
|---|---|---|---|
| `SENHA_MESTRE_VALIDA` | Permite recadastrar novo PIN sem apagar histórico de OSs | `pin_recovery_test.dart`, `pin_recovery_uc0104_test.dart`, `credential_recovery_test.dart` (reset preserva userId/passwordHash) | PASSOU |
| `BIOMETRIA_OU_PADRAO_DO_SISTEMA_OPERACIONAL` | Permite recadastrar novo PIN sem apagar histórico de OSs | `pin_recovery_test.dart`, `pin_recovery_uc0104_test.dart`, `authenticateDeviceCredential` fail-closed | PASSOU |

## Conformidade segurança (Gate 2.5)

- **A1**: `verifyPassword` com rate-limit/backoff persistido (`ERR_SENHA_BLOQUEADA_TEMPORARIAMENTE`), expiração coberta.
- **A2/A5**: `resetPin` dedicado altera apenas PIN+lockout PIN; preserva `userId`/`passwordHash`; sem `clearAll`/`saveCredentials`.
- **A3**: `authenticateDeviceCredential()` separado (`biometricOnly:false`), fail-closed.
- **A4**: controller/use case gateiam reset sem bypass UI; device credential falha -> `ERR_RECUPERACAO_NAO_AUTORIZADA`.

## Observações (não bloqueantes)

- **A1**: `ERR_RECUPERACAO_NAO_AUTORIZADA` ausente da taxonomia SPEC §6.
- **A2**: Fixture `docs/plan/fixtures/uc-01-04-recovery.json` referenciada no épico não existe.
- **A3**: Preservação de “histórico de OSs” evidenciada indiretamente (sem tabela OS no slice; resetPin não toca DB).

## Parecer

**Aprovado com confiança Alta.** UC-01.04 consolidado. 65/65 testes, analyze limpo, Gherkin coberto, A1-A5 aplicados, fix de 48dp verificado.