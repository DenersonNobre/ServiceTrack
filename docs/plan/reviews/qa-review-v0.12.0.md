# QA Review — v0.12.0

> **Data**: 2026-11-21  
> **Commit auditado**: `2c1c936` — `feat(work-orders): create work order aggregate and quick creation flow for UC-03.01`  
> **Escopo**: UC-03.01 — Criação Rápida de Ordem de Serviço  
> **Gate 2.5**: PULADO (CRUD local SQLite, sem nova dependência/superfície sensível)  
> **Gate 3**: APROVADO Média (`ses_e00b54588ffempuwZPApBZ8CYl`)  
> **Gate 4**: APROVADO COM RESSALVAS Alta (`ses_e00b54588ffdKHtVYBOSwx2Kke`)

## Evidência empírica

| Comando | Resultado | Evidência |
|---|---|---|
| `flutter analyze --fatal-infos` | PASSOU | `No issues found! (ran in 8.6s)` (exit 0) |
| `flutter test` | PASSOU | `00:42 +91: All tests passed!` (92/92, exit 0) |

Testes do slice:
- `test/modules/work_orders/domain/work_order_test.dart` — criação agendada com Money BRL; rejeição de descrição vazia.
- `test/modules/work_orders/data/work_order_sqlite_repository_test.dart` — save/findAll SQLite.

## Rastreabilidade UC-03.01

| Critério | Evidência | Status |
|---|---|---|
| Criação rápida de OS (cliente, descrição, data/hora, valor estimado Money) | Formulário/lista Kortex, controller usa `Money.tryParse` BRL scale 2 e `WorkOrder.tryCreate` | Conforme |
| WorkOrder agregado / status SCHEDULED | `WorkOrder.tryCreate` default `WorkOrderStatus.scheduled`; códigos canônicos definidos | Conforme |
| INV-01/INV-06 (escopo UC-03.01) | Criação apenas SCHEDULED; sem transição/conclusão neste slice | Conforme no escopo |
| Persistência SQLite v3 | `app_database.dart` dbVersion 3 + `WorkOrderMigration.v3()` | Conforme |
| Alvos táteis >=48dp | Inputs minHeight 48, botão 52/min 48, ListTile minTileHeight 56 | Conforme |
| Cor primária #115E59 | `AppColors.primaryAction` usado em CTA/FAB/indicadores | Conforme |

## Observações

- **M1 (Maior, não bloqueante)**: Cobertura unitária insuficiente para validações de `WorkOrder.tryCreate` (id/customerId vazios, valor negativo, currency/scale inválidos).
- **A1**: Sem teste de widget/controller para fluxo de criação (parse BRL, erro/sucesso).
- **A2 (Gate 3)**: `ensureLoaded()` sem retry após falha transitória; status exibido como código bruto na lista.

## Parecer

**APROVADO COM RESSALVAS — confiança Alta.** UC-03.01 consolidável no HEAD `2c1c936`. Gates automatizados verdes; ressalvas registradas para hardening.
