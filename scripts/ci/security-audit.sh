#!/usr/bin/env bash
# Rotina reproduzível de auditoria de dependências/CVE (D-02 / UC-08.04).
# - flutter pub outdated --json: evidencia advisories/atualizações (quando suportado)
# - osv-scanner (opcional local, obrigatório no CI job): CVEs contra pubspec.lock
#
# Uso:
#   bash scripts/ci/security-audit.sh
#   OSV_SCANNER_BIN=osv-scanner bash scripts/ci/security-audit.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "==> [D-02] flutter pub outdated --json"
OUTDATED_JSON="$(mktemp)"
trap 'rm -f "$OUTDATED_JSON"' EXIT
flutter pub outdated --json >"$OUTDATED_JSON" || true

# Falha se o JSON indicar advisory atual (campo isCurrentAffectedByAdvisory).
if grep -q '"isCurrentAffectedByAdvisory"[[:space:]]*:[[:space:]]*true' "$OUTDATED_JSON"; then
  echo "[FAIL] flutter pub outdated reportou pacote atual afetado por advisory."
  grep -n '"isCurrentAffectedByAdvisory"[[:space:]]*:[[:space:]]*true' "$OUTDATED_JSON" || true
  exit 1
fi
echo "[OK] Nenhum advisory atual sinalizado por flutter pub outdated."

OSV_BIN="${OSV_SCANNER_BIN:-osv-scanner}"
if command -v "$OSV_BIN" >/dev/null 2>&1; then
  echo "==> [D-02] $OSV_BIN scan source -L pubspec.lock"
  "$OSV_BIN" scan source -L pubspec.lock
  echo "[OK] osv-scanner sem vulnerabilidades conhecidas."
else
  echo "[WARN] osv-scanner não encontrado; pulando scan CVE local."
  echo "       Instale osv-scanner ou execute o job security-audit no CI."
  if [[ "${REQUIRE_OSV_SCANNER:-0}" == "1" ]]; then
    echo "[FAIL] REQUIRE_OSV_SCANNER=1 e osv-scanner ausente."
    exit 1
  fi
fi
