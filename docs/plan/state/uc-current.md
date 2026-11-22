# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-06.05` — Composition Root & Route Bindings
- **Status**: CONCLUÍDO (T1/T2/T3/T4; `qa-review-v0.20.0.md`)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-06`
- **Gate 2.5 (Segurança)**: PULADO — refactor de composição/navegação sem nova superfície sensível ou coleta/persistência de PII.
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **Concluído**: `AppDependencies` (composition root), `CustomersRoutes`, `ProfileRoutes`, `AuthRoutes` e `WorkOrdersRoutes`; helper `appScopedRoute` adotado; `AppEntry` em **168 linhas/0 `KortexScope`/`KortexProvider`**; gate de fronteira `test/app/app_entry_boundaries_test.dart` ativo.
- **Evidência**: suíte completa **180 testes verdes** no topo atual (179 no fechamento do UC-06.05 + gate `db49589` do UC-06.03); `flutter analyze --fatal-infos` sem issues; laudo `docs/plan/reviews/qa-review-v0.20.0.md`.
- **Decisão**: [ADR-002](../../architecture/adr-002-app-shell-di-route-bindings.md); plano detalhado em `docs/plan/epics/epic-06-hardening-qualidade.md` (UC-06.05).
- **Paralelismo**: T1 por `agy01@59993bf1`; T2/T3/T4 pelo orquestrador. Subagentes de T1/T2 atingiram limite de passos; paths disjuntos evitaram colisão.
- **Resíduo**: lifecycle/relock permanece no `AppEntry` por `WidgetsBindingObserver` (justificativa técnica).

## [EVIDENCIA]
- Leitura: `lib/app/app_entry.dart` (168 linhas/0 providers), `lib/modules/auth/ui/auth_routes.dart`, `lib/modules/work_orders/ui/work_orders_routes.dart`, `lib/modules/customers/ui/customers_routes.dart`, `lib/modules/profile/ui/profile_routes.dart`, `lib/core/ui/app_scoped_route.dart` → composição por módulo e gate de fronteira.
- Verifica: `flutter analyze --fatal-infos` → `No issues found!`; `flutter test` → `+180 All tests passed!`.
- Confirma: commits `2a6915a` (AuthRoutes/T1), `d978f3d` (WorkOrdersRoutes/T2), `3e28c30` e `e34ee3d` (integração/T3) → shell enxuto sem mudança de comportamento; `e34ee3d` inclui o gate de fronteira; `db49589` adiciona o gate `ERR_*` (UC-06.03).

## Próximo passo
1. **EPIC-07**: iniciar `UC-07.01` (settings) → `UC-07.02` (UI) → Gate 2.5/`UC-07.03`.
2. **EPIC-06 residual**: fechar `UC-06.01` (literais `ERR_*` em auth) e `UC-06.02` (touch targets residuais).
3. **EPIC-04**: validação E2E device pendente.
