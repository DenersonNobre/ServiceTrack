# Épico 06: Hardening Técnico, Aderência & Qualidade Transversal

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC06` |
| **Dependências Diretas** | `EPIC00`, `EPIC03` (base de código estável); **não bloqueia** EPIC-04/05, mas deve evitar colisão de diff |
| **Prioridade** | Média (Qualidade/Manutenibilidade; reduz dívida antes de escalar EPIC-04/05) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Em Andamento (UC-06.05 concluído; UC-06.01/02 residuais; UC-06.03/04 pendentes)` |
| **Referências** | [Proposta de Mitigação](../../proposals/proposta-mitigacao-aderencia-dnolib-kortex-core-2026-11-22.md) \| [ADR-002](../../architecture/adr-002-app-shell-di-route-bindings.md) \| [AGENTS.md](../../../AGENTS.md) \| [SPEC](../../architecture/SPEC.md) |

---

## 1. Objetivo de Negócio & Escopo

Reduzir dívida técnica transversal identificada na auditoria de 2026-11-22, sem mudar regra de negócio: padronizar códigos de falha, consolidar utilitários de UI/core, reforçar aderência Kortex/Stateless e criar gates simples anti-regressão.

- **Incluso**:
  - `UC-06.01`: Catálogo de `*FailureCodes` por módulo e eliminação de `ERR_*` inline.
  - `UC-06.02`: Core UI transversal (`AppFeedback`, tokens de touch target, helpers de diálogo/confirmação quando houver 2+ usos).
  - `UC-06.03`: Aderência Stateless/Kortex em widgets com `setState` injustificado (inventário da auditoria; exceções só com justificativa explícita).
  - `UC-06.04`: Gate de qualidade anti-string-mágica `ERR_*` fora de catálogos.
  - `UC-06.05`: Composition Root & Route Bindings (`AppDependencies`, `*Routes`, `appScopedRoute`, shell enxuto), com implementação paralela T1/T2 e integração serial T3.
- **Não Incluso**:
  - Integração D-05 / prova real de checklist na conclusão de OS (concluída em EPIC-04; não reabrir neste épico).
  - Unificação do contrato `DigitalSignature` (concluída em EPIC-04/M-05).
  - Hardening de plataforma D-01/D-02/D-03 (débitos separados por ambiente).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| :--- | :--- | :--- | :---: |
| **UC-06.01** | Catálogos de Falha por Módulo (`*FailureCodes`) | Nenhuma | `Em Andamento (auth residual)` |
| **UC-06.02** | Core UI Transversal (Feedback/Touch Target) | Nenhuma | `Em Andamento (touch residual)` |
| **UC-06.03** | Refator Stateless/Kortex em Widgets Justificados | UC-06.02 (opcional) | `Pendente` |
| **UC-06.04** | Gate Anti-String-Mágica `ERR_*` | UC-06.01 | `Pendente` |
| **UC-06.05** | Composition Root & Route Bindings | UC-06.02 (helper), EPIC-03/04 | `Concluído (qa-review-v0.20.0.md)` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] Nenhum literal `ERR_*` fora dos catálogos `*FailureCodes` aprovados (ou allowlist documentada).
- [ ] `AppFeedback`/helpers de core usados onde havia duplicação real; sem “core dump”.
- [ ] `StatefulWidget/setState` remanescentes têm justificativa técnica explícita documentada no código/proposta.
- [ ] Gate automatizado (script/test) falha em novo `ERR_*` literal fora de catálogo.
- [x] `AppEntry` com **0 `KortexProvider` de controller de módulo** e alvo de **≤ 170 linhas** (medido: 168) após T3.
- [x] Cada módulo extraído expõe `*Routes` e usa `appScopedRoute` (ou `KortexScope` manual justificado).
- [x] Gate de fronteira falha se `AppEntry` voltar a compor controller de módulo.
- [x] `flutter analyze --fatal-infos` e `flutter test` com exit code 0 (`179 passed`).
- [x] Laudo QA por UC/épico conforme governança (`qa-review-v0.20.0.md`).

### 3.1 Status de Execução (2026-11-22)

