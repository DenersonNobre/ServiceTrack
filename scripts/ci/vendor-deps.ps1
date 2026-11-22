# Gera os tarballs de dependências locais usados pelo CI.
#
# Uso: pwsh scripts/ci/vendor-deps.ps1
# Requer os repositórios irmãos ../.dnolib e ../kortex no disco.

$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$vendor = Join-Path $repo 'ci\vendor'
New-Item -ItemType Directory -Force -Path $vendor | Out-Null

$deps = @(
    @{ Name = 'dnolib'; Path = (Join-Path $repo '..\.dnolib') },
    @{ Name = 'kortex'; Path = (Join-Path $repo '..\kortex') }
)

foreach ($dep in $deps) {
    $depPath = (Resolve-Path $dep.Path).Path
    $output = Join-Path $vendor ("{0}.tar.gz" -f $dep.Name)
    git -C $depPath archive --format=tar.gz -o $output HEAD
    Get-Item $output | Select-Object FullName, Length
}
