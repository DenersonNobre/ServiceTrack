# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-21)
- **Branch**: `main` (commits locais à frente de `origin/main`, sem push — sem autorização do PO).
- **EPIC-00**: **CONCLUÍDA**.
- **EPIC-01**: **CONCLUÍDA** (UC-01.01..UC-01.05, `qa-review-v0.1.0..v0.7.0`).
- **EPIC-02**: **CONCLUÍDA** (UC-02.01..UC-02.04, `qa-review-v0.8.0..v0.11.0`).
- **Dívidas**: `docs/DEBITOS.md` D-01..D-04; observações QA baixas/info em laudos.

## Próximo Passo Acionável
1. Iniciar próximo épico conforme `docs/plan/README.md` (EPIC-03) com pré-flight, claim, TDD e Gate 2.5 conforme superfície.
2. Antes de codar: build/teste verde + claim atômico.

## Travas Vivas
- **Claim ativo**: Nenhum (UC-02.04 liberado após consolidação em 2026-11-21).
- **Pendência**: `docs/plan/reviews/audit-epic-01.md` untracked (de outro agente) — decidir commitar/remover antes do push.
- **Greenfield Lock**: **DESTRAVADO**.
