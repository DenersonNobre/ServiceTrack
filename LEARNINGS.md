# Diário de Bordo Técnico — LEARNINGS.md

Este arquivo registra aprendizados, armadilhas superadas e decisões técnicas do **ServiceTrack**.

## 2026-11-25 — Evolução da Agenda (2D Fullscreen e Timeline Diária) e Formatação Universal com Kortex

### 1. Calendário Mensal em Tela Cheia com Navegação Bidimensional
- **Fato**: A agenda mensal anterior compartilhava espaço vertical de forma restrita, prejudicando a visão de múltiplos agendamentos em telas menores.
- **Decisão**: A `SchedulePage` passou a ocupar 100% da viewport útil (Full Screen), integrando gestos bidimensionais (arrastar na horizontal para trocar de mês, arrastar na vertical para navegar entre anos).
- **Interação**: Ao tocar em qualquer dia com ou sem agendamentos, o app navega de forma determinística para a **Agenda Diária** (`ScheduleDayPage`).

### 2. Agenda Diária com Timeline de Ocupação e Parametrização da Jornada
- **Implementação**: Criados `ScheduleDayPage` e `ScheduleDayController` em Kortex reativo puro (`IKortexPage`, `IKortexController`, `KortexSignal`, `KortexWatch`).
- **Resolução de Horários**: A timeline vertical é renderizada a partir das configurações dinâmicas de jornada do usuário (`schedule_day_start`, `schedule_day_end`, `schedule_slot_interval`).
- **Ocupação Visual**: Blocos de compromissos (`WorkOrder`) preenchem os slots horários com título, badges de status (`AppStatusBadge`) e identificador. O toque no compromisso abre a tela de detalhes da OS, e o toque em um slot livre abre o agendamento pré-preenchido.

### 3. Persistência Resiliente de Configurações no SQLite (`ConflictAlgorithm.replace`)
- **Sintoma**: As configurações falhavam ao salvar na UI com snackbar de erro em certas compilações SQLite devido a sintaxe raw `INSERT ... ON CONFLICT(key)`.
- **Causa Raiz**: Queries manuais `INSERT ... ON CONFLICT` dependem de versões e flags específicas do SQLite em runtimes embarcados/FFI, sendo propensas a falhas de parsing ou violação de constraints.
- **Solução**: Uso do método padrão da biblioteca `db.insert(table, map, conflictAlgorithm: ConflictAlgorithm.replace)`. Garante atomicidade nativa (upsert) tanto em desenvolvimento FFI quanto nos runtimes Android/iOS.

### 4. Formatação Dinâmica ao Digitar com `kortex_lib/brlib`
- **Fato**: Campos de entrada de dados como CPF/CNPJ, Telefone/WhatsApp, CEP, Moeda (R$) e Datas necessitavam de formatação instantânea na digitação sem corromper o valor limpo consumido pelos controladores.
- **Solução**: Uso dos formatters prontos e testados de `package:kortex_lib/brlib/brlib.dart`:
  - `DocumentInputFormatter`: Comutação dinâmica automática entre `CpfInputFormatter` (11 dígitos) e `CnpjInputFormatter` (14 dígitos).
  - `PhoneBrInputFormatter`: Formatação padrão brasileira para telefones fixos e celulares com nono dígito.
  - `CepInputFormatter`: Formatação de CEP (`99999-999`).
  - `CurrencyInputFormatter`: Formatação de moeda em tempo real (`R$ 0,00`).
  - `DateInputFormatter`: Formatação de data (`dd/MM/yyyy`).
- **Regra**: Evitar criar formatters manuais com regex artesanal quando o ecossistema `kortex_lib/brlib` já fornece as implementações canônicas homologadas.

---

## 2026-11-24 — Refatoração Arquitetural: `AppServices`, Route Bindings e FakeAsync com SQLite

### 1. `AppServices` vs `AppDependencies` (Composition Root Enxuto)
- **Fato**: O antigo `AppDependencies` acumulava dezenas de repositórios de domínio de múltiplos bounded contexts (`customerRepo`, `workOrderRepo`, `checklistRepo`, etc.), gerando acoplamento desnecessário na raiz do aplicativo.
- **Decisão**: Substituído definitivamente por **`AppServices`** (`lib/app/app_services.dart`). `AppServices` contém **exclusivamente** serviços de infraestrutura e plataforma/hardware (`database`, `credentialStore`, `biometricAuth`, `locationService`).
- **Invariante**: **Zero repositórios de domínio em `AppServices`**. Módulos recebem a conexão com o banco e instanciam seus próprios repositórios internamente (`*Routes.fromDatabase(database)`).
- **Resultado**: `lib/app/app.dart` e classe `App` (antigo `ServiceTrackApp`) tornaram-se puramente declarativos; o `main.dart` foi reduzido a apenas 14 linhas de bootstrap.

### 2. Simplificação de Nomenclatura (Anti-Redundância)
- **Regra**: Evitar prefixos/sufixos compostos redundantes em módulos com escopo evidente.
- **Ação**: No módulo `home/`, renomeado `HomeDashboardController` para `HomeController` (`home_controller.dart`) e `HomeDashboardData` para `HomeData`.

