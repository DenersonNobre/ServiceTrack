# Contexto de Projeto — ServiceTrack (Mobile Standalone)

> **Fonte única de contexto para agentes de IA** (Antigravity, OpenCode, Codex, Cursor).
> Não duplicar regras aqui: a profundidade vive nos documentos em `docs/`.

---

## 1. Mandato & Não-Negociáveis

- **Arquitetura Standalone**: O app é 100% autocontido no smartphone. Zero chamadas para backend/nuvem no escopo atual.
- **Motor Reativo Obrigatório**: Toda gerência de estado de tela deve utilizar **`kortex`** (`KortexSignal`, `IKortexPage`, `KortexWatch`, `KortexScope`). Nunca introduzir GetX, Provider avulso ou ChangeNotifier desgovernado.
- **Widgets Stateless por Padrão**: Preferir `StatelessWidget`. Evitar `StatefulWidget`/`setState`; estado de tela/local reativo deve ser modelado com Kortex. `StatefulWidget` só com justificativa técnica explícita (ex.: lifecycle nativo de controlador de plataforma).
- **Infraestrutura**: Utilizar **`kortex_lib`** (pub.dev) para utilitários comuns, `Result`/`ValidationError`, regras de validação brasileira (`brlib`) e banco SQLite. `dnolib` está aposentada.
- **Composição & Rotas**: `AppDependencies` é o composition root; cada módulo expõe seu `*Routes` usando `appScopedRoute` para rotas com um controller. `AppEntry` não compõe controllers de módulo; `KortexScope` manual só para múltiplos providers, com justificativa. GetX/service locator seguem proibidos. Detalhe: `docs/architecture/adr-002-app-shell-di-route-bindings.md`.
- **Regra de Orientação de UI**:
  - Smartphones (`< 600dp`): Estritamente Retrato (`Portrait-Only`).
  - Tablets (`>= 600dp`): Suporte a Paisagem (`Landscape`) com layout Master-Detail.
- **Tratamento de Falhas**: Fluxo esperado deve retornar `Result<T>` ou falha tipada de negócio. Exceções são restritas a I/O, corrupção de disco ou falhas catastróficas.
- **Alvos Táteis de Campo**: Botões e campos interativos devem ter no mínimo `48dp` x `48dp`.
- **Governança Estrita de Personas (Oráculo Pipeline)**:
  - O agente principal atua **estritamente como Orquestrador** (`/orchestrator`), coordenando fatias, claims e invocação de subagentes.
  - Toda implementação de código de produção e testes de unidade/widget deve ser executada por um subagente **Coder** (`invoke_subagent` com role `Coder`) com TDD Red-Before-Green.
  - Toda fatia concluída pelo Coder deve passar por auditoria independente de um subagente **Reviewer** (`invoke_subagent` com role `Reviewer`) validando Diff Budget, SOLID, estilo e ausência de regressões antes de qualquer merge/conclusão (Gate 3).
  - A validação final (Gate 4) é executada com suíte completa (`flutter analyze` e `flutter test`) antes do commit e liberação do claim.
  - É expressamente proibido ao agente orquestrador escrever diretamente código de produção sem a esteira de subagentes.

---

## 2. Comandos Essenciais

- **Build / Verificação**: `pwsh build-all.ps1` (ou `flutter analyze --fatal-infos`) — zero warnings.
- **Testes**: `flutter test` — exit code 0 obrigatório.
- **Claims**: `tools/bin/claims claim -path . -slice <UC> -owner <agente> -paths <arquivos>`

---

## 3. Onde Está O Que (Ponteiros Canônicos)

- **Produto & Personas**: `docs/product/PRD.md` (v2.0.0 Standalone).
- **Domínio, Invariantes e Portas**: `docs/architecture/SPEC.md` (`INV-01` a `INV-06`).
- **Design Tokens & Styleguide**: `docs/architecture/DESIGN.md` (Deep Petrol Green `#115E59`).
- **Plano Mestre & DAG**: `docs/plan/README.md`.
- **Épico da Fundação**: `docs/plan/epics/epic-00-fundacao.md`.
- **Épico em Andamento**: `docs/plan/epics/epic-06-hardening-qualidade.md` (UC-06.05 — Composition Root & Route Bindings).
- **Próximo Épico de Produto**: `docs/plan/epics/epic-07-configuracoes-politicas.md` (Configurações & Políticas Locais).
