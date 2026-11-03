# AGENTS.md

## Alcance
Este repositorio corresponde solo a finanzas-personales.
No tocar archivos, contenedores, volúmenes ni redes de TGEngrave.

## Entorno local esperado
- macOS con Docker Desktop.
- Proyecto montado desde esta carpeta del host al contenedor.
- `compose.yaml` de este directorio es la única orquestación válida para este proyecto.

## Contenedores
- `app`: PHP/Apache para MVC.
- `db_dev`: MySQL persistente para desarrollo.
- `db_test`: MySQL desechable para pruebas SQL del núcleo (perfil `tests`).

## Reglas de base de datos
- Desarrollo: usar `scripts/migrate_dev.sh` (00, 01, 02) con control en `schema_migrations`.
- Pruebas: usar `scripts/run_core_tests.sh` (00, 01, 02, 03 y 05) sobre `db_test`.
- `04_migrar_v1_a_catalogos.sql` es solo para bases v1 ya instaladas; no se ejecuta en instalación nueva.

## Estructura MVC mínima
- Entrada HTTP: `public/index.php`.
- Núcleo: `app/Core`.
- Controladores: `app/Controllers`.
- Modelos: `app/Models`.
- Vistas: `app/Views`.
- Rutas: `config/routes.php`.

## Prohibiciones
- No ejecutar despliegues remotos.
- No aplicar cambios en Hostinger.
- No mezclar datos reales con base de pruebas desechable.