### 3. Gotcha Técnico: SQLite FFI em `testWidgets` e Deadlock de FakeAsync
- **Sintoma**: `test/smoke_test.dart` travava por 10 minutos com `TimeoutException` após a migração para `AppServices`.
- **Causa Raiz**: O `databaseFactoryFfi` despacha chamadas I/O em isolate de background. O `testWidgets` do Flutter roda dentro de uma zona simulada `FakeAsync`. Abrir e inicializar um banco SQLite FFI real dentro de `testWidgets` sem `tester.runAsync` causa deadlock porque o microtask loop do `FakeAsync` não avança com threads nativas externas.
- **Solução**:
  - `AppServices.database` foi tornado opcional (`SqliteProvider?`).
  - Para `testWidgets` de casca/smoke (ex.: tela inicial de autenticação), passar `AppServices(database: null, ...)` com repositórios e serviços em memória (`FakeCredentialStore`, etc.).
  - Testes que realmente necessitam do banco SQLite integrado devem ser testes normais de unidade/integração (`test(...)`) ou isolados com mocks/fakes puros.

---

## 2026-11-24 — Governança de Personas do Oráculo & Blindagem Anti-Monolito

### 1. Desvio de Persona e Restauração da Esteira Multi-Agente
- **Fato**: Durante a execução inicial do `UC-05.01`, o agente orquestrador implementou o código diretamente na thread principal em vez de delegar as fases de Coder e Reviewer para subagentes especializados via `invoke_subagent`.
- **Causa Raiz**: Ausência de um gate explícito e mandatório de personas em `AGENTS.md`, permitindo atalhos na esteira de desenvolvimento.
- **Ação Corretiva**: Blindagem de `AGENTS.md` tornando compulsória a divisão de papéis: Orquestrador (coordena claims/fatias), Coder (subagente TDD Red-Before-Green), Reviewer (subagente antagônico Gate 3) e QA (verificação completa Gate 4).
- **Regra**: O agente orquestrador não escreve código de produção; delega sempre a subagentes dedicados com isolamento de contexto e TDD estrito.

---

## 2026-11-20 — Fundação Técnica (EPIC-00)

### 1. Paridade de SDK e Dependências do Autor
- **Fato**: O ambiente local possui o Flutter `3.47.6` com Dart `3.13.5`. O pacote local `kortex` está pinado em Dart `>=3.13.5` e a `dnolib` em `3.9.0`.
- **Ação**: O `pubspec.yaml` do ServiceTrack foi configurado com `sdk: ^3.13.5` e dependências por caminho relativo local (`../kortex` e `../.dnolib`), resolvendo perfeitamente sem conflito de lockfile.
- **Regra**: Conforme diretriz do projeto, o módulo `synapx` da `dnolib` não deve ser importado nos módulos de negócio.

### 2. Shim de Claims no Windows
- **Fato**: O binário nativo `claims.exe` reside em `A:\Projetos\.oraculo\tools\bin\cli\claims.exe`.
- **Ação**: Criado o wrapper `tools/bin/claims.cmd` apontando diretamente para o caminho absoluto com encaminhamento de argumentos (`%*`), garantindo interoperabilidade entre agentes e terminal sem poluir o PATH do sistema.

### 3. CI/CD e Qualidade de Código
- **Decisão**: Configurado `analysis_options.yaml` com flags de checagem estrita (`strict-casts`, `strict-inference`, `strict-raw-types`), garantindo que nenhum código sem tipagem completa passe despercebido.

## 2026-11-21 — Obsidian MCP (Local REST API) com OpenCode: integração e decisão

### 1. Falha TLS no endpoint HTTPS (Node 24)
- **Sintoma**: `mcp connect failed` para `obsidian` com `TypeError: unsupported name constraint type (UNSUPPORTED_CONSTRAINT_TYPE)` ao conectar em `https://127.0.0.1:27124/mcp/`.
- **Causa**: incompatibilidade de parsing/validação X.509 na pilha TLS do Node.js (v24) com o certificado autoassinado emitido pelo plugin "Local REST API with MCP" (v5.5.2). O transporte falhava antes do handshake MCP.
- **Mitigação aplicada**: uso do endpoint HTTP local `http://127.0.0.1:27123/mcp/` (loopback), contornando TLS. HTTPS exigiria regenerar/atualizar certificado do plugin ou proxy local compatível.
- **Evidência**: endpoint HTTP respondeu (401 sem auth) enquanto HTTPS falhava com o erro acima; após ajuste de URL e auth, `command_list` respondeu com sucesso.

### 2. Autenticação: API key estática, não OAuth
- **Sintoma**: após trocar para HTTP, status `needs_auth` (401); ao clicar "Sign In" na TUI, OpenCode tentou fluxo OAuth/DCR e falhou com `Dynamic Client Registration rejected (HTTP 401)` e mensagem do plugin pedindo API Key.
- **Causa**: o plugin autentica por **Bearer token estático** (`Authorization: Bearer {env:OBSIDIAN_API_KEY}`), não oferece OAuth/DCR.
- **Mitigação**: definir `OBSIDIAN_API_KEY` no ambiente do processo que inicia o OpenCode e reiniciar completamente (variável de usuário exige novo processo/sessão que herde o ambiente). Não usar "Sign In" OAuth para este servidor.