- **UC-06.01 (parcial)**: catálogos `CustomerFailureCodes`, `ProfileFailureCodes`, `ChecklistFailureCodes`, `EvidenceFailureCodes`, `WorkOrderFailureCodes` e `AuthFailureCodes` existem. Ainda há literais `ERR_*` inline em value objects/recovery de `auth` (ex.: `ERR_EMAIL_INVALIDO`, `ERR_RECUPERACAO_NAO_AUTORIZADA`), pendentes para fechar o critério “zero literal fora de catálogo”.
- **UC-06.02 (parcial)**: `AppFeedback` e tokens `kMinTouchTarget*` criados e usados em work_orders/checklists/profile. Ainda há `Size(48, 48)` literal em auth/checklists/evidences; migrar ou justificar.
- **UC-06.05 (concluído)**: `AppDependencies`, `CustomersRoutes`, `ProfileRoutes`, `AuthRoutes`, `WorkOrdersRoutes` e `appScopedRoute` entregues; `AppEntry` em **168 linhas/0 providers**; gate de fronteira ativo; suíte **179 testes verdes** (`qa-review-v0.20.0.md`).

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-06.01 — Catálogos de Falha por Módulo

* **Identificador**: `UC-06.01`
* **Status**: `Pendente`

#### Narrativa
- **Como** mantenedor do ServiceTrack
- **Eu quero** códigos `ERR_*` centralizados por módulo/contexto
- **Para que** evite typo, divergência de contrato e refatoração frágil.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Nenhum código de erro literal fora de catálogo após migração
  Dado que os módulos possuem catálogos *FailureCodes
  Quando a suíte de verificação de strings mágicas é executada
  Então ela retorna exit code 0
  E não há literal "ERR_" fora dos arquivos de catálogo/allowlist
```

#### Tarefas Técnicas
1. `TASK-01`: Inventariar `ERR_*` por módulo (auth já tem padrão; replicar para customers/work_orders/checklists/evidences/profile/core onde aplicável).
2. `TASK-02`: Migrar literais com testes verdes por módulo (fatia pequena).
3. `TASK-03`: Adicionar teste/script de verificação.

---

### Caso de Uso UC-06.02 — Core UI Transversal

* **Identificador**: `UC-06.02`
* **Status**: `Pendente`

#### Narrativa
- **Como** desenvolvedor Flutter
- **Eu quero** helpers transversais para feedback e alvo tátil
- **Para que** eliminar boilerplate sem criar abstração prematura.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Feedback de erro padronizado
  Dado que uma tela precisa exibir ValidationError ao usuário
  Quando o helper AppFeedback.showError é chamado
  Então exibe SnackBar com mensagem e sem duplicar ScaffoldMessenger boilerplate
```

#### Tarefas Técnicas
1. `TASK-01`: Criar `lib/core/ui/app_feedback.dart` e tokens `touch_target.dart` (somente se 2+ usos reais).
2. `TASK-02`: Migrar usos duplicados (começar por `work_order_list_page.dart`).
3. `TASK-03`: Testes de widget para helper/comportamento acessível.

---

### Caso de Uso UC-06.03 — Refator Stateless/Kortex

* **Identificador**: `UC-06.03`
* **Status**: `Pendente`

#### Narrativa
- **Como** time de UI
- **Eu quero** widgets sem `setState` injustificado
- **Para que** cumprir a regra canônica do AGENTS.md e manter reatividade Kortex.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Widget com estado de tela usa Kortex
  Dado um widget que antes usava setState para estado de tela
  Quando for refatorado
  Então passa a usar KortexSignal/IKortexController/KortexWatch conforme aplicável
  E nenhum StatefulWidget permanece sem justificativa técnica explícita
```

#### Tarefas Técnicas
1. `TASK-01`: Revisar ocorrências validadas na Seção 7.1 da proposta (foco em `signature_pad_widget.dart` e lifecycle forms).
2. `TASK-02`: Refatorar somente onde houver ganho real; documentar exceções.

---

### Caso de Uso UC-06.04 — Gate Anti-String-Mágica ERR

* **Identificador**: `UC-06.04`
* **Status**: `Pendente`
* **Dependência**: UC-06.01

#### Narrativa
- **Como** mantenedor de qualidade
- **Eu quero** um gate que falhe em novos `ERR_*` literais fora de catálogo
- **Para que** a dívida N-06 não regrida.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Gate reprova literal ERR fora de catálogo
  Dado um arquivo Dart com literal "ERR_NOVO_CODIGO" fora de *FailureCodes
  Quando o script de gate executa
  Então retorna exit code != 0 e aponta o arquivo:linha
```

