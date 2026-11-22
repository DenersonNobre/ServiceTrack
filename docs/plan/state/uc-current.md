# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-07.03` — Integração de Políticas de Conclusão/Evidência
- **Status**: CONCLUÍDO (código+testes; G2.5 com condicionantes; G3 aprovado com ressalvas; G4 pendente)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-07`
- **Gate 2.5 (Segurança)**: INVOKED — APROVADO COM CONDICIONANTES (Média). SEC-01 fonte única via `GetSettings`; SEC-02 leitura por operação; SEC-03 fail-closed se settings falhar; SEC-04 não coletar documento sem proteção em repouso; SEC-05 guard D-01 preservado; SEC-06 sem PII em log/erro; SEC-07 prova de ausência no guard; SEC-08 política de checklist não relaxa INV-03. Invariantes INV-SEC-28..32.
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **Concluído**: `WorkOrderListController` lê `GetSettings` por operação; `require_checklist_template` alimenta a prova real; `require_receiver_document` valida documento e falha com `ERR_ASSINATURA_DOCUMENTO_PROTECAO_INDISPONIVEL` enquanto D-01/C-01 estiver aberto. A UI consulta a política antes do diálogo e não renderiza o campo de documento quando a proteção está indisponível.
- **Wiring**: bools de política removidos de `AppDependencies`, `ServiceTrackApp` e `WorkOrdersRoutes`; `settingsRepository` é a fonte única. `documentAtRestProtectionAvailable` é injetável apenas para testes, com default fail-closed.
- **Testes**: 4 testes nomeados de política/segurança (SEC-02/03/04/08) + widget test de não-coleta; SEC-07 é asserção de ausência no teste do guard; suíte completa **202 verdes**; análise limpa.
- **Gate 3**: APROVADO COM RESSALVAS (Média). Corrigidos M-01/M-02/M-04/B-02/B-03/B-04; deferidos M-03/M-05/B-01.
- **CI**: GitHub Actions green no run `45079552556` (vendor de deps locais). O Gitea não possui workflow.

## [EVIDENCIA]
- Leitura: `lib/modules/work_orders/ui/list/work_order_list_controller.dart`, `lib/modules/work_orders/ui/list/work_order_list_page.dart`, `lib/modules/work_orders/ui/work_orders_routes.dart`, `lib/app/app_dependencies.dart`, `lib/app/service_track_app.dart`, `lib/app/app_entry.dart`, `lib/modules/work_orders/domain/value_objects/document_protection.dart` → política única, leitura por operação e fail-closed.
- Verifica: `flutter analyze --fatal-infos` → `No issues found!`; `flutter test test/modules/settings test/modules/work_orders/ui` → `+24 All tests passed!`.
- Confirma: `flutter test` → `+202 All tests passed!`; teste do guard confirma que OS permanece `IN_PROGRESS` sem assinatura após falha; CI GitHub run `45081277660` verde.

## Próximo passo
1. **Gates 3/4 formais** do EPIC-07 (review/QA).
2. **EPIC-04**: validação E2E device pendente.
3. **EPIC-06 residual**: UC-06.01/02 residuais.
4. **Push**: pendente de autorização explícita do PO + 3 evidências.