### 3. Operação do vault e escopo do MCP
- **Fato**: o MCP (Local REST API) opera no **vault aberto/servido** no momento; `.obsidian/` é bloqueado pela API. Plugins/configurações (incluindo Local REST API, porta e chave) são **por vault** — cada novo vault exige instalação/configuração do plugin.
- **Estrutura em disco**: criado e depois removido `C:\Users\Denerson\Vaults\Oraculo` (hub, índice, sessão e pastas); entrada do vault removida de `%APPDATA%\obsidian\obsidian.json`; MCP `obsidian` desativado em `~/.config/opencode/opencode.json` (`disabled: true`).

### 4. Decisão de adoção (ServiceTrack / fluxo Oráculo)
- **Avaliação**: com artefatos canônicos já versionados no repo (PRD/SPEC/DESIGN, `docs/plan`, `CHECKPOINT.md`, `LEARNINGS.md`, reviews), Obsidian/Notion adicionariam camada paralela com custo de manutenção e risco de divergência sem ganho claro no momento.
- **Decisão**: não adotar Obsidian/Notion para este fluxo agora; seguir com Oráculo + repositório como fonte única. Reavaliar apenas diante de dor concreta (colaboração externa/stakeholders → Notion; base pessoal interligada cross-projeto → Obsidian).

## 2026-11-22 — Shell DI: `AppDependencies` + bindings por módulo

### 1. Sintoma
- `lib/app/app_entry.dart` concentrava gate de rota, lifecycle, navegação e 13 `KortexScope`/`KortexProvider` em 487 linhas; cada módulo novo exigia editar o shell.

### 2. Decisão
- GetX é proibido (`AGENTS.md`); o "binding" no Kortex é o `KortexScope`/`KortexProvider`.
- Introduzido `AppDependencies` (composition root), `CustomersRoutes`, `ProfileRoutes`, `AuthRoutes` e `WorkOrdersRoutes` (rotas + bindings Kortex por módulo), com injeção por construtor.
- O helper `appScopedRoute` (`lib/core/ui`) elimina o boilerplate de `MaterialPageRoute` + `KortexScope` + `KortexProvider` + `readKortex` + auto-dispose nas rotas de módulo.
- `AppEntry` recebe `deps` e delega a navegação de clientes, perfil, auth e work orders aos módulos; o comportamento observável foi preservado.
- Decisão registrada em `docs/architecture/adr-002-app-shell-di-route-bindings.md`; plano e divisão paralela em `docs/plan/epics/epic-06-hardening-qualidade.md` (UC-06.05).

### 3. Regra
- Cada módulo deve expor seu route/scope builder e receber apenas as portas que usa; o shell só orquestra gate, lifecycle e rotas.
- Usar `appScopedRoute` para rotas com um único controller; `KortexScope` manual só quando a rota precisar de múltiplos providers.
- Refator é behavior-preserving: a suíte completa é a rede de segurança.

### 4. Evidência
- `app_entry.dart`: 487 -> **168 linhas**; `KortexScope`/`KortexProvider` no shell: 13 -> **0**.
- Gate: `test/app/app_entry_boundaries_test.dart` falha se `AppEntry` voltar a conter `KortexScope(`/`KortexProvider<`.
- `flutter analyze --fatal-infos` => `No issues found!`; `flutter test` => **179 passed, 0 failed**.

### 5. Paralelização segura
- T1 (`AuthRoutes`) e T2 (`WorkOrdersRoutes`) podem rodar em worktrees separados porque só criam arquivos de módulo e barrels distintos.
- `lib/app/app_entry.dart` é **exclusivo da T3** (integração); T1/T2 não tocam o shell, eliminando o conflito de índice/merge.
- Gate de fronteira (T3) deve falhar se `AppEntry` voltar a conter `KortexProvider<` de controller de módulo.
- **Execução real**: subagentes de T1/T2 atingiram o limite de passos antes do commit; T1 foi concluído por `agy01@59993bf1` e T2/T3/T4 pelo orquestrador. O desenho de paths disjuntos evitou colisão; o fallback serial não invalidou a divisão.
- **Gotcha de path**: `import '../../../../core/ui/...'` em `lib/modules/<m>/ui/` funciona por *clamp* de URI do Dart, mas o caminho explícito correto é `../../../core/ui/...` (3 níveis). Normalizado em customers/profile/auth; usar 3 níveis em novos módulos.

## 2026-11-22 — UC-07.01: fundação de configurações locais

### 1. Decisão
- `app_settings` key/value (`key`, `value`, `updated_at_utc`) na migration `v11`; `app_database` em `dbVersion: 11`.
- Catálogo `SettingKey` com defaults seguros (`require_checklist_template=true`, `require_receiver_document=false`), `SettingsSnapshot` imutável, porta e use cases `GetSettings`/`UpdateSetting`.
- Valores persistidos como `'true'`/`'false'`; valor inválido falha com `ERR_CONFIGURACAO_VALOR_INVALIDO`; chave desconhecida com `ERR_CONFIGURACAO_CHAVE_INVALIDA`.
- Decisão registrada em `docs/architecture/adr-003-settings-locais-tipadas.md`.

