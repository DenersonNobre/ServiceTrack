# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-06.05` — Composition Root & Route Bindings
- **Status**: EM ANDAMENTO (planejamento; T1/T2 a executar)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-06`
- **Gate 2.5 (Segurança)**: PULADO — refactor de composição/navegação sem nova superfície sensível ou coleta/persistência de PII; reavaliar se a fatia alterar essas superfícies.
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **Concluído**: `AppDependencies` (composition root), `CustomersRoutes`, `ProfileRoutes` e helper `appScopedRoute`; `AppEntry` reduzido de 487 para 312 linhas e de 13 para 7 `KortexProvider`. Suíte completa: 174 testes verdes.
- **Planejado**: T1 `AuthRoutes` (onboarding/lock/recovery) e T2 `WorkOrdersRoutes` (list/form/checklist) em worktrees paralelos; T3 integra os dois no `AppEntry` (somente T3 edita o shell); T4 gate de fronteira + QA.
- **Decisão**: [ADR-002](../../architecture/adr-002-app-shell-di-route-bindings.md); plano detalhado em `docs/plan/epics/epic-06-hardening-qualidade.md` (UC-06.05).
- **Restrição**: T1/T2 criam apenas arquivos de módulo; `lib/app/app_entry.dart` é exclusivo da T3. Staging por path explícito; sem `git add -A`.

## [EVIDENCIA]
- Leitura: `lib/app/app_entry.dart` (312 linhas/7 providers), `lib/app/app_dependencies.dart`, `lib/core/ui/app_scoped_route.dart`, `lib/modules/customers/ui/customers_routes.dart`, `lib/modules/profile/ui/profile_routes.dart` → composição por módulo e helper em uso.
- Verifica: `flutter analyze --fatal-infos` → `No issues found!`; `flutter test` → `+174 All tests passed!`.
- Confirma: commits `232c90a` (AppDependencies/CustomersRoutes), `5a36e13` (appScopedRoute) e `8557b66` (helper + ProfileRoutes) → shell reduzido sem mudança de comportamento.

## Próximo passo
1. **T1 `OPS-AUTH-ROUTES`**: criar `AuthRoutes` + testes em worktree próprio, sem tocar `app_entry.dart`.
2. **T2 `OPS-WO-ROUTES`**: criar `WorkOrdersRoutes` + testes em worktree próprio, sem tocar `app_entry.dart`.
3. **T3 `OPS-APP-SHELL-INTEGRATION`**: integrar T1/T2, remover providers manuais e adicionar gate de fronteira; alvo ≤160 linhas/0 providers.
4. **T4 `QA-APP-SHELL-BOUNDARY`**: suíte completa, laudo QA e atualização de `LEARNINGS.md`.
