# QA Review — v0.8.0

> **Data**: 2026-11-21  
> **Commit auditado**: `45fe4aa` — `fix(customers): handle save navigation once and surface edit load errors`  
> **Escopo**: UC-02.01 — Cadastro e Edição de Cliente com Validação `brlib` (re-QA pós-fix)  
> **Baseline anterior**: `637456b` (Gate 3 rejeitado; Gate 4 aprovado com ressalvas)  
> **Gate 2.5**: PULADO (CRUD local, sem nova superfície sensível; sem nova dep)  
> **Gate 3**: APROVADO Alta (`ses_e0145ed3affeVg886ZFzcgDrn9`) — re-review  
> **Gate 4**: APROVADO COM RESSALVAS Alta (`ses_e0145ed3affda6s6lEe9yiNk9f`) — re-QA

## Evidência empírica

| Comando | Resultado | Evidência |
|---|---|---|
| `flutter analyze --fatal-infos` | PASSOU | `No issues found! (ran in 25.1s)` (exit 0) |
| `flutter test` | PASSOU | `01:40 +82: All tests passed!` (exit 0) |

## Delta auditado (637456b..45fe4aa)

- `lib/modules/customers/ui/form/customer_form_controller.dart`: `ensureLoaded()` expõe erro em `Success(null)` ("Cliente não encontrado.") e em `Failure(message)`.
- `lib/modules/customers/ui/form/customer_form_page.dart`: guarda `_savedHandled` + `mounted` impede callback/navegação duplicada após save.
- Sem novos testes adicionados no delta.

## Rastreabilidade UC-02.01

| Critério | Evidência | Status |
|---|---|---|
| Cadastrar/editar cliente (Nome/Razão Social, CPF/CNPJ brlib, WhatsApp, E-mail, Observações) | `customer_test.dart`, `customer_sqlite_repository_test.dart`, `customer_form_test.dart`; campos no form | Conforme |
| Validação CPF/CNPJ via brlib sem exceção de fluxo | `Customer.tryCreate` retorna Failure para documento inválido | Conforme |
| Persistência SQLite local | `CustomerSqliteRepository` + migration v1, testes FFI | Conforme |
| Controller reativo kortex | `IKortexController`, `KortexSignal`, `KortexWatch` | Conforme |
| Alvos >=48dp / cor primária #115E59 | `minHeight:48`, botão 52dp, `AppColors.primaryAction` | Conforme |
| Fix erro load edição | Tratamento null/failure no controller | Conforme com ressalva (sem teste dedicado) |
| Fix navegação única pós-save | `_savedHandled` + `mounted` | Conforme com ressalva (sem teste dedicado) |

## Conformidade SPEC/DESIGN

- **INV-01..INV-06**: não aplicáveis ao slice UC-02.01; nenhuma violação observada.
- **DESIGN**: campos e ação primária atendem alvo tátil >=48dp e token `AppColors.primaryAction`.

## Observações

- **M1**: Adicionar testes de regressão para os caminhos corrigidos em 45fe4aa (edit load null/failure; onSaved single-fire).
- **A1**: Epic-02 sem Gherkin/fixtures detalhados por UC.
- **A2**: Sync de edição no form depende de `name/whatsapp` não vazios; frágil em cenários futuros.

## Parecer

**Aprovado com confiança Alta (ressalvas não bloqueantes).** UC-02.01 consolidável no HEAD `45fe4aa`: `flutter test` 82/82 PASS, `flutter analyze --fatal-infos` sem issues.
