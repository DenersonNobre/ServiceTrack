# ADR-002 — Composition Root e Route Bindings por Módulo

> **Status**: Aceito (implementação incremental)  
> **Data**: 2026-11-22  
> **Autor**: `opc01@e03ff640`  
> **Relacionado**: `EPIC-06`/`UC-06.05`, `AppEntry`, `AppDependencies`, `CustomersRoutes`, `ProfileRoutes`, `appScopedRoute`, `AGENTS.md` (proibição de GetX), `SPEC.md` §5, `DESIGN.md` §6.

## Contexto

[FATO] O `lib/app/app_entry.dart` concentrava gate de rota, lifecycle, navegação e composição de 13 `KortexScope`/`KortexProvider` em 487 linhas. Cada nova tela de módulo exigia editar o shell, aumentando o acoplamento e o risco de regressão.

[FATO] O projeto proíbe GetX (`AGENTS.md`) e adota Kortex com escopo explícito na árvore de widgets (`KortexScope`/`KortexProvider`, `SPEC.md` §5). Não existe “binding” de GetX; o equivalente é o escopo Kortex.

[INFERÊNCIA, confiança Alta] O padrão anterior era emergente, não uma decisão documentada: a navegação foi centralizada no `AppEntry` e as UCs seguintes empilharam escopos no mesmo arquivo.

[FATO] A extração piloto já entregou `AppDependencies`, `CustomersRoutes`, `ProfileRoutes` e o helper `appScopedRoute`; o `AppEntry` caiu para 312 linhas e 7 `KortexProvider`.

## Decisão

1. **Composition root explícito**: `AppDependencies` (`lib/app/app_dependencies.dart`) agrega portas/adaptadores e políticas; `ServiceTrackApp` monta o objeto e o injeta no `AppEntry`.
2. **Binding por módulo**: cada módulo expõe `*Routes` (ex.: `CustomersRoutes`, `ProfileRoutes`) em `lib/modules/<modulo>/ui/`, com métodos que retornam `Route<void>`.
3. **Helper canônico**: `appScopedRoute<T, R>` (`lib/core/ui/app_scoped_route.dart`) encapsula `MaterialPageRoute` + `KortexScope` + `KortexProvider` + `readKortex` + auto-dispose para rotas com **um** controller.
4. **Exceção justificada**: `KortexScope` manual permanece apenas quando a rota precisa de múltiplos providers; a justificativa fica no código/PR.
5. **Shell enxuto**: `AppEntry` mantém gate de rota inicial, lifecycle/relock e dispatch das rotas; não compõe controllers de módulo nem conhece regras de negócio.
6. **Sem service locator**: dependências continuam explícitas por construtor; GetX/Provider/ChangeNotifier seguem proibidos.

## Alternativas consideradas

| Alternativa | Por que não |
| :--- | :--- |
| **GetX Bindings** | Proibido por `AGENTS.md`; introduziria dependência e padrão indesejados. |
| **Service locator** (ex.: `Get.find`/container global) | Esconde dependências, dificulta testes e mascara acoplamento. |
| **Manter tudo no `AppEntry`** | SRP violado, shotgun surgery a cada módulo e crescimento linear do shell. |
| **Pacote externo de roteamento** | Não resolve a composição Kortex e adiciona dependência sem ganho mensurável no escopo standalone. |
| **Um binding global por app** | Mistura ciclos de vida e impede descarte determinístico por rota. |

## Consequências

**Positivas**
- Módulo autocontido: página, controller e binding vivem no mesmo bounded context.
- Shell menor e estável; novas telas não exigem editar `AppEntry`.
- Descarte determinístico do controller no pop da rota.
- Dependências explícitas e testáveis; nenhuma resolução global.

**Negativas / custos**
- Mais um arquivo `*Routes` por módulo.
- Necessidade de disciplina para não reintroduzir composição no shell.
- Rotas com múltiplos controllers exigem `KortexScope` manual documentado.

## Estado da migração

