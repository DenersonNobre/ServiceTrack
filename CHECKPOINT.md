# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-22)
- **Branch**: `main`; topo = fatia `UC-04.09` (ver `git log -1`); claims `UC-04.09` e `OPS-EPIC04-E2E-DEVICE` ativos.
- **EPIC-00/01/02/03**: **CONCLUÍDOS** (`qa-review-v0.1.0..v0.17.0`).
- **EPIC-04**: **Implementado em código/testes** (UC-04.01–04.09; D-05 mitigado; modelo de checklist com seed + cadastro alcançável). **E2E device bloqueado pelo ambiente** — MIUI recusa `adb install` (`INSTALL_FAILED_USER_RESTRICTED`).
- **EPIC-06**: **Concluído** — UC-06.01..06.05 (catálogos `*FailureCodes` + gate com prova negativa; tokens 48dp; `SignaturePadWidget` em Kortex/`setState` zero; `AppDependencies` + `*Routes`; `qa-review-v0.20.0.md`).
- **EPIC-07**: **Concluído** — UC-07.01/02/03 (settings + UI + integração fail-closed D-01/C-01). G2.5/G3/G4 aprovados com ressalvas (`qa-review-v0.21.0.md`).
- **Toolchain**: `kortex` vem do **pub.dev (`^0.2.1`)**; `dnolib` segue por path (`ci/vendor/dnolib.tar.gz`).
- **CI GitHub**: **verde** no run `45089417985` (`origin/main` `a9c07ce`). Gitea sem workflow.
- **Dívidas**: `docs/DEBITOS.md` D-01..D-05; D-05 mitigado.

## Próximo Passo Acionável
1. **Desbloquear `adb install`**: habilitar "Instalar via USB" na MIUI (conta Mi) e então rodar `flutter test integration_test/epic04_probe.dart -d 192.168.67.65:5555` — medir rota de boot e fix de GPS antes de escrever o E2E.
2. **E2E `template→OS→checklist→conclusão`** só depois do probe confirmar GPS (conclusão de OS exige fix, sem bypass).
3. **Push**: pendente de autorização explícita do PO + 3 evidências.

## Travas Vivas
- **Claims**: `UC-04.09` e `OPS-EPIC04-E2E-DEVICE` (`opc01@e03ff640`); `claims status` antes de mutar.
- **Push**: somente com autorização explícita do PO + 3 evidências.
- **D-01/C-01**: persiste bloqueando documento do recebedor por design (fail-closed).
- **Greenfield Lock**: **DESTRAVADO**.