#### Tarefas Técnicas
1. `TASK-01`: Criar script PowerShell/Dart em `scripts/gates/` ou `scripts/` com allowlist explícita.
2. `TASK-02`: Integrar ao `build-all.ps1`/verificação local; documentar em AGENTS/LEARNINGS.

---

### Caso de Uso UC-06.05 — Composition Root & Route Bindings

* **Identificador**: `UC-06.05`
* **Status**: `Concluído (T1/T2/T3/T4; qa-review-v0.20.0.md)`
* **Dependência**: UC-06.02 (`appScopedRoute`), EPIC-03/04 (módulos estáveis)
* **Gate 2.5**: `PULADO — refactor de composição/navegação sem nova superfície sensível, sem nova coleta/persistência de PII; se a fatia alterar essas superfícies, vira INVOKED.`
* **Decisão**: [ADR-002](../../architecture/adr-002-app-shell-di-route-bindings.md)
* **Gate DoR**: claim por track (`OPS-AUTH-ROUTES`, `OPS-WO-ROUTES`, `OPS-APP-SHELL-INTEGRATION`) com paths explícitos.
* **Gate DoD**: T1/T2 verdes isolados; T3 com `flutter analyze --fatal-infos` + `flutter test` exit 0; T4 laudo.

#### Narrativa
- **Como** mantenedor do ServiceTrack
- **Eu quero** que cada módulo componha suas próprias rotas/escopos Kortex
- **Para que** novas telas não exijam editar o shell nem reintroduzam boilerplate de `MaterialPageRoute + KortexScope + KortexProvider`.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Rota de módulo sem editar o shell
  Dado que o módulo expõe <Modulo>Routes com appScopedRoute
  Quando o shell navega para a rota
  Então o controller é criado no KortexScope e descartado no pop
  E AppEntry não contém KortexProvider daquele módulo

Cenário: Refactor sem mudança de comportamento
  Dado que todos os fluxos de auth/work orders são exercitados
  Quando a suíte completa executa após T3
  Então flutter analyze --fatal-infos retorna 0
  E flutter test retorna 0 com a mesma cobertura funcional
