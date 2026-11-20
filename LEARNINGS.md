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