| Etapa | Estado | Evidência |
| :--- | :--- | :--- |
| `AppDependencies` + `CustomersRoutes` | Concluído | commit `232c90a` |
| `appScopedRoute` (helper) | Concluído | commit `5a36e13` |
| `CustomersRoutes` usando o helper | Concluído | commit `8557b66` |
| `ProfileRoutes` | Concluído | commit `8557b66` |
| `AuthRoutes` | Concluído | commit `2a6915a` (T1) |
| `WorkOrdersRoutes` | Concluído | commit `d978f3d` (T2) |
| Integração no `AppEntry` | Concluído | commits `3e28c30`/`e34ee3d` (T3); 168 linhas/0 providers |
| Gate de fronteira + QA | Concluído | `test/app/app_entry_boundaries_test.dart` + `qa-review-v0.20.0.md` (T4) |

## Plano de Implementação Paralela

| Track | Slice | Ownership de paths | Dependência | Saída |
| :--- | :--- | :--- | :--- | :--- |
| **T0** | `DOC-APP-SHELL-PLAN` | `docs/**`, `AGENTS.md`, `CHECKPOINT.md`, `README.md`, `LEARNINGS.md` | Nenhuma | ADR/plano/documentação |
| **T1** | `OPS-AUTH-ROUTES` | `lib/modules/auth/ui/auth_routes.dart`, `lib/modules/auth/ui/.index.dart`, `test/modules/auth/ui/auth_routes_test.dart` | `appScopedRoute` | `AuthRoutes` + testes |
| **T2** | `OPS-WO-ROUTES` | `lib/modules/work_orders/ui/work_orders_routes.dart`, `lib/modules/work_orders/ui/.index.dart`, `test/modules/work_orders/ui/work_orders_routes_test.dart` | `appScopedRoute` | `WorkOrdersRoutes` + testes |
| **T3** | `OPS-APP-SHELL-INTEGRATION` | `lib/app/app_entry.dart`, `lib/app/app_dependencies.dart` (se necessário), `test/app/app_entry_boundaries_test.dart` | T1 + T2 | Shell integrado + gate de fronteira |
| **T4** | `QA-APP-SHELL-BOUNDARY` | `docs/plan/reviews/**`, `LEARNINGS.md` | T3 | Laudo QA e evidência final |
| **T4** | `QA-APP-SHELL-BOUNDARY` | `docs/plan/reviews/**`, `LEARNINGS.md` | T3 | Laudo QA e evidência final |

**Regras de paralelismo**
- T1 e T2 são disjuntos e podem rodar em **worktrees separados** (TOPO-01), com claims independentes.
- **Somente T3 edita `lib/app/app_entry.dart`**; T1/T2 não tocam o shell.
- Merge-back serializado: T1 → T2 → T3, ou ambos em worktrees e T3 integra por último.
- Nenhum agente usa `git add -A`/`git add -u`; staging por path explícito e commit com `-o`.
- O gate de fronteira (T3) deve falhar se `AppEntry` voltar a conter `KortexProvider<` de controller de módulo.

## Regras de implementação

1. `*Routes` recebe apenas as portas que usa (ISP); não importa `AppDependencies` do shell.
2. Uma rota = um controller via `appScopedRoute`; multi-provider exige justificativa.
3. Rotas não contêm regra de negócio; apenas composição/navegação.
4. Refactor é behavior-preserving: suíte completa verde antes/depois.
5. Gate 2.5 é `PULADO` para refactor de composição sem nova superfície/PII; se a fatia alterar coleta/persistência sensível, vira `INVOKED`.

## Referências

- `AGENTS.md` §1 (mandato e proibição de GetX).
- `docs/architecture/SPEC.md` §5 e §5.1.
- `docs/architecture/DESIGN.md` §6 (ADR-06).
- `docs/plan/epics/epic-06-hardening-qualidade.md` (`UC-06.05`).
- `lib/app/app_dependencies.dart`, `lib/core/ui/app_scoped_route.dart`, `lib/modules/customers/ui/customers_routes.dart`, `lib/modules/profile/ui/profile_routes.dart`.
