# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-04.09` — Modelos de checklist alcançáveis (seed + cadastro), sobre `OPS-EPIC04-E2E-DEVICE`
- **Status**: CONCLUÍDO em código+testes; **E2E device BLOQUEADO pelo ambiente** (MIUI `INSTALL_FAILED_USER_RESTRICTED`)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-04`
- **Gate 2.5 (Segurança)**: PULADO — seed de catálogo estático e CRUD local de modelo de checklist; sem nova superfície sensível (nenhuma coleta/transmissão de PII, nenhuma dependência nova de rede).
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **Lacuna fechada**: `UC-04.01` estava `Concluído` com `TASK-02` ("UI de cadastro/listagem") não entregue — `ChecklistTemplateListPage` era **código morto** (nenhuma rota a montava), não havia formulário de cadastro e nenhuma migration semeava templates. Consequência medida: `wo-checklist-template` nascia vazio em instalação limpa, `checklistTemplateId` só podia ser `null` e o fluxo `template→OS→checklist→conclusão` era inalcançável pela UI.
- **Seed (v12)**: `ChecklistMigration.v12()` semeia 3 modelos (`Instalação Split`, `Manutenção Preventiva`, `Vistoria Rápida`) com 8 itens no total, via `INSERT OR IGNORE` (idempotente: reabrir o banco não duplica). `createAppDatabase()` passou para `dbVersion: 12`.
- **Cadastro**: `ChecklistTemplateFormController` (Kortex, rascunho com identidade por item) + `ChecklistTemplateFormPage` (`StatelessWidget`) — validação delegada a `ChecklistTemplate.tryCreate`/`ChecklistItem.tryCreate`, sem duplicar regra no controller.
- **Rota**: `ChecklistsRoutes` (`list()`/`form()`) + ação `wo-templates` no AppBar da lista de OS. A UI antes órfã agora tem caminho de entrada a partir do produto.
- **Toolchain**: `kortex` passou de `path: ../kortex` para **`^0.2.1` (pub.dev)** — o pacote foi publicado e o repositório virou workspace (`packages/kortex`), o que quebrou o path local. `ci/vendor/kortex.tar.gz` removido e `scripts/ci/vendor-deps.ps1` reduzido a `dnolib` (única dependência de path restante).
- **Testes**: +11 na suíte (2 seed, 4 controller, 3 form, 2 alcançabilidade) → **221 verdes**.
- **Bloqueio medido (device)**: `adb -s 192.168.67.65:5555 install -r -t app-debug.apk` → `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`. O aparelho responde (`adb devices` = `device`, `location_mode=3`); a MIUI está recusando instalação por USB (falta "Instalar via USB" nas Opções do desenvolvedor). Sem instalar, `flutter test integration_test/...` não roda — o probe escrito (`integration_test/epic04_probe.dart`) **não foi executado** e não é reportado como validado.

## [EVIDENCIA]
- Leitura: `lib/modules/checklists/data/checklist_migration.dart` → `v12()` com `INSERT OR IGNORE` para 3 templates + 8 itens; `lib/app/database/app_database.dart` → `dbVersion: 12`; `lib/modules/checklists/ui/checklists_routes.dart` → `list()`/`form()` com `appScopedRoute`; `lib/modules/work_orders/ui/list/work_order_list_page.dart` → ação `wo-templates`; `lib/modules/checklists/ui/templates/checklist_template_form_controller.dart` → validação delegada ao domínio.
- Verificação: RED antes do verde em 4 pontos — seed `Expected: length 3 / Actual: []`; controller `Method not found: 'ChecklistTemplateFormController'`; identidade de item `Found 1 widget with text "Primeiro item"` (mutação `ValueKey(draft.id)`→`ValueKey(index)`); alcançabilidade `+0 -2` (mutação removendo `wo-templates`) → todos passaram após a implementação/restauração.
- Confirmação: `flutter analyze --fatal-infos` → `No issues found!`; `flutter test` → `+221 All tests passed!`; `flutter pub get` resolve `kortex 0.2.1` de `https://pub.dev` (`pubspec.lock: source: hosted`).

## Próximo passo
1. **Desbloquear o device**: habilitar "Instalar via USB" (MIUI, exige conta Mi) e rodar `flutter test integration_test/epic04_probe.dart -d 192.168.67.65:5555` para medir rota de boot e fix de GPS antes de escrever o E2E completo.
2. **E2E `template→OS→checklist→conclusão`**: escrever `integration_test/epic04_flow.dart` depois de o probe confirmar GPS (a conclusão de OS exige fix e não tem bypass).
3. **Push**: pendente de autorização explícita do PO + 3 evidências.
4. **D-01/C-01**: segue bloqueando persistência de documento do recebedor por design.
