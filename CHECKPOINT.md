# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-21)
- **Branch**: `main` (commits locais à frente de `origin/main`, sem push — sem autorização do PO).
- **EPIC-00 (Fundação Técnica)**: **CONCLUÍDA** e 100% verde.
- **UC-01.01 (EPIC-01, Concluída)**: TASK-01/02/03 consolidadas com Gates 2.5/3/4 — suíte 33/33, `flutter analyze --fatal-infos` limpo, laudos `qa-review-v0.1.0..v0.3.0`.
  - Desvio do épico autorizado pelo PO: PBKDF2-HMAC-SHA-256 para senha E PIN (Gate 2.5 C1).
  - Estrutura canônica Flutter/Dart alinhada ao POC `kortex/poc/lib` (`app/`, `core/`, `modules/<nome>/{domain,data,commands,features,ui}`).
- **Dívidas**: `docs/DEBITOS.md` D-01..D-04 (runners nativos, CVE-audit, rate-limit da senha, ledger MIT). QA v0.3.0: B1-B3 baixas.

## Próximo Passo Acionável
1. Iniciar **UC-01.02** (Biometria / "Lembrar de Mim") com novo claim, TDD e Gate 2.5 por superfície `local_auth`.
2. Antes de codar: pré-flight build/teste verde + claim atômico.

## Travas Vivas
- **Claim ativo**: Nenhum (UC-01.01 liberado após consolidação Gates 3/4 em 2026-11-21).
- **Greenfield Lock**: **DESTRAVADO** para código de negócio pela conclusão da EPIC-00.
