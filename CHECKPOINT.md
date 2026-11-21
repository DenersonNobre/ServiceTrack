# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-21)
- **Branch**: `main` (sincronizado com `origin/main` após push autorizado; novos commits locais podem existir).
- **EPIC-00 (Fundação Técnica)**: **CONCLUÍDA** e 100% verde.
- **UC-01.01 (EPIC-01, Concluída)**: laudos `qa-review-v0.1.0..v0.3.0`.
- **UC-01.02 (EPIC-01, Concluída)**: biometria/boot gate/lock, laudo `qa-review-v0.4.0.md`, barrels `.index.dart`.
- **UC-01.03 (EPIC-01, Concluída)**: keypad PIN >=48dp, 55/55, laudo `qa-review-v0.5.0.md`.
  - Desvio PBKDF2 senha+PIN autorizado pelo PO (Gate 2.5 C1, UC-01.01).
- **Dívidas**: `docs/DEBITOS.md` D-01..D-04; observações QA baixas/info em laudos.

## Próximo Passo Acionável
1. Iniciar **UC-01.04** (Recuperação de Acesso Local & Fallback do SO) com claim, TDD e Gate 2.5 (superfície auth/sessão).
2. Antes de codar: pré-flight build/teste verde + claim atômico.

## Travas Vivas
- **Claim ativo**: Nenhum (UC-01.03 liberado após consolidação em 2026-11-21).
- **Greenfield Lock**: **DESTRAVADO** para código de negócio pela conclusão da EPIC-00.