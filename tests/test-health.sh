#!/bin/bash
# tests/test-health.sh — Verifica que el script funciona correctamente
 
set -euo pipefail
 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/../server-health.sh"
 
PASS=0
FAIL=0
 
assert() {
  local DESC=$1
  local CMD=$2
  if eval "$CMD" > /dev/null 2>&1; then
    echo "  ✓ $DESC"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $DESC"
    FAIL=$((FAIL + 1))
  fi
}
 
echo "Ejecutando tests..."
 
assert "Script existe" "[ -f $MAIN_SCRIPT ]"
assert "Script es ejecutable" "[ -x $MAIN_SCRIPT ]"
assert "Script tiene shebang correcto" "head -1 $MAIN_SCRIPT | grep -q bash"
assert "Script muestra ayuda sin error" "$MAIN_SCRIPT --help"
assert "Script corre sin errores" "$MAIN_SCRIPT --output /tmp/test-report"
assert "Reporte fue generado" "ls /tmp/test-report/health-*.txt 2>/dev/null | head -1"
 
echo ""
echo "Resultados: $PASS pasados, $FAIL fallidos"
 
[ $FAIL -eq 0 ] && exit 0 || exit 1