### 2. Barrels
- `settings/.index.dart` reexporta apenas `data/`, `domain/` e `features/`; `domain/.index.dart` reexporta entities/ports/value_objects.
- Arquivos de `data/` e `features/` importam somente `../domain/.index.dart`; `app_database` importa `settings/data/.index.dart`.
- **Dívida global**: há ~183 imports relativos profundos em `lib/modules`; migrar por módulo em fatia de hardening separada, sem misturar com UC funcional.

### 3. Evidência
- `flutter test test/modules/settings` => `+10 All tests passed!`; `flutter analyze --fatal-infos` => `No issues found!`; suíte completa => `+190 All tests passed!`.

### 4. Gotcha de teste
- `group(..., timeout: ...)` **não** existe no wrapper do `flutter_test` (só `skip`/`retry`); timeout é por `test`. Testes pesados de PBKDF2 estouravam 30s sob carga paralela; helper `_slowTest` com `Timeout(2min)` estabilizou `credential_recovery_test.dart` (commit `cd2c6c7`).

### 5. UI de configurações (UC-07.02)
- `SettingsController` usa `KortexSignal` para `loading/saving/snapshot/error/success`; `KortexListener` dispara `AppFeedback.showSuccess/showError` fora do build (sem `setState`).
- `SwitchListTile` com `minTileHeight: 56` garante alvo >=48dp; `SettingsRoutes.edit()` usa `appScopedRoute`.
- Entrada na Home via callback `onSettings`; `AppDependencies`/`ServiceTrackApp` recebem `ISettingsRepositoryPort`, com `MemorySettingsRepository` como fallback de teste e `SettingsSqliteRepository` no `main.dart`.
- Evidência: 4 testes de UI/controller; suíte completa **194 verdes**; análise limpa.

## 2026-11-22 — CI GitHub: path deps não existem no runner

### 1. Sintoma
- **Todos** os runs recentes do GitHub Actions falhavam no passo `flutter pub get`: `could not find package dnolib at "../.dnolib"` (exit 66). O Gitea não possui workflow de CI.

### 2. Causa
- `pubspec.yaml` usa path deps de desenvolvimento (`../.dnolib`, `../kortex`). O checkout do runner só contém o repo do app; os diretórios irmãos não existem.
- `dnolib` não está no pub.dev nem no GitHub; `kortex` está no GitHub, mas o path dep exige o checkout local.

### 3. Fix
- Vendor de CI: `ci/vendor/dnolib.tar.gz` e `ci/vendor/kortex.tar.gz`, gerados por `git archive HEAD` via `scripts/ci/vendor-deps.ps1`.
- Workflow extrai os tarballs para `../.dnolib` e `../kortex` antes do `flutter pub get`.
- `pubspec.yaml` local permanece intacto; o vendor é snapshot de CI, não cópia de desenvolvimento.

### 4. Prevenção
- Ao atualizar `../.dnolib`/`../kortex`, rodar o script e commitar os tarballs no mesmo commit.
- CI que depende de path dep externo precisa de bootstrap explícito; nunca assumir que o runner tem os irmãos.
- Verificação real: GitHub Actions run `45079552556` passou (vendor → pub get → analyze → 194 testes).

## 2026-11-22 — UC-07.03: integração de políticas com fail-closed

### 1. Decisão de implementação
- `GetSettings` é a **fonte única** no `WorkOrderListController`; bools de política removidos de `AppDependencies`, `ServiceTrackApp` e `WorkOrdersRoutes`.
- A política é relida **por operação** de conclusão; falha de leitura aborta com código de settings (sem default silencioso).
- `require_checklist_template` alimenta `checklistProofPort.requireTemplate`; `require_receiver_document` valida documento e falha com `ERR_ASSINATURA_DOCUMENTO_PROTECAO_INDISPONIVEL` enquanto `kDocumentAtRestProtectionAvailable=false` (D-01/C-01).
- A UI consulta a política **antes** de abrir o diálogo; se documento é exigido e a proteção está indisponível, não renderiza o campo e mostra erro.

### 2. Testes de segurança
- SEC-02: documento exigido é validado na operação.
- SEC-03: settings indisponível aborta sem persistir.
- SEC-04: documento não é coletado quando proteção está indisponível (widget test).
- SEC-07: guard do repositório deixa OS em `IN_PROGRESS`, sem assinatura/check-out.
- SEC-08: `require_checklist_template=false` não relaxa INV-03.

### 3. Evidência
- `flutter analyze --fatal-infos` => `No issues found!`; `flutter test` => **204 passed**.
- Gate 2.5: APROVADO COM CONDICIONANTES (Média); SEC-01..SEC-08; INV-SEC-28..32.
- CI GitHub run `45081277660` verde.

### 4. Gate 3 (review)
- Veredito: APROVADO COM RESSALVAS (Média). Nada bloqueava merge; SEC-01..08 conformes.
- Corrigidos: M-01 (`SettingsSnapshot.==` itera todo o catálogo), M-02 (UI usa a mesma capacidade do controller), M-04 (testes de falha de load/update da UI), B-02/B-03/B-04 (docs/UX).
- Deferidos: M-03 (recuperação de settings corrompido), M-05 (método `completeWorkOrder` longo), B-01 (fallback de settings em produção).
- Ressalva de processo: Red-Before-Green sem prova temporal nos commits; registrar `[RED]` no corpo do commit no próximo UC.

