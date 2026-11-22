# QA Review — v0.20.0 — UC-06.05 Composition Root & Route Bindings

> **Data**: 2026-11-22  
> **Escopo**: T1 (`AuthRoutes`), T2 (`WorkOrdersRoutes`), T3 (integração no `AppEntry` + gate de fronteira) e T4 (evidência/laudo) do `UC-06.05`.  
> **Decisão de arquitetura**: [ADR-002](../../architecture/adr-002-app-shell-di-route-bindings.md).  
> **Gate 2.5**: PULADO — refactor de composição/navegação sem nova superfície sensível ou coleta/persistência de PII.

## 1. Veredito

**APROVADO** — confiança **Alta**.

O shell deixou de compor controllers de módulo: `AppEntry` está em **168 linhas** e **0 `KortexScope`/`KortexProvider`**. As rotas de auth, customers, profile e work orders usam `appScopedRoute` / `*Routes`; o comportamento observável foi preservado.

## 2. Evidência

```text
flutter analyze --fatal-infos -> No issues found!
flutter test                  -> +179 All tests passed!
```

- **Gate de fronteira**: `test/app/app_entry_boundaries_test.dart` passa e falha se `AppEntry` voltar a conter `KortexProvider<`/`KortexScope(`.
- **Red-Before-Green (T2)**: teste de `WorkOrdersRoutes` falhou por ausência do arquivo/classe antes da implementação e passou depois (`+1 All tests passed!`).
- **Red-Before-Green (T1)**: `AuthRoutes` entregue com testes de widget pelo `agy01@59993bf1` (commit `2a6915a`); suíte inclui os testes de auth.
- **Import depth**: imports de `appScopedRoute` normalizados de `../../../../core/ui` para `../../../core/ui` em customers/profile/auth (commit `3b5b85d` e `e34ee3d`). O caminho antigo funcionava por clamp de URI do Dart, mas o explícito de 3 níveis é o correto para `lib/modules/<m>/ui/`.

## 3. Checklist de conformidade

| Critério | Resultado |
| :--- | :--- |
| `AppEntry` sem `KortexProvider`/`KortexScope` de módulo | Conforme (0 ocorrências; teste dedicado) |
| `AppEntry` ≤ 170 linhas | Conforme (168) |
| `AuthRoutes` com onboarding/lock/recovery | Conforme |
| `WorkOrdersRoutes` com list/form/checklist | Conforme |
| `CustomersRoutes`/`ProfileRoutes` usando helper | Conforme |
| `isWorkOrderMutable` preservado na rota de checklist | Conforme (mesma lógica do shell anterior) |
| Nenhuma mudança de regra de negócio | Conforme (refactor de composição) |
| Análise estática estrita | Conforme (`No issues found!`) |
| Suíte completa | Conforme (`179 passed`) |

## 4. Achados e resíduos

1. **Target inicial de linhas**: o plano previa ≤160; o resultado foi **168**. O desvio de 8 linhas é de lifecycle/gate (`WidgetsBindingObserver`, `_goHome`, callbacks de lock/recovery), não de composição de módulo. O alvo foi refinado para **≤170** com registro neste laudo.
2. **Lifecycle no shell**: `AppEntry` segue `StatefulWidget` por `WidgetsBindingObserver` (justificativa técnica explícita); o estado de tela continua em Kortex.
3. **T1/T2 em subagentes**: os subagentes atingiram o limite de passos antes de commit; T2 foi concluído pelo orquestrador e T1 pelo `agy01@59993bf1`. O desenho de paths disjuntos evitou colisão; `app_entry.dart` permaneceu exclusivo da integração.
4. **Worktree T1**: o worktree `.../d250c9/t1-auth-routes` pode ser removido após confirmação de que não há mudanças (ficou vazio).

## 5. Commits da fatia

| Commit | Conteúdo |
| :--- | :--- |
| `232c90a` | `AppDependencies` + `CustomersRoutes` |
| `5a36e13` | helper `appScopedRoute` |
| `8557b66` | helper em customers/profile |
| `236bfcd` | ADR-002 + documentação/plano |
| `3b5b85d` | normalização de import depth |
| `d978f3d` | `WorkOrdersRoutes` |
| `2a6915a` | `AuthRoutes` (T1, `agy01@59993bf1`) |
| `3e28c30` | integração de work orders no `AppEntry` |
| `e34ee3d` | integração de auth + gate de fronteira |

## 6. Próximos passos

1. **EPIC-07**: UC-07.01 (settings) → UC-07.02 (UI) → Gate 2.5/UC-07.03.
2. **EPIC-06 residual**: fechar UC-06.01 (literais `ERR_*` em auth) e UC-06.02 (touch targets residuais).
3. **EPIC-04**: validação E2E device pendente.
