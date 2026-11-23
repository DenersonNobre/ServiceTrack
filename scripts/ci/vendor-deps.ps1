# Gera os tarballs de dependências locais usados pelo CI.
#
# Uso: pwsh scripts/ci/vendor-deps.ps1
# Requer os repositórios irmãos das dependências de path no disco (../.dnolib).
# kortex é consumido do pub.dev (^0.2.1), então não entra no vendor.

$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$vendor = Join-Path $repo 'ci\vendor'
New-Item -ItemType Directory -Force -Path $vendor | Out-Null

$deps = @(
    @{ Name = 'dnolib'; Path = (Join-Path $repo '..\.dnolib') }
)

foreach ($dep in $deps) {
    $depPath = (Resolve-Path $dep.Path).Path
    $output = Join-Path $vendor ("{0}.tar.gz" -f $dep.Name)
    git -C $depPath archive --format=tar.gz -o $output HEAD
    Get-Item $output | Select-Object FullName, Length
}