### 5. Gate 4 (QA)
- Veredito: APROVADO COM RESSALVAS (Alta), sem bloqueadores (`qa-review-v0.21.0.md`).
- Corrigidos também M-03 (reset de settings corrompido com `restoreDefaults`), M-05 (`_policyError`) e B-01 (`settingsRepository` obrigatório); A1..A7 tratados ou documentados.
- Evidência: `flutter test` => **204 passed**; análise limpa; gate de schema OK; CI `origin/main` run `45081277660` verde.

## 2026-11-22 — OPS-EPIC06-RESIDUAL: fechamento do EPIC-06

### 1. Entregas
- UC-06.01: catálogo `EvidenceFailureCodes` ganhou `busy` (`ERR_ASSINATURA_EM_PROCESSAMENTO`); `git grep "ERR_" lib/` só encontra catálogos e comentários.
- UC-06.02: `Size(48, 48)` literal migrado para `kMinTouchTargetSize` em lock, recuperação de PIN, item de checklist e canvas; zero ocorrências restantes.
- UC-06.03: `SignaturePadWidget` virou `StatelessWidget` + `SignaturePadController` (KortexSignal `saving`/`error`); `setState` zero em `lib/`. Exceções de `StatefulWidget` (sem `setState`) documentadas no épico: shell de lifecycle e formulários com `TextEditingController`/`FormState`.
- UC-06.04: gate `test/architecture/failure_codes_gate_test.dart` extraído em função pura com prova de não vacuidade (`filesScanned > 0`) e prova negativa (fixture `ERR_NOVO_CODIGO` reprova).

### 2. Gotchas (custo real medido nesta fatia)
- `dart format <diretório>` reformatou 17 arquivos fora do slice (drift de formatter no repo) e inflou o diff de `pin_recovery_page` em ~70 linhas. **Regra**: formatar sempre por **lista explícita de arquivos do slice** e revisar `git status` logo depois; o que não é do slice volta com `git checkout --`.
- `pumpAndSettle` **nunca** assenta enquanto um `CircularProgressIndicator` de `loading` está na árvore: o teste de captura válida estourou por timeout porque a rasterização (`Picture.toImage`) não completa sob o relógio sintético. **Fix**: injetar `SignatureController` fake (`isEmpty`/`toPngBytes` sobrescritos) e usar `tester.pump()`; o encode real não pertence ao widget test.
- `claims claim -add-paths` é **modificador booleano**, não uma opção com valor: chamar `claim -add-paths <arquivo>` reprova com "claim exige -slice, -owner e -paths". Para ampliar o claim do próprio dono: `claims claim -slice <S> -owner <O> -paths <novo-arquivo> -add-paths`.

### 3. Evidência
- `flutter analyze --fatal-infos` => `No issues found!`; `flutter test` => **210 passed**; `git grep "setState(" lib/` e `git grep "Size(48, 48)" lib/` => zero.

## 2026-11-22 — UC-04.09: modelos de checklist alcançáveis (seed + cadastro)

### 1. Entregas
- `ChecklistMigration.v12()`: seed idempotente (`INSERT OR IGNORE`) de 3 modelos (`Instalação Split`, `Manutenção Preventiva`, `Vistoria Rápida`) com 8 itens; `createAppDatabase()` em `dbVersion: 12`.
- `ChecklistTemplateFormController` (Kortex; rascunho com id por item) + `ChecklistTemplateFormPage` (`StatelessWidget`), com validação delegada a `ChecklistTemplate.tryCreate`/`ChecklistItem.tryCreate`.
- `ChecklistsRoutes` (`list()`/`form()`) e ação `wo-templates` no AppBar da lista de OS: a página de modelos deixou de ser código morto.
- `kortex` migrado de path para pub.dev `^0.2.1`; `ci/vendor/kortex.tar.gz` removido e `scripts/ci/vendor-deps.ps1` restrito a `dnolib`.

### 2. Gotchas (custo real medido nesta fatia)

- **Pacote local publicado vira workspace e quebra a dependência de path.** Sintoma: todo o app parou de compilar com `Error: Error when reading '../kortex/lib/kortex.dart': O sistema não pode encontrar o caminho` em **todas** as units que importam `package:kortex/kortex.dart`. Causa: o repositório virou pub workspace (`packages/kortex`, `resolution: workspace`), então `../kortex/lib` deixou de existir. **Fix**: trocar a dependência para a versão publicada (`kortex: ^0.2.1`), confirmar `pubspec.lock` com `source: hosted` + `url: https://pub.dev` e **tirar o pacote do vendor do CI** (tarball + extração), senão o CI continua montando `../kortex` para uma dependência que já não é local.

- **`ChecklistTemplateListPage` existindo não provava entrega.** Código morto compila, passa no `analyze` e o teste de widget dele passa (o teste monta a página direto). O que faltava era **rota**: `grep ChecklistTemplateListPage lib/` dava 2 ocorrências (página + controller) e zero chamadores. **Regra prática**: ao auditar "UI entregue", grepar o **chamador** da página, não a página; e exigir um teste que chegue nela **pela navegação do produto**, não por `home:`.

