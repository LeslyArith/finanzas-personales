# Entrega 1 - Finanzas Personales

## 1) Revisión SQL

Resultado:
- Esquema base y núcleo (`00`, `01`, `02`) son la ruta para instalación nueva.
- `04_migrar_v1_a_catalogos.sql` es migración de compatibilidad para instalaciones previas v1, no para base nueva.
- `03_pruebas.sql` y `05_pruebas_catalogos.sql` son solo para base de pruebas.

Hallazgo relevante:
- Si `04` se ejecuta en base nueva puede fallar por intentos de `DROP CHECK` que no existen en ese contexto.
- Por ese motivo, el flujo de instalación nueva excluye `04`.

## 2) Entorno Docker independiente

Se definió `compose.yaml` propio del proyecto con:
- `app` en puerto local `8082`.
- `db_dev` en puerto local `3310` (persistente).
- `db_test` en puerto local `3311` (desechable, perfil `tests`).

No se usan contenedores, redes ni volúmenes de TGEngrave.

## 3) Estructura MVC mínima

Creada estructura base:
- `public/index.php`
- `app/Core`
- `app/Controllers`
- `app/Models`
- `app/Views`
- `config/routes.php`

Incluye rutas `/` y `/health` para comprobación inicial.

## 4) Migraciones versionadas

Se agregó:
- `database/migrations/manifest.txt`
- `scripts/migrate_dev.sh`

Reglas:
- Versiones `001-003` se aplican a desarrollo.
- Versiones `004-006` son manuales/solo pruebas según el caso.
- Registro aplicado en `schema_migrations`.

## 5) Pruebas del núcleo financiero

Script incorporado:
- `scripts/run_core_tests.sh`

Flujo:
- Levanta `db_test` desechable.
- Ejecuta `00`, `01`, `02`, `03`, `05`.
- Valida reglas del núcleo contable e idempotencia.

## 6) Guía para agentes

Se agregó `AGENTS.md` con reglas de alcance, entorno, ejecución local, y prohibición de cambios en Hostinger.
