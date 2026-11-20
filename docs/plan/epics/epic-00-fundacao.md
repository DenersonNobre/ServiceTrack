# EPIC-00: Fundação Técnica Flutter (Mobile Standalone)

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC00` |
| **Dependências Diretas** | Nenhuma (Alicerce Técnico) |
| **Prioridade** | Crítica (Bloqueante para qualquer código de negócio) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Concluído` |
| **Referências** | [docs/product/PRD.md](../../docs/product/PRD.md) \| [docs/architecture/SPEC.md](../../docs/architecture/SPEC.md) \| [docs/architecture/DESIGN.md](../../docs/architecture/DESIGN.md) |

---

## 1. Objetivo & Escopo da Fundação

Estabelecer a fundação de engenharia estéril e autocontida para o **ServiceTrack Mobile (Flutter Standalone)**, eliminando necessidade de servidores externos, configurando banco de dados relacional local com Drift (SQLite), biblioteca de geração nativa de PDF, sistema de temas com os Design Tokens do Styleguide v2.1 (Deep Petrol Green) e governança multiagente via Claims.

- **Incluso**:
  - `F0.1`: Topologia Vertical Slice Architecture (`lib/modules/`, `lib/global/`, `test/`).
  - `F0.2`: Toolchain Flutter, script `build-all.ps1` (`flutter analyze`) e dependências pinadas em `pubspec.yaml`.
  - `F0.3`: Test Harness headless para testes de unidade e widgets (`flutter test`).
  - `F0.4`: Governança Git, VCS, Shims, Hooks de Claim & DevSecOps:
    - **Quality Gates Locais (Pre-Commit)**: `gate-secrets.ps1` bloqueando commits de segredos (chaves privadas, `.env`, tokens), `.gitattributes` normalizando LF/UTF-8 e poka-yoke de claims de concorrência.
    - **Proteção de Dados & LGPD em Repouso**: Sanitização de logs, isolamento de fotos locais em armazenamento privado do app e permissões estritas de câmera/GPS.
  - `F0.5`: Banco de dados local Drift (SQLite) configurado com schema tipado e migrações determinísticas.
  - `F0.6`: Pipeline de CI/CD Contínuo (Shift-Left Gate & Release Automation):
    - **CI (Pull Request & Push na main)**: Clean build estéril, `flutter analyze` com zero warnings, `flutter test` com 100% verde e auditoria de dependências via `dart pub outdated`.
    - **Estratégia de Branching & Versionamento**: Trunk-Based Development com branches efêmeras (`feat/*`, `fix/*`). Versionamento Semântico (`SemVer` `vX.Y.Z+build`) acionado por Git Tags (`v1.0.0`).
    - **CD / Build de Artefatos**: Geração automatizada de APK assinado (release) e release notes via GitHub/Gitea Actions ao taguear release.
  - `F0.7`: Shared Kernel com `Result<T, E>`, Value Objects de `GeoPoint` e utilitários de compressão.
  - `F0.8`: Governança documental na **raiz do repositório**:
    - `README.md`: Apresentação executiva, comandos de 1 linha (build/test) e guia rápido.
    - `AGENTS.md`: Contexto único de projeto lido nativamente pelos agentes de IA (~90 linhas, mandatos e ponteiros).
    - `LEARNINGS.md`: Diário técnico para registro de lições e decisões de engenharia.
    - `CHECKPOINT.md`: Protocolo canônico de continuidade entre sessões (<= 60 linhas, ponteiro para o estado real).
- **Não Incluso**:
  - Backend, containers Docker, servidores de API ou banco remoto na nuvem.

---

## 2. Matriz de Features da Fundação

| # | Feature | UCs/Histórias | Independência / Risco | Status |
| :--- | :--- | :---: | :--- | :---: |
| **F0.1** | Topologia Canônica Flutter & VSA | 1 | Independente | `Pendente` |
| **F0.2** | Toolchain, `pubspec.yaml` & Build de 1 Comando | 1 | Depende de F0.1 | `Pendente` |
| **F0.3** | Test Harness Headless (`flutter test`) | 1 | Depende de F0.2 | `Pendente` |
| **F0.4** | Governança Git, VCS, Shims & Hooks de Claim | 1 | Depende de F0.1 | `Pendente` |
| **F0.5** | Banco Local SQLite (Drift Setup) | 1 | Depende de F0.2 | `Pendente` |
| **F0.6** | Pipeline de CI/CD Contínuo de Flutter | 1 | Depende de F0.2..F0.5 | `Pendente` |
| **F0.7** | Shared Kernel & Primitivos Universais (`Result`) | 1 | Depende de F0.1 | `Pendente` |
| **F0.8** | Governança Documental & Matriz de Planos | 1 | Depende de F0.1..F0.7 | `Pendente` |

---

## 3. Definição de Pronto (DoD) da EPIC-00

- [ ] Projeto Flutter configurado na raiz com `pubspec.yaml` contendo:
  - Pacote local: `kortex` (gerenciamento reativo via signals e injeção com `KortexScope`).
  - Pacote local: `dnolib` (na íntegra, com `hide Synapx` / exceto synapx).
  - Dependências nativas: `sqlite3_flutter_libs`, `pdf`, `share_plus`, `geolocator`, `image`, `signature`, `flutter_secure_storage`, `local_auth`.
- [ ] Script `pwsh build-all.ps1` executa `flutter analyze` com zero erros/warnings.
- [ ] Suíte de smoke test executável via `flutter test` com exit code 0.
- [ ] Banco Drift inicializado em memória nos testes e em SQLite local no dispositivo.
- [ ] Shim `tools/bin/claims` ativo no repositório.
- [ ] Zero dependências de backend ou servidores externos.
