# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-21)
- **Branch**: `main` (3 commits locais à frente de `origin/main`, sem push — sem autorização do PO).
- **EPIC-00 (Fundação Técnica)**: **CONCLUÍDA** e 100% verde.
- **UC-01.01 (EPIC-01)**: TASK-01 (Value Objects, 15 testes) e TASK-02 (cofre PBKDF2 + rate-limit, 14 testes) **consolidadas** com Gates 2.5/3/4 — suíte 30/30, `analyze` limpo, laudos `qa-review-v0.1.0` e `qa-review-v0.2.0`.
  - Desvio do épico autorizado pelo PO: PBKDF2-HMAC-SHA-256 para senha E PIN (Gate 2.5 C1).
- **Dívidas**: `docs/DEBITOS.md` D-01..D-04 (runners nativos, CVE-audit, rate-limit da senha, ledger MIT).

## Próximo Passo Acionável
1. Retomar **`UC-01.01` TASK-03**: tela de Onboarding (tokens Deep Petrol Green, teclado ≥48dp) com `kortex`.
2. Alvo: widget tests TDD contra VOs + store já auditados (sem superfície nova p/ Gate 2.5).

## Travas Vivas
- **Claim ativo**: Nenhum (claim `UC-01.01` liberado no encerramento da sessão em 2026-11-21).
- **Greenfield Lock**: **DESTRAVADO** para código de negócio pela conclusão da EPIC-00.
