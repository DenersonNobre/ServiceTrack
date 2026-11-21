# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-21)
- **Branch**: `main` (local à frente de `origin/main`, sem push — aguardar autorização do PO).
- **EPIC-00/01/02**: **CONCLUÍDAS** (`qa-review-v0.1.0..v0.11.0`).
- **EPIC-03 (em andamento)**: UC-03.01..UC-03.03 concluídas (`qa-review-v0.12.0..v0.14.0`). Próxima: UC-03.04.
- **Dívidas**: `docs/DEBITOS.md` D-01..D-04; observações QA (M1 flakiness auth fora do slice).

## Próximo Passo Acionável
1. Iniciar **UC-03.04** (Pausa e Cancelamento com Justificativa) com pré-flight, claim, TDD e Gate 2.5 conforme superfície.
2. Antes de codar: build/teste verde + claim atômico.

## Travas Vivas
- **Claim ativo**: Nenhum (UC-03.03 liberado após consolidação em 2026-11-21).
- **Push**: pendente autorização explícita do PO (e evidências: árvore limpa, sem concorrência/divergência).
- **Greenfield Lock**: **DESTRAVADO**.