- **`TextFormField` + `ValueKey(index)` faz o campo herdar o texto do vizinho removido.** Numa lista editável, remover o item 0 troca o conteúdo lógico do índice 0 e o Flutter **reusa o elemento** (mesma key), mantendo o `TextEditingController` interno com o texto antigo — `initialValue` só vale na primeira construção daquele `State`. **Fix**: identidade estável por rascunho (`ValueKey(draft.id)`), com o id vivendo no estado (Kortex), não na página. Prova: mutar para `ValueKey(index)` reprova o teste com `Found 1 widget with text "Primeiro item"` quando nenhum era esperado.

- **Red-Before-Green por mutação quando o teste nasce depois do código.** Os testes de tela foram escritos após a implementação (não havia como montar a tela antes dela existir). Para não entregar teste tautológico, o RED foi obtido por **mutação dirigida**: trocar `ValueKey(draft.id)` → `ValueKey(index)` e remover a ação `wo-templates` da rota. Ambas reprovaram (`+0 -2` no segundo caso) e voltaram a passar ao restaurar. Registrar a mutação no corpo do commit, não só o verde.

- **`INSTALL_FAILED_USER_RESTRICTED: Install canceled by user` não prova que instalar seja impossível — e eu registrei isso como bloqueio de ambiente.** [FATO] O erro saiu em duas tentativas de `adb install -r -t`; na tentativa seguinte, **sem alterar nenhuma opção do aparelho**, o mesmo comando devolveu `Success` e o logcat registrou `PACKAGE_ADDED com.servicetrack.service_track`. [FATO] A atribuição que eu havia gravado ("falta habilitar *Instalar via USB*, exige conta Mi") era **especulação apresentada como causa medida** — está refutada: o transporte (Wi-Fi/USB) é irrelevante para essa string e a opção estava operante. [INFERÊNCIA] A mensagem descreve o **instalador MIUI recusando aquela sessão** (fluxo de verificação/confirmação), não ausência de caminho nem de permissão. **Regra de método**: erro de instalação com o device em `device` se resolve **retentando e lendo o logcat**; declarar "ambiente bloqueado" a partir de uma string de erro encerra a investigação sem causa comprovada. A parte válida do registro anterior fica: um E2E escrito nesse estado é código **nunca executado** e não pode ser reportado como validado.

### 3. Evidência
- `flutter analyze --fatal-infos` => `No issues found!`; `flutter test` => **221 passed**.
- REDs registrados: seed (`Expected: length 3 / Actual: []`), controller (`Method not found: 'ChecklistTemplateFormController'`), identidade de item (`Found 1 widget with text "Primeiro item"`), alcançabilidade (`+0 -2` sem `wo-templates`).
- Bloqueio de device: `adb install -r -t app-debug.apk` => `INSTALL_FAILED_USER_RESTRICTED` nas duas primeiras tentativas; `Success` na terceira, **sem mudança de configuração** (atribuição anterior refutada — ver seção 2). **Sessão seguinte (2026-11-23): o mesmo comando voltou a dar `Success` de primeira** (`adb_install_need_confirm` já persistido em `0`), confirmando a intermitência por sessão do instalador MIUI — padrão medido: falha em rajada, sucesso isolado, sem correlação com configuração.
- **Workaround tente com sucesso parcial**: `adb push` + `adb shell pm install -r -t /data/local/tmp/st.apk` => `Success` (uma vez). Tentativas subsequentes de `adb install -r -t` e de `pm install` voltam a falhar com `INSTALL_FAILED_USER_RESTRICTED` — bloqueio intermitente do instalador MIUI sobre o repositório. Resultado: `flutter test integration_test/epic04_flow.dart -d ...` não conseguiu instalar o app. **A conclusão do E2E (`epic04_flow.dart`) está pendente de instalação bem-sucedida**; o probe de boot/GPS (`epic04_probe.dart`) já foi executado com sucesso (rota = onboarding; GPS OK em 2558 ms).

## 2026-11-25 — EPIC-04 E2E device verde: 3 causas raiz distintas

- **`ON CONFLICT(...) DO UPDATE` quebra no SQLite 3.22 (Android 10/API 29).** [FATO] E2E device falhou com snackbar "Não foi possível salvar a resposta do checklist."; o repo capturava Exception genérica. Android 10 vem com SQLite 3.22.0; upsert `ON CONFLICT DO UPDATE` exige 3.24+. `flutter test` host (sqflite_common_ffi, SQLite moderno) não detecta. **Fix**: `INSERT OR REPLACE` quando todas as colunas da row são fornecidas e a tabela não tem FKs dependentes do rowid. **Regra**: ao mirar Android 10, evitar `ON CONFLICT DO UPDATE`; preferir `INSERT OR REPLACE`/`ConflictAlgorithm.replace` ou update-then-insert.
- **Integration test em device: `pump(ms)` único não dá tempo real para I/O async.** [FATO] Após tap conforme, `selectedStatus` ficou `null` por 30s; save SQLite era real async. **Fix**: polling wall-clock (`DateTime.now()` + `tester.pump(100ms)`) como `esperarPor`, com timeout e diagnóstico de tela; retap defensivo uma vez se status null após 5s (hit-test miss).
- **`AlertDialog` + `LayoutBuilder` (ex.: `Signature`) quebra intrinsics.** [FATO] "LayoutBuilder does not support returning intrinsic dimensions" ao abrir dialog de conclusão. **Fix**: `content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(...))`.
- **E2E keys envelhecem com refactor de UI.** Home refatorada removeu `home-customers/home-work-orders`; E2E passou a usar `home-new-work-order` + drawer keys estáveis (`drawer-customers`, `drawer-work-orders`) e abertura por `ScaffoldState.openDrawer()` (sem tooltip/localização).

