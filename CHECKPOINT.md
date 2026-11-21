# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-21)
- **Branch**: `main` (commits locais à frente de `origin/main`, sem push — sem autorização do PO).
- **EPIC-00 (Fundação Técnica)**: **CONCLUÍDA** e 100% verde.
- **EPIC-01 (CONCLUÍDA)**: UC-01.01..UC-01.05 concluídas (laudos `qa-review-v0.1.0..v0.7.0`).
  - Desvio PBKDF2 senha+PIN autorizado pelo PO (Gate 2.5 C1, UC-01.01).
- **Dívidas**: `docs/DEBITOS.md` D-01..D-04; observações QA baixas/info em laudos.

## Próximo Passo Acionável
1. Iniciar **EPIC-02 (Clientes & Locais)** conforme DAG — pré-flight, claim, Gate 2.5 conforme superfície.
2. Antes de codar: build/teste verde + claim atômico.

## Travas Vivas
- **Claim ativo**: Nenhum (UC-01.05 liberado após consolidação em 2026-11-21).
- **Greenfield Lock**: **DESTRAVADO** para código de negócio pela conclusão da EPIC-00.