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
- **EPIC-07**: **Fatiado** (UC-07.01→07.02→G2.5/07.03) — `docs/plan/epics/epic-07-configuracoes-politicas.md`.
- **Dívidas**: `docs/DEBITOS.md` D-01..D-05; D-05 mitigado.

## Próximo Passo Acionável
1. **EPIC-07**: iniciar UC-07.01 (settings) → UC-07.02 (UI) → Gate 2.5/UC-07.03.
2. **EPIC-06 residual**: fechar UC-06.01 (literais `ERR_*` em auth) e UC-06.02 (touch targets residuais).
3. **E2E device EPIC-04**: validar template→OS→checklist→conclusão.
4. **Push**: pendente de autorização explícita do PO + 3 evidências.

## Travas Vivas
- **Claims**: nenhum ativo; verificar `claims status` antes de mutar.
- **Push**: somente com autorização explícita do PO + 3 evidências.
- **Greenfield Lock**: **DESTRAVADO**.
