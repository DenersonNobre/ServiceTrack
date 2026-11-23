# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, kortex_lib (pub.dev), SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-23)
- **Branch**: `main`; árvore limpa antes desta retomada de B5; local `ahead 4` de `origin/main` (`88ee8a0` no momento da medição). Claims: verificar com `claims status`.
- **EPIC-00/01/02/03/06/07**: **CONCLUÍDOS** (ver `docs/plan/README.md` e `docs/plan/reviews/`).
- **EPIC-04**: Implementado em código/testes (UC-04.01–04.09). E2E de device executa mas trava na navegação home→clientes (`home-customers` não abre `CustomerListPage`, 3 execuções); hipótese de fiação nula refutada. D-01/C-01 continuam fail-closed por design.
- **Migração dnolib → kortex_lib (Fase B)**: B1 Result/ValidationError (`cc253ef`), B2 Money (`2081d22`), B3 brlib (`574e0d8`), B4 sqlite (`88ee8a0`) concluídos com gates verdes (+221). **B5 (cleanup)** em andamento: remover dnolib do pubspec/CI/vendor e atualizar docs factuais.
- **CI GitHub**: verde no último push verificado (`45174220335` para `8deaada`). Gitea sem workflow.
- **Dívidas**: `docs/DEBITOS.md` D-01..D-05; D-05 mitigado.

## Próximo Passo Acionável
1. Finalizar B5: remover `dnolib` do pubspec/lock/CI/vendor, atualizar docs factuais, rodar `analyze` + `test`, commitar.
2. Push dos commits locais somente com autorização explícita do PO + 3 evidências.
3. Retomar E2E EPIC-04 (tap `home-customers` / rota) com evidência de device.

## Travas Vivas
- **Push**: proibido sem autorização explícita do PO + 3 evidências (pedido, árvore limpa, sem concorrência/divergência).
- **D-01/C-01**: documento do recebedor bloqueado por design (fail-closed).
- **Greenfield Lock**: **DESTRAVADO**.