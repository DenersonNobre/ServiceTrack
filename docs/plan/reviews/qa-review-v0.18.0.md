# QA Review — v0.18.0

> **Data**: 2026-11-22  
> **Commits auditados**: `2b4d962..0d30acb` (5 commits) — UC-04.07 (EPIC-04, D-05)  
> **Escopo**: Prova real de checklist na conclusão de OS (`IChecklistProofPort` + `ChecklistProofAdapter`), política C `requireChecklistTemplate` (default `true`, fail-closed), binding de template na OS, `ChecklistExecutionPage/Controller` com guard `INV-06`, `WorkOrder.checklistTemplateId` + migration v9.  
> **Gate 2.5**: INVOKED — registrado em `docs/plan/state/uc-current.md`; análise estática do slice sem nova PII/LGPD/dependência, reforço de `INV-03`/`INV-06`/`INV-SEC-22` (fail-closed). Risco residual: OS sem template sob política `requireChecklistTemplate=false` (controlado por EPIC-07).  
> **Gate 3**: APROVADO (Alta, `ses_dfbe19c4fffeAhxnu0LOuWgcqx`) após correções de 1ª rodada.  
> **Gate 4**: APROVADO — confiança Alta (esta auditoria).

## Evidência empírica

| Comando | Resultado | Evidência |
|---|---|---|
| `flutter analyze --fatal-infos` | PASSOU | `No issues found! (ran in 73.7s)` (exit 0) — executado em 2026-11-22. |
| `flutter test` (alvo UC-04.07) | PASSOU | `00:12 +12: All tests passed!` (exit 0). Arquivos: `test/modules/checklists/ui/checklist_execution_controller_test.dart`, `test/app/adapters/checklist_proof_adapter_test.dart`, `test/modules/work_orders/ui/work_order_list_controller_test.dart`, `test/modules/checklists/data/checklist_answer_sqlite_repository_test.dart`. |
| `flutter test` (suíte completa) | PASSOU COM RESSALVA FORA DO SLICE | `01:52 +163 -1: Some tests failed.` (exit 1). Falha única: `test/modules/auth/data/credential_recovery_test.dart` — `UC-01.04 - recuperação de credenciais resetPin atualiza apenas PIN e preserva senha/identidade (A2/A5)`. Fora do slice UC-04.07; módulo auth/UC-01.04. |

## Matriz de conformidade

| Invariante / Requisito | Status | Evidência |
|---|---|---|
| **INV-03 (Completude de Fechamento)** | Conforme | `ChecklistProofAdapter.getProof` calcula prova real por template+respostas (`lib/app/adapters/checklist_proof_adapter.dart:25-75`); ausência de template com `requireTemplate=true` retorna `ERR_CHECKLIST_TEMPLATE_OBRIGATORIO` fail-closed; template inexistente retorna `ERR_CHECKLIST_NAO_ENCONTRADO`; obrigatórios não respondidos resultam em `ChecklistCompletionProof.tryCreate` => `ERR_CHECKLIST_INCOMPLETO` (`lib/modules/work_orders/domain/value_objects/checklist_completion_proof.dart:19-39`). `WorkOrderListController.completeWorkOrder` obtém prova via `IChecklistProofPort` antes de concluir e passa prova ao domínio (`lib/modules/work_orders/ui/list/work_order_list_controller.dart:190-244`). `WorkOrder.complete` exige `ChecklistCompletionProof` (`lib/modules/work_orders/domain/value_objects/work_order.dart:245-273`). Testes: adapter cobre fail-closed, política C, obrigatório pendente, completo, template ausente, falha DB template/respostas; controller cobre prova real e `requireTemplate`. |
| **INV-06 (Imutabilidade Pós-Conclusão)** | Conforme | `ChecklistExecutionController.setAnswer` consulta guard `isWorkOrderMutable` antes de criar/salvar resposta e retorna `ERR_OS_IMUTAVEL` quando não mutável (`lib/modules/checklists/ui/execution/checklist_execution_controller.dart:66-100`). Wiring em `AppEntry._goChecklistExecution` considera imutável quando OS `completed` ou `cancelled` (`lib/app/app_entry.dart`, diff 0d30acb). Teste: `checklist_execution_controller_test.dart` prova bloqueio INV-06 e ausência de persistência. |
| **D-05 (bypass 0/0 hardcoded)** | Mitigado no slice | Removido hardcode; prova real via porta/adapter; binding de template na criação/execução; política C explícita. Débito permanece `Em andamento` em `docs/DEBITOS.md` por validação ponta-a-ponta/gates formais — coerente com estado atual. |
| **Política C (decisão PO 2026-11-22)** | Conforme | `requireChecklistTemplate` default `true` (fail-closed) propagado por `ServiceTrackApp`, `AppEntry`, `WorkOrderListController`, `ChecklistProofAdapter`. Sem template + `requireTemplate=false` retorna prova 0/0 apenas por política explícita. |
| **Persistência/binding** | Conforme | `WorkOrder.checklistTemplateId` no domínio/restore/migration v9/repo SQLite; `app_database` registra v9; UI form/list/execution wired. Evidência por diff + testes de repo/controller alvo passando. |

## Apontamentos

- **A1 (fora do slice, conhecido)**: `flutter test` completo com 1 falha em `test/modules/auth/data/credential_recovery_test.dart` (`resetPin atualiza apenas PIN e preserva senha/identidade (A2/A5)`, UC-01.04). Não relacionado ao diff UC-04.07; previamente observado como flakiness auth.
- **A2 (observação, não bloqueante)**: `ChecklistExecutionController.isWorkOrderMutable` é callback injetado; o wiring atual consulta `findAll()` e filtra por id. Funcionalmente correto, mas pode ser otimizado quando houver `findById` no repositório (baixa prioridade, sem impacto de correção no slice).
- **A3 (governança)**: `docs/DEBITOS.md` D-05 e `docs/plan/state/uc-current.md` ainda refletem "Em andamento/pendente gates" — atualizar após consolidação do Gate 4/release conforme processo.

## Parecer

**APROVADO — confiança Alta**.

O slice UC-04.07 fecha o bypass D-05 com prova real calculada por porta/adapter, política C fail-closed por default, guard INV-06 na execução de checklist, e cobertura de testes alvo passando. Não há evidência empírica de regressão no slice; a única falha da suíte completa é fora do escopo (auth UC-01.04). Pode gerar/atualizar laudo de release (este arquivo: `docs/plan/reviews/qa-review-v0.18.0.md`) e seguir consolidação/documentação de gates conforme workflow.