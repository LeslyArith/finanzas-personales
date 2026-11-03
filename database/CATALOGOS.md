# Versión 2: catálogos en lugar de enumeraciones

Se sustituyeron las 11 columnas originalmente enumeradas por códigos VARCHAR(30) con claves foráneas hacia nueve catálogos. Los códigos usan ascii_bin de forma consistente para que la integridad referencial no dependa de la intercalación por defecto del alojamiento.

| Catálogo | Uso |
|---|---|
| cat_estados_usuario | Estado de usuario y permiso de acceso. |
| cat_tipos_token | Invitación y recuperación. |
| cat_tipos_espacio | Personal y grupo. |
| cat_roles_espacio | Rol, permiso para registrar y permiso para reversar. |
| cat_tipos_contables | Clasificación contable esencial. |
| cat_tipos_cuenta | Tipo de cuenta y naturaleza contable asociada. |
| cat_tipos_operacion | Tipos identificados por el núcleo financiero. |
| cat_estados_operacion | Estados del flujo de confirmación. |
| cat_acciones_auditoria | Acciones auditadas. |

Cada registro tiene codigo estable, nombre visible editable, activo, es_sistema y orden. No hay catálogo universal que mezcle dominios. El código es la clave natural; no se necesita alterar tablas para agregar filas. Nombres, códigos, roles y relaciones se almacenan por separado de los textos del formulario.

## Extensibilidad real

Agregar BILLETERA como tipo de cuenta con naturaleza ACTIVO permite usarlo en gastos, ingresos y transferencias sin cambiar el esquema ni las rutinas. La compatibilidad tipo/naturaleza se valida con una clave foránea compuesta, en lugar de una lista cerrada en un CHECK.

Agregar un rol CAPTURISTA con puede_registrar=1 y puede_reversar=0 habilita el registro y niega reversos sin que la rutina reconozca su nombre. Agregar un estado de usuario exige definir expresamente permite_acceso: el valor por defecto es falso.

Los tipos contables, los tipos de espacio, los tokens, los estados de confirmación y las operaciones tienen significado técnico. Agregar una fila no inventa un algoritmo financiero ni un flujo de seguridad. Por ejemplo, un tipo INVERSION necesita reglas y pruebas antes de operar; el procedimiento rechaza tipos de operación que no implementa. No reemplazamos integridad financiera por texto libre.

## Bajas y edición

Para nuevos selectores se filtra activo=1; los reportes históricos no ocultan registros inactivos. No borrar valores referenciados ni cambiar códigos del sistema. es_sistema es metadata: aún no existe pantalla ni servicio que proteja su edición; la futura administración debe restringir cambios de significado y de permisos. La cuenta SQL de la aplicación no debe tener escritura general en estos catálogos.

Desactivar un tipo de cuenta impide nuevos movimientos normales con ese tipo; los reversos conservan la posibilidad de corregir el historial. Desactivar un rol revoca su capacidad para operar en grupos. El identificador de un espacio personal sigue siendo su propietario, independientemente de membresías de grupos.

## Instalación nueva

Orden: 00_catalogos.sql → 01_esquema.sql → 02_nucleo.sql. Solo en una base nueva.

Pruebas: importar esos tres archivos en otra base nueva de pruebas y ejecutar 03_pruebas.sql → 05_pruebas_catalogos.sql. Los archivos de pruebas crean datos ficticios y no son reentrantes.

## Si ya se instaló el paquete anterior

Ensayar primero en una copia de la base con respaldo restaurable. Mantener la aplicación detenida durante todo el cambio. No volver a ejecutar 01_esquema.sql ni importar pruebas.

Orden: 00_catalogos.sql → 04_migrar_v1_a_catalogos.sql → 02_nucleo.sql de esta versión.

04 conserva los datos y convierte las columnas. Al final retira las rutinas y triggers anteriores para que 02 instale las nuevas versiones: no reactivar la aplicación entre ambos archivos. No desactiva foreign_key_checks. Como el DDL no es atómico en conjunto, ante fallo no continuar ni reejecutar a ciegas: revisar el estado y restaurar la copia si corresponde.

La migración se dirige exclusivamente al esquema v1 original: verificar SHOW CREATE TABLE cuentas y cuentas_por_cobrar para confirmar los nombres cuentas_ibfk_1 y cuentas_por_cobrar_ibfk_2 antes de ejecutar. Si hay modificaciones manuales, ajustar y revisar la migración en la copia de ensayo.

## Validación disponible

Se incluyen pruebas nuevas para alta de tipo de cuenta, rechazo de tipo inexistente, ausencia de columnas enumeradas y rol personalizado. No se ejecutaron contra MySQL en este entorno. La revisión estática y la integridad del ZIP no sustituyen esa ejecución.

Referencia oficial: https://dev.mysql.com/doc/refman/8.0/en/create-table-foreign-keys.html
