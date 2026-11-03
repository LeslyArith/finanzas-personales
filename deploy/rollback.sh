#!/usr/bin/env bash
set -euo pipefail

echo "ROLLBACK_PLAN=manual"
echo "1) Restaurar paquete estable anterior en servidor"
echo "2) Restaurar backup de base si hubo cambios"
echo "3) Verificar /health y login"
