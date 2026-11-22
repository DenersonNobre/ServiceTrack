# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-21)
- **Branch**: `main` (local à frente de `origin/main`, sem push — aguardar autorização do PO).
- **EPIC-00/01/02**: **CONCLUÍDAS** (`qa-review-v0.1.0..v0.11.0`).
- **EPIC-03**: UC-03.01..03,05 concluídas; UC-03.04 **PARCIAL** (cancelamento entregue; pausa pendente SPEC). Laudos `qa-review-v0.12.0..v0.16.0`.
- **Dívidas**: `docs/DEBITOS.md` D-01..D-05; M1 flakiness `credential_recovery_test.dart` UC-01.04 fora do slice (não observado no último full run).

## Próximo Passo Acionável
1. Definir contrato de “Pausa” na SPEC/épico para fechar UC-03.04 (parcial).
2. Tratar D-05 antes de integrar EPIC-04 (prova checklist real). Seguir `docs/plan/README.md` para próximo épico.

## Travas Vivas
- **Claim ativo**: Nenhum (UC-03.05 liberado após consolidação em 2026-11-21).
- **Push**: pendente autorização explícita do PO (e evidências: árvore limpa, sem concorrência/divergência).
- **Greenfield Lock**: **DESTRAVADO**.
