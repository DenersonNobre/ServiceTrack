# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-22)
- **Branch**: `main` (sincronizada com `origin/main` após push autorizado).
- **EPIC-00/01/02/03**: **CONCLUÍDAS** (`qa-review-v0.1.0..v0.17.0`).
- **EPIC-04**: **Em reconciliação** — código parcial (UC-04.01–04.04 com commits e 19 testes de módulo verdes), mas sem laudos/gates e com lacunas: D-05 (prova 0/0), respostas só em memória, assinatura duplicada. Ver `docs/plan/epics/epic-04-checklists-evidencias.md` §6.
- **EPIC-06**: **Pronta para iniciar** (hardening/qualidade transversal) — `docs/plan/epics/epic-06-hardening-qualidade.md`.
- **Dívidas**: `docs/DEBITOS.md` D-01..D-05; N-01..N-07 na proposta de mitigação.

## Próximo Passo Acionável
1. **EPIC-04 reconciliação**: executar UC-04.05–04.08 (contrato assinatura, SQLite respostas por OS, integração D-05, unificação assinatura) com Gates 2.5/3/4.
2. **EPIC-06 em paralelo controlado**: iniciar M-01/M-02/M-07/M-08 em fatias pequenas sem colidir com work_orders/checklists.

## Travas Vivas
- **Claim ativo**: nenhum (verificar `claims status` antes de mutar).
- **Push**: somente com autorização explícita do PO + 3 evidências.
- **Greenfield Lock**: **DESTRAVADO**.
