#!/usr/bin/env bash
# Quality Gate local de cobertura para UTrueque.
#
# Lee el reporte LCOV de `flutter test --coverage` y calcula la cobertura de
# líneas de las capas que contienen la lógica y el acceso al API REST:
#   - lib/features/*/domain/   (casos de uso, entidades)
#   - lib/features/*/data/     (repositorios, datasources de Supabase)
#   - lib/core/utils/ y lib/core/errors/
# Si la cobertura es menor al umbral, el pipeline falla (Fail-Fast).
#
# Uso: bash quality_gate_cobertura.sh [ruta_lcov] [umbral]
set -euo pipefail

LCOV="${1:-coverage/lcov.info}"
UMBRAL="${2:-80}"
PATRON='^SF:lib/(features/[^/]+/(domain|data)/|core/(utils|errors)/)'

if [ ! -f "$LCOV" ]; then
  echo "No se encontró el reporte de cobertura: $LCOV"
  exit 1
fi

awk -v patron="$PATRON" -v umbral="$UMBRAL" '
  /^SF:/ { incluir = ($0 ~ patron); archivo = substr($0, 4); lf = 0 }
  incluir && /^LF:/ { lf = substr($0, 4) + 0; total += lf }
  incluir && /^LH:/ {
    lh = substr($0, 4) + 0; cubiertas += lh
    pct = (lf > 0) ? (lh * 100 / lf) : 100
    printf "  %-65s %4d/%-4d %6.1f%%\n", archivo, lh, lf, pct
  }
  END {
    if (total == 0) { print "No hay líneas medibles en el alcance del Quality Gate."; exit 1 }
    cobertura = cubiertas * 100 / total
    printf "\nCobertura (dominio + datos): %.1f%% (%d/%d líneas). Umbral: %d%%\n", cobertura, cubiertas, total, umbral
    if (cobertura < umbral) { print "QUALITY GATE: FAILED"; exit 1 }
    print "QUALITY GATE: PASSED"
  }
' "$LCOV"
