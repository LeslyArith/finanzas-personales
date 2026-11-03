#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[1/6] Validando compose"
docker compose -f compose.yaml config >/dev/null

echo "[2/6] Empaquetado y verificación de artefacto"
./deploy/deploy.sh >/dev/null

echo "[3/6] Verificando salud PHP en contenedor app"
docker compose -f compose.yaml exec -T app php /var/www/html/deploy/check-php.php >/dev/null

echo "[4/6] Verificando health web"
docker compose -f compose.yaml exec -T app php /var/www/html/deploy/web-check.php http://127.0.0.1 >/dev/null

echo "[5/6] Smoke local de espacios en db_dev"
docker compose -f compose.yaml exec -T app php /var/www/html/scripts/smoke_local.php >/dev/null

echo "[6/6] Estado final"
echo "RELEASE_CHECK_OK=1"