## 2026-11-23 — Fase A da aposentadoria da dnolib: kortex 0.2.3 + kortex_lint

- **Decisão do PO**: aposentar `dnolib`. Substitutos no pub.dev: `kortex` (reatividade), `kortex_lint` (lints de analyzer), `kortex_persist` (persistência) — e `kortex_lib` (que conteria `brlib`/`core`/`sqlite`) **ainda não publicado** (404 no pub.dev, existe no GitHub com `publish_to: none`). Migração será gradual; a Fase A só depende do que já está publicado.
- **Fase A executada**: `kortex ^0.2.1 → ^0.2.3` e `kortex_lint ^0.1.2` em `dev_dependencies`; plugin ativado no `analysis_options.yaml`. `flutter pub get` → lock com `kortex 0.2.3` (hosted) e `kortex_lint 0.1.2` (hosted). `flutter analyze --fatal-infos` → **No issues found!**; `flutter test` → **+221**.
- **Gotcha do `kortex_lint` (custo real medido)**: é um **plugin de analyzer** (`analysis_server_plugin`), não arquivo de regras `include:`. A chave `plugins:` vai no **topo** do `analysis_options.yaml` (fora de `analyzer:`) — colocá-la dentro de `analyzer:` gera `analysis_options_deprecated_plugins` e falha o `--fatal-infos`. A doc oficial (dart.dev/tools/analyzer-plugins) confirma formato *top-level*. Também precisa entrar em `dev_dependencies` para o pub resolver.
- **Bloqueio do restante (Fase B/C)**: sem `kortex_lib` publicado, não há substituto para os ~150 imports de `Result`/`ValidationError`, `Money`, `brlib` e `sqlite` (192 imports de `dnolib` no total). Fase B fica para outra sessão, após publicação.
- **`flutter analyze` CLI e o LSP da IDE divergiram — e só o LSP viu 6 vazamentos reais.** [FATO] `flutter analyze --fatal-infos` reportou `No issues found!` (duas vezes, 241 s e 70,8 s), enquanto o `dartAnalysisLSP` do VS Code reportou 6 × `avoid_undisposed_kortex_signal` em `pin_recovery_controller.dart`. [FATO] O controller era o **único dos 16** sem `onDispose()`/`autoDispose()` — os 6 sinais (`step`, `masterPassword`, `newPin`, `passwordError`, `pinError`, `loading`) nunca eram disposed. Vazamento real, não falso positivo. **Erro de método meu**: afirmei "nada a limpar" com base só no CLI, generalizando a partir de uma fonte — exatamente o que o mandato cognitivo proíbe. **Regra**: quando CLI e LSP divergem, investigue a divergência e trate o diagnosticamente mais rico como sinal, nunca assuma que o CLI limpo prova ausência de problema; e ao auditar "todos os controllers fazem dispose", varredura sistemática por arquivo (deck `decl` vs `dispose`) — não basta ver que `onDispose()` existe em alguns. **Fix**: `onDispose()` com os 6 `.dispose()` no padrão dos outros controllers; varredura confirmou 0 sinais órfãos em 16 controllers.

## 2026-11-25 — D-01/C-01: cifragem de campo PII em repouso (SQLite) + gates

- **Padrão adotado (mitigação parcial, técnica)**: `IDocumentAtRestCipher` (`lib/core/security/document_at_rest_cipher_port.dart`) + `AesGcmDocumentAtRestCipher` (AES-GCM 256, chave 32 bytes em `flutter_secure_storage` com `KeychainAccessibility.first_unlock_this_device` / `encryptedSharedPreferences: true`, prefixo `enc:v1:`). `WorkOrderSqliteRepository` cifra em save e decifra em read de `signature_document_number`; sem cifrador ou payload inválido => fail-closed `ERR_ASSINATURA_DOCUMENTO_PROTECAO_INDISPONIVEL` / `ERR_DOCUMENTO_PROTECAO_INDISPONIVEL`. `MemoryWorkOrderRepository` espelha a invariante.
- **Wiring**: cifrador nasce no composition root `AppServices.fromDatabase()` e é injetado por `AppPages`/`*Routes.fromDatabase` até os repos. Evita cifrador ad hoc por módulo.
- **Gate M-08 (failure codes)**: literal `ERR_*` em `lib/` fora de `*_failure_codes.dart` reprova o teste de arquitetura. Novo módulo de segurança exigiu `lib/core/security/document_at_rest_failure_codes.dart`.
- **Flip de capacidade quebra testes por desenho**: ao tornar `kDocumentAtRestProtectionAvailable=true`, teste que provava "não coleta quando proteção indisponível" passou a coletar. Fix correto: tornar a dependência explícita no teste (`documentAtRestProtectionAvailable: false`) em vez de enfraquecer a asserção.
- **Residual honesto**: não é full-db encryption; residual LGPD (base legal/finalidade/retenção/minimização), iOS/Keystore por fabricante e backup cifrado controlado permanecem abertos/parciais (ver D-01, ADR-001 C-01/C-02, EPIC-08 proposto).

