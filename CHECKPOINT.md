# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-21)
- **Branch**: `main` (local à frente de `origin/main`, sem push — aguardar autorização do PO).
- **EPIC-00/01/02/03**: **CONCLUÍDAS** (`qa-review-v0.1.0..v0.17.0`). UC-03.04 fechada com pausa/retomada (sem GPS na retomada, decisão PO).
- **Dívidas**: `docs/DEBITOS.md` D-01..D-05; A1 flakiness `credential_recovery_test.dart`/`auth_session_settings_test.dart` fora do slice.

## Próximo Passo Acionável
1. Tratar **D-05** antes de integrar EPIC-04 (prova checklist real, substituir 0/0).
2. Iniciar **EPIC-04 — Checklists, Câmera & Evidências GPS** conforme `docs/plan/README.md`.

## Travas Vivas
- **Claim ativo**: UC-04.03 por outro agente (`agy01@59993bf1`) — não conflitar.
- **Push**: pendente autorização explícita do PO (e evidências: árvore limpa, sem concorrência/divergência).
- **Greenfield Lock**: **DESTRAVADO**.
