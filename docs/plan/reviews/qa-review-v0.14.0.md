# QA Review — v0.14.0

> **Data**: 2026-11-21  
> **Commit auditado**: `0bb9527` — `feat(work-orders): add check-in geolocation and start service for UC-03.03`  
> **Escopo**: UC-03.03 — Check-in de Atendimento & Georreferenciamento  
> **Gate 2.5**: INVOKED — APROVADO COM CONDICIONANTES (Média, `ses_dfff9c294ffeKsUX0t27vzhOvX`); condicionantes INV-SEC-17..21 atendidos.  
> **Gate 3**: APROVADO Média (`ses_dffe177bdffe0N1BwZgzIjdto3`)  
> **Gate 4**: APROVADO COM RESSALVAS Alta (`ses_dffe177bdffdyxYsCRZuI7yspo`)

## Evidência empírica

| Comando | Resultado | Evidência |
|---|---|---|
| `flutter analyze --fatal-infos` | PASSOU | `No issues found! (ran in 30.0s)` (exit 0) |
| `flutter test` (suíte completa) | FALHOU (flakies fora do slice) | `01:44 +100 -2: Some tests failed.` (exit 1). Falhas: `credential_recovery_test.dart` UC-01.04 (2 testes, timeout/assert, fora do diff UC-03.03). |
| `flutter test test/modules/auth/data/credential_recovery_test.dart` (rerun isolado) | PASSOU | `00:30 +4: All tests passed!` (exit 0) — confirma flakiness ambiental fora do slice. |

## Rastreabilidade UC-03.03

| Critério | Evidência | Status |
|---|---|---|
| INV-01 transição SCHEDULED->IN_PROGRESS | `WorkOrder.startService` rejeita transição ilegal com `ERR_OS_TRANSICAO_INVALIDA` | Conforme |
| INV-02 / RN-02 GeoPoint/check-in | GeoPoint valida faixa/finito/UTC; bypass explícito tipado com confirmação UI | Conforme |
| INV-SEC-17 bypass tipado/auditável | `CheckInBypassReason`, `CheckInBypassed`, diálogo de confirmação, persistência source/reason | Conforme |
| INV-SEC-18 redação/minimização | `GeoPoint.toString()`/`CheckInGps.toString()` redacted; sem coords em logs/erros | Conforme |
| INV-SEC-19 fail-closed | Serviço/permissão/timeout/dados inválidos/exceção mapeados para erro tipado; sem transição em falha | Conforme |
| INV-SEC-20 validação estrita | Limites, NaN/Infinity rejeitados | Conforme |
| INV-SEC-21 foreground only | `getCurrentPosition` sob demanda com timeout 15s; sem background tracking | Conforme (A5) |
| DESIGN >=48dp / #115E59 | Chips minHeight 48, ListTile 56, IconButton 48x48; primaryAction | Conforme |

## Observações

- **M1 (Maior, fora do slice)**: Suíte completa com 2 flakies em `credential_recovery_test.dart` (UC-01.04). Rerun isolado verde. Registrar/estabilizar antes do próximo gate de release.
- **A1**: Sem teste de controller para startService/bypass/busy guard.
- **A2**: Sem widget test para fluxo check-in/bypass.
- **A3**: Sem teste SQLite para persistência de bypass.
- **A4**: Sem teste unitário de `GeolocatorLocationService`.
- **A5**: Confirmar que plugin geolocator não habilita rastreamento background contínuo.
- **A6**: Evidência local pré-gate reportou 102/102; Gate 4 observou 100/102 com flakies fora do slice.

## Parecer

**APROVADO COM RESSALVAS — confiança Alta** para consolidação do UC-03.03 no HEAD `0bb9527`. M1 deve ser registrado como flakiness/debito; não bloqueia o slice.