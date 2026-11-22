# Diário de Bordo Técnico — LEARNINGS.md

Este arquivo registra aprendizados, armadilhas superadas e decisões técnicas do **ServiceTrack**.

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
