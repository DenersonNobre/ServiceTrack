# CI — Dependências locais (`dnolib` e `kortex`)

O `pubspec.yaml` usa path deps de desenvolvimento:

```yaml
kortex:
  path: ../kortex
dnolib:
  path: ../.dnolib
```

No GitHub Actions esses diretórios não existem. O workflow `CI` extrai um **vendor de CI** antes do `flutter pub get`:

```yaml
mkdir -p ../.dnolib ../kortex
tar -xzf ci/vendor/dnolib.tar.gz -C ../.dnolib
tar -xzf ci/vendor/kortex.tar.gz -C ../kortex
```

## Atualizar o vendor

Quando `../.dnolib` ou `../kortex` mudarem, regenere os tarballs a partir dos repos irmãos:

```powershell
pwsh scripts/ci/vendor-deps.ps1
```

O script usa `git archive HEAD`, portanto inclui apenas arquivos versionados. Commite os dois tarballs junto com a mudança de dependência.

## Limitações

- O vendor é um **snapshot de CI**, não uma cópia de desenvolvimento. O app continua usando `../kortex` e `../.dnolib` localmente.
- `dnolib` não está publicado no pub.dev nem no GitHub; por isso o snapshot é necessário.
- O Gitea não possui workflow de CI configurado; o sinal de CI atual vem do GitHub Actions.
- Não coloque tokens/credenciais nos tarballs. Eles contêm apenas código versionado das dependências.