```

#### Plano de Implementação Paralela
| Track | Slice | Ownership de paths | Dependência | Saída |
| :--- | :--- | :--- | :--- | :--- |
| **T0** | `DOC-APP-SHELL-PLAN` | `docs/**`, `AGENTS.md`, `CHECKPOINT.md`, `README.md`, `LEARNINGS.md` | Nenhuma | ADR/plano/documentação |
| **T1** | `OPS-AUTH-ROUTES` | `lib/modules/auth/ui/auth_routes.dart`, `lib/modules/auth/ui/.index.dart`, `test/modules/auth/ui/auth_routes_test.dart` | `appScopedRoute` | `AuthRoutes` (onboarding/lock/recovery) + testes |
| **T2** | `OPS-WO-ROUTES` | `lib/modules/work_orders/ui/work_orders_routes.dart`, `lib/modules/work_orders/ui/.index.dart`, `test/modules/work_orders/ui/work_orders_routes_test.dart` | `appScopedRoute` | `WorkOrdersRoutes` (list/form/checklist) + testes |
| **T3** | `OPS-APP-SHELL-INTEGRATION` | `lib/app/app_entry.dart`, `lib/app/app_dependencies.dart` (se necessário), `test/app/app_entry_boundaries_test.dart` | T1 + T2 | Shell integrado + gate de fronteira |
| **T4** | `QA-APP-SHELL-BOUNDARY` | `docs/plan/reviews/**`, `LEARNINGS.md` | T3 | Laudo QA e evidência final |

**Execução (2026-11-22)**: T1 (auth) por `agy01@59993bf1`; T2 (work orders), T3 (integração/gate) e T4 (laudo) pelo orquestrador `opc01@e03ff640`. Os subagentes de T1/T2 atingiram o limite de passos antes do commit; o desenho de paths disjuntos permitiu concluir sem colisão e manteve `app_entry.dart` exclusivo da T3.

**Regras de paralelismo**
- T1 e T2 são disjuntos; executar em **worktrees separados** (TOPO-01) com claims independentes.
- **Somente T3 edita `lib/app/app_entry.dart`**; T1/T2 não tocam o shell.
- Merge-back serializado: T1 e T2 concluem/commitam; T3 integra os dois; T4 audita.
- Staging por path explícito; proibido `git add -A`/`git add -u`; commit com `-o`.
- Gate de fronteira: `test/app/app_entry_boundaries_test.dart` falha se `AppEntry` contiver `KortexProvider<` de controller de módulo.

#### Tarefas Técnicas
1. `TASK-01 (T1)`: Criar `AuthRoutes` com `onboarding(onCompleted)`, `lock(onUnlocked, onForgotPin)` e `recovery(onRecovered)` usando `appScopedRoute`; testar criação/descarte e callbacks.
2. `TASK-02 (T2)`: Criar `WorkOrdersRoutes` com `list`, `form(onSaved)` e `checklistExecution(workOrderId, templateId)`; calcular `isWorkOrderMutable` internamente via repositório; testar.
3. `TASK-03 (T3)`: Integrar T1/T2 no `AppEntry`; remover imports/providers manuais; manter gate/lifecycle/dispatch; alvo ≤170 linhas e 0 providers de módulo (medido: 168/0).
4. `TASK-04 (T3)`: Criar gate de fronteira `test/app/app_entry_boundaries_test.dart` e prova negativa (fixture com `KortexProvider` reprova).
5. `TASK-05 (T4)`: Rodar suíte completa, `flutter analyze --fatal-infos`, emitir laudo QA e atualizar `LEARNINGS.md`/`uc-current`.

#### Impacto & Arquivos Alvo
- `lib/modules/auth/ui/auth_routes.dart` [NEW]
- `lib/modules/auth/ui/.index.dart` [MODIFY]
- `test/modules/auth/ui/auth_routes_test.dart` [NEW]
- `lib/modules/work_orders/ui/work_orders_routes.dart` [NEW]
- `lib/modules/work_orders/ui/.index.dart` [MODIFY]
- `test/modules/work_orders/ui/work_orders_routes_test.dart` [NEW]
- `lib/app/app_entry.dart` [MODIFY — T3 only]
- `lib/app/app_dependencies.dart` [MODIFY se necessário — T3 only]
- `test/app/app_entry_boundaries_test.dart` [NEW]
- `docs/plan/reviews/qa-review-*.md` [NEW na T4]

## 5. Riscos & Dependências

| Risco | Prob. | Impacto | Mitigação |
| :--- | :--- | :--- | :--- |
| Refator amplo de `ERR_*` gerar churn | Média | Médio | Migrar por módulo, commits atômicos, testes por fatia. |
| “Core dump” de abstrações | Média | Médio | Só promover para core com 2+ usos reais. |
| Regressão no fluxo de conclusão de OS (EPIC-04) | Média | Alto | D-05 já mitigado; preservar testes de prova/checklist e não alterar regra na extração de rotas. |
| Conflito de `app_entry.dart` entre T1/T2 | Alta | Alto | Somente T3 edita o shell; T1/T2 criam apenas arquivos de módulo em worktrees separados. |
| Regressão no relock/onboarding ao extrair auth | Média | Alto | Testes de rota + smoke test; manter callbacks `onUnlocked`/`onForgotPin`/`onCompleted`. |
| Regressão de política/D-05 ao extrair work orders | Média | Alto | `WorkOrdersRoutes` reutiliza controller/prova existentes; suíte de conclusão como rede; Gate 2.5 reavaliado se superfície mudar. |
| Merge-back de worktrees | Média | Médio | Commits atômicos por track; T3 integra por último; diff vazio/status limpo antes do teardown. |
