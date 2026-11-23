# CI — Dependências

As dependências de kernel (`kortex`, `kortex_lib`) vêm do **pub.dev**. Não há path deps nem vendor de CI.

## Workflow

O GitHub Actions (`.github/workflows/ci.yml`) roda em `ubuntu-latest` com Flutter `3.47.6`:

1. `flutter pub get`
2. `flutter analyze --fatal-infos`
3. `flutter test`

## Histórico

- `dnolib` (path dep, aposentada) era vendorizada em `ci/vendor/dnolib.tar.gz` e extraída no CI. Removida na Fase B da migração (kortex_lib 0.1.0 no pub.dev).