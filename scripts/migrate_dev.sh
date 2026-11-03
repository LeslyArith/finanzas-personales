#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

SERVICE="db_dev"

wait_for_db() {
  local retries=40
  until docker compose -f compose.yaml exec -T "$SERVICE" sh -lc "mysqladmin ping -h localhost --silent" >/dev/null 2>&1; do
    retries=$((retries - 1))
    if [[ $retries -le 0 ]]; then
      echo "No fue posible conectar a $SERVICE" >&2
      exit 1
    fi
    sleep 2
  done
}

run_sql_file() {
  local file="$1"
  docker compose -f compose.yaml exec -T "$SERVICE" sh -lc \
    "mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" \"\$MYSQL_DATABASE\" < /workspace/database/$file" </dev/null
}

docker compose -f compose.yaml up -d "$SERVICE"
wait_for_db

docker compose -f compose.yaml exec -T "$SERVICE" sh -lc "
mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" \"\$MYSQL_DATABASE\" -e \"
CREATE TABLE IF NOT EXISTS schema_migrations (
  version VARCHAR(10) PRIMARY KEY,
  filename VARCHAR(120) NOT NULL,
  description VARCHAR(255) NOT NULL,
  applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;\"
" </dev/null

while IFS='|' read -r version filename description; do
  [[ -z "$version" ]] && continue

  if [[ "$version" == "004" || "$version" == "005" || "$version" == "006" ]]; then
    continue
  fi

  applied="$(docker compose -f compose.yaml exec -T "$SERVICE" sh -lc "mysql -N -s -uroot -p\"\$MYSQL_ROOT_PASSWORD\" \"\$MYSQL_DATABASE\" -e \"SELECT COUNT(*) FROM schema_migrations WHERE version='$version';\"" </dev/null)"

  if [[ "$applied" == "1" ]]; then
    echo "[SKIP] $version $filename"
    continue
  fi

  echo "[APPLY] $version $filename"
  run_sql_file "$filename"

  docker compose -f compose.yaml exec -T "$SERVICE" sh -lc \
    "mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" \"\$MYSQL_DATABASE\" -e \"INSERT INTO schema_migrations(version, filename, description) VALUES ('$version', '$filename', '${description//\'/\'\'}');\"" </dev/null
done < database/migrations/manifest.txt

echo "Migraciones de desarrollo aplicadas correctamente."
