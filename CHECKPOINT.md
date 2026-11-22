# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-22)
- **Branch**: `main` (sincronizada com `origin/main` após push autorizado).
- **EPIC-00/01/02/03**: **CONCLUÍDAS** (`qa-review-v0.1.0..v0.17.0`).
- **EPIC-04**: **Em reconciliação** — código parcial (UC-04.01–04.04), sem laudos/gates; lacunas D-05, respostas em memória, assinatura duplicada. Depende também de **EPIC-07 (D2)**. Ver `docs/plan/epics/epic-04-checklists-evidencias.md` §6.
- **EPIC-06**: **Pronta para iniciar** (hardening/qualidade transversal) — `docs/plan/epics/epic-06-hardening-qualidade.md`.
- **EPIC-07**: **Planejada** (configurações/políticas locais; D2) — `docs/plan/epics/epic-07-configuracoes-politicas.md`.
- **Dívidas**: `docs/DEBITOS.md` D-01..D-05; N-01..N-07 na proposta de mitigação.

## Próximo Passo Acionável
1. **UC-04.05/ADR-001**: obter aprovação Arch (D1/D3/D4/D5); D2 já decidido pelo PO (obrigatório por política/configuração).
2. **EPIC-07**: detalhar/implementar UC-07.01/07.02 para suportar D2 com default seguro.
3. **EPIC-06**: paralelo controlado (M-01/M-02/M-07/M-08) sem colidir com work_orders/checklists.

## Travas Vivas
- **Claim ativo**: nenhum (verificar `claims status` antes de mutar).
- **Push**: somente com autorização explícita do PO + 3 evidências.
- **Greenfield Lock**: **DESTRAVADO**.