## 2026-11-25 — PDF: asserção de conteúdo real (não só bytes)

- **`%PDF-` não prova conteúdo**. Para validar seções/texto do relatório gerado pelo `pdf` package, extrair texto dos streams: decodificar bytes como `latin1`, descomprimir streams `FlateDecode` (`zlib`), e varrer literais `(...) Tj/TJ`/arrays. Útil para testes que precisam confirmar que dados do domínio chegaram ao PDF sem acoplar a layout exato. [FATO, usado no commit M2 de EPIC-05]

## 2026-11-23 — E2E de device EPIC-04: link perdido, dump enganoso e tap fantasma

### 1. `did not complete` + `No tests were found` após silêncio = host perdeu o device, não teste travado
- **Sintoma**: `flutter test integration_test/epic04_flow.dart -d 192.168.67.65:5555` instalou (`37,7s`), imprimiu `00:00 +0: EPIC-04...` e ficou **18:31 em silêncio** até `did not complete` + `No tests were found`.
- **Por que não era stall do teste**: todas as esperas (`esperarPor`) têm deadline (máx 120 s) e terminam em `fail()` imprimindo a tela — um stall de rota falharia em ~90 s, nunca em 18 min de silêncio. No aparelho: app em foreground (`MainActivity`), secure storage sem credenciais (rota onboarding esperada), nenhum `.db` criado.
- **Fix de instrumentação (fica no código)**: heartbeat `debugPrint('[E2E] ...')` a cada 10 s dentro da espera + log da tela no timeout. O heartbeat aparece no **logcat mesmo que o host perca o observatory** — foi o que diferenciou, na rerun seguinte, perda de link (zero eventos no host) de falha de asserção real (`TIMEOUT CustomerListPage ... tela: Home - ServiceTrack`). Reruns de E2E em device: `--no-uninstall` para perícia post-mortem + `screen_off_timeout=1800000` para a tela não apagar no meio do fluxo.
- **Critério de triagem**: vale para qualquer projeto Flutter com `integration_test` em device via adb-wifi → **proposta de promoção** à skill `flutter-device-e2e` (`references/helpers.md`: seção de heartbeat + diagnóstico de `did not complete`).

### 2. `disabled, disabled` no dump do IconButton não significa `onPressed` nulo
- **Sintoma**: o dump de `IconButton-[<'home-customers'>]` mostrava `(tooltip: Clientes, disabled, disabled, ...)` e o tap não navegava — leitura inicial: "botão desabilitado".
- **Causa do engano**: `ButtonStyleButton.debugFillProperties` emite `FlagProperty('enabled', ..., ifFalse: 'disabled')`; os dois `disabled` são ruído desse diagnóstico, não prova de callback nulo.
- **Veredito por medição, não por leitura de dump**: `tester.widget<IconButton>(key).onPressed == null` → `false`. Botão habilitado; hipótese de fiação nula **refutada** com uma linha, sem reler framework. **Regra**: dump de widget sugere, só o campo lido prova.
- **Critério de triagem**: vale para qualquer widget test Flutter → **proposta** à skill `flutter-device-e2e` (snippet de checagem de habilitado antes do tap).

### 3. Correção de teclado refutada para este caso (registrar a refutação, não só o fix)
- O `tocar` foi reforçado (unfocus + `pumpAndSettle` com fallback antes de mirar) sob a hipótese "teclado desloca a coordenada". Três execuções depois: mesmo elo travado, mesmo sintoma. Hipótese **refutada pelo experimento**, e o reforço ficou como higiene (não como causa).
- Em aberto: tap acerta algo sem throw e sem navegar, com botão habilitado — bissecar gesto absorvido (`find.byTooltip('Clientes')`) vs. rota falhando no build com repos reais (reproduzir headless com fakes). Uma hipótese por vez.

## 2026-11-25 — UC-08.04: D-03 stale, rotina D-02/osv-scanner em CI

- **Dívida documentada pode estar obsoleta — confirme no código antes de implementar.** [FATO] D-03 dizia "`verifyPassword` sem rate-limit (só o PIN tem bloqueio)"; o código já tinha lockout/backoff exponencial (`passwordFailCountKey`/`passwordLockedUntilKey`, limpa em sucesso) e testes `credential_recovery_test` (A1 + expiração). Implementar "rate-limit" teria sido retrabalho/desperdício. **Regra**: antes de executar item de DEBITOS, validar estado atual no código+testes e atualizar o débito por evidência.
- **`dart pub audit` ausente no Dart 3.13.5**; rotina reproduzível: `flutter pub outdated --json` (sinaliza `isCurrentAffectedByAdvisory`) + `osv-scanner scan source -L pubspec.lock` (v2) no CI. [FATO]
- **osv-scanner em CI: pinar binário de release, não adivinhar URL de install script.** [FATO] `https://raw.githubusercontent.com/google/osv-scanner/main/scripts/install.sh` retornou 404; fix: download pinado `https://github.com/google/osv-scanner/releases/download/v2.7.1/osv-scanner_linux_amd64` + `chmod +x`. Tornar ausência fatal no CI (`REQUIRE_OSV_SCANNER=1`) para o gate não degradar silenciosamente.
