# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-22)
- **Branch**: `main`; topo = planejamento do UC-06.05 (ver `git log -1`); sem claims ativos.
- **EPIC-00/01/02/03**: **CONCLUÍDOS** (`qa-review-v0.1.0..v0.17.0`).
- **EPIC-04**: **Implementado em código/testes** (UC-04.01–04.08; D-05 mitigado); **E2E device pendente**.
- **EPIC-06**: **Em andamento** — **UC-06.05 concluído** (AppDependencies + `*Routes` + `appScopedRoute`; `AppEntry` em **168 linhas/0 providers**; gate de fronteira; `qa-review-v0.20.0.md`). UC-06.01/02 residuais; UC-06.03/04 pendentes. Ver [ADR-002](docs/architecture/adr-002-app-shell-di-route-bindings.md).
- **EPIC-07**: **Concluído** — UC-07.01/02/03 (settings + UI + integração fail-closed D-01/C-01). G2.5/G3/G4 aprovados com ressalvas (`qa-review-v0.21.0.md`).
- **CI GitHub**: **verde** no run `45079552556` (vendor de deps locais em `ci/vendor/`). Gitea sem workflow.
- **Dívidas**: `docs/DEBITOS.md` D-01..D-05; D-05 mitigado.

## Próximo Passo Acionável
1. **EPIC-04**: validação E2E device pendente.
2. **EPIC-06 residual**: UC-06.01/02 residuais.
3. **Push**: pendente de autorização explícita do PO + 3 evidências.

## Travas Vivas
- **Claims**: nenhum ativo; verificar `claims status` antes de mutar.
- **Push**: somente com autorização explícita do PO + 3 evidências.
- **Greenfield Lock**: **DESTRAVADO**.
