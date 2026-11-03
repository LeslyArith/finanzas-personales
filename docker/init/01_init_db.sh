#!/bin/bash
set -euo pipefail

SQL_FILES=(
  /workspace/database/00_catalogos.sql
  /workspace/database/01_esquema.sql
  /workspace/database/02_nucleo.sql
  /workspace/database/03_pruebas.sql
  /workspace/database/04_migrar_v1_a_catalogos.sql
  /workspace/database/05_pruebas_catalogos.sql
)

echo "Inicializando base de datos: ${MYSQL_DATABASE}"

for sql_file in "${SQL_FILES[@]}"; do
  if [[ -f "$sql_file" ]]; then
    echo "--> Ejecutando $(basename "$sql_file")"
    if ! mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" < "$sql_file"; then
      echo "[WARN] $(basename "$sql_file") terminó con errores; se continúa con el siguiente script." >&2
    fi
  else
    echo "[WARN] No se encontró $sql_file" >&2
  fi
done

echo "Inicialización finalizada."
