# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, dnolib, SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-20)
- **Branch**: `main` (inicializada, limpa).
- **EPIC-00 (Fundação Técnica)**: **CONCLUÍDA** e 100% verde.
  - Dependências resolvidas no `pubspec.yaml` (`kortex`, `dnolib`, `local_auth`, `flutter_secure_storage`, `pdf`, `share_plus`, etc.).
  - `flutter analyze`: No issues found!
  - `flutter test`: 100% dos testes passando (Smoke test validado).
  - Shim `tools/bin/claims.cmd` operacional.
  - CI configurado em `.github/workflows/ci.yml`.

## Próximo Passo Acionável
1. Iniciar execução da **`EPIC-01: Onboarding, Autenticação Local & Perfil do Técnico`**.
2. Alvo: `UC-01.01` (Value Objects de credenciais e tela de onboarding inicial com `kortex`).

## Travas Vivas
- **Claim ativo**: Nenhum.
- **Greenfield Lock**: **DESTRAVADO** para código de negócio pela conclusão da EPIC-00.
