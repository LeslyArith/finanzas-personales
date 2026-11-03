#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

SERVICE="db_test"

wait_for_db() {
  local retries=40
  until docker compose -f compose.yaml --profile tests exec -T "$SERVICE" sh -lc "mysqladmin ping -h localhost --silent" >/dev/null 2>&1; do
    retries=$((retries - 1))
    if [[ $retries -le 0 ]]; then
      echo "No fue posible conectar a $SERVICE" >&2
      exit 1
    fi
    sleep 2
  done
}

apply_sql() {
  local file="$1"
  echo "[SQL] $file"
  docker compose -f compose.yaml --profile tests exec -T "$SERVICE" sh -lc \
    "mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" \"\$MYSQL_DATABASE\" < /workspace/database/$file"
}

docker compose -f compose.yaml --profile tests rm -fsv "$SERVICE" >/dev/null 2>&1 || true

docker compose -f compose.yaml --profile tests up -d "$SERVICE"
wait_for_db

apply_sql "00_catalogos.sql"
apply_sql "01_esquema.sql"
apply_sql "02_nucleo.sql"
apply_sql "03_pruebas.sql"
apply_sql "05_pruebas_catalogos.sql"

echo "Pruebas del núcleo financiero completadas."
