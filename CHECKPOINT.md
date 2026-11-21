# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-21)
- **Branch**: `main` (acompanhando `origin/main` após saneamento local pendente de push).
- **EPIC-00 (Fundação Técnica)**: **CONCLUÍDA** e 100% verde (hooks `pre-commit` instalados).
- **EPIC-01 (Auth & Perfil)**: **CONCLUÍDA** (`UC-01.01..UC-01.05`, 76/76 testes, `qa-review-v0.1.0..v0.7.0`).
  - Desvio PBKDF2 senha+PIN autorizado pelo PO (Gate 2.5 C1, UC-01.01).
- **Dívidas**: `docs/DEBITOS.md` D-01..D-04; observações QA baixas/info em laudos.

## Próximo Passo Acionável
1. Detalhar `UC-02.01..04` (Gherkin + fixtures) em `docs/plan/epics/epic-02-clientes.md`.
2. Iniciar **UC-02.01** (Cadastro e Edição de Cliente com `dnolib/brlib`) com claim e TDD.

## Travas Vivas
- **Claim ativo**: Nenhum.
- **Greenfield Lock**: **DESTRAVADO**.
