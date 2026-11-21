# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-21)
- **Branch**: `main` (commits locais à frente de `origin/main`, sem push — sem autorização do PO).
- **EPIC-00 (Fundação Técnica)**: **CONCLUÍDA** e 100% verde.
- **UC-01.01 (EPIC-01, Concluída)**: Gates 2.5/3/4 — laudos `qa-review-v0.1.0..v0.3.0`.
- **UC-01.02 (EPIC-01, Concluída)**: Biometria/boot gate/lock screen, Gates 2.5/3/4 — 51/51, analyze limpo, laudo `qa-review-v0.4.0.md`. Barrels `.index.dart` aplicados.
  - Desvio PBKDF2 senha+PIN autorizado pelo PO (Gate 2.5 C1, UC-01.01).
  - Estrutura canônica Flutter/Dart alinhada ao POC `kortex/poc/lib`.
- **Dívidas**: `docs/DEBITOS.md` D-01..D-04. QA: B1-B3 (v0.3.0), A1-A6 (v0.4.0, baixas/info).

## Próximo Passo Acionável
1. Iniciar **UC-01.03** (Desbloqueio por PIN numérico, teclado >=48dp) com novo claim, TDD e Gate 2.5 conforme superfície.
2. Antes de codar: pré-flight build/teste verde + claim atômico.

## Travas Vivas
- **Claim ativo**: Nenhum (UC-01.02 liberado após consolidação Gates 3/4 em 2026-11-21).
- **Greenfield Lock**: **DESTRAVADO** para código de negócio pela conclusão da EPIC-00.
