# Deploy baseline - finanzas-personales

Este directorio prepara un flujo similar al de TGEngrave sin ejecutar despliegues remotos automáticos.

## Flujo recomendado

1. Empaquetar:
   - `./deploy/package.sh`
2. Verificar paquete:
   - `python3 ./deploy/verify.py deploy/runtime/finanzas-personales-YYYYMMDD-HHMMSS.tar.gz`
3. Precheck general:
   - `./deploy/deploy.sh`
4. Verificación web:
   - `php ./deploy/web-check.php http://127.0.0.1:8082`

## Checklist automático (pre-merge / pre-tag)

Ejecuta en local:

- `./deploy/release-check.sh`

Si termina con `RELEASE_CHECK_OK=1`, el baseline técnico quedó listo para:

1. Merge de rama feature a `main`.
2. Etiquetado de release (`v0.x.x`).

El script valida:

- `docker compose config`
- empaquetado + verificación de artefacto
- verificación PHP en contenedor `app`
- `health` web
- smoke local sobre `db_dev`

## Flujo Git recomendado

1. `git checkout -b feat/<cambio>`
2. `git add . && git commit -m "<mensaje>"`
3. `./deploy/release-check.sh`
4. `git push origin feat/<cambio>`
5. PR a `main`
6. Al aprobar: merge + `git tag v0.x.x` + push del tag

## Notas

- `front-controller.php` y `entry.example.php` son plantilla para separación de rutas privadas en hosting.
- No se sube `.env` ni `deploy/runtime`.
- `rollback.sh` contiene pasos mínimos de reversión operativa.
