# Núcleo SQL de finanzas — Fase 1, versión 2 sin enumeraciones

Entrega de desarrollo. No es todavía una aplicación web ni un sistema listo para producción.

## Contenido

- `00_catalogos.sql`: nueve catálogos con códigos, nombres, estado y orden.
- `01_esquema.sql`: usuarios, tokens, sesiones, segundo factor, espacios, integrantes, contactos, cuentas contables, cuentas financieras, cuentas por cobrar, operaciones, partidas y auditoría.
- `02_nucleo.sql`: validaciones, inmutabilidad, registro transaccional y reversión.
- `03_pruebas.sql`: pruebas de integración con datos ficticios, exclusivamente en una base desechable vacía.
- `04_migrar_v1_a_catalogos.sql`: conversión de la versión anterior, solo si ya se instaló; ver CATALOGOS.md.
- `05_pruebas_catalogos.sql`: pruebas de extensibilidad y permisos.
- `CATALOGOS.md`: cambios, políticas y rutas de instalación/migración.
- `CONTRATOS.md`: reglas de integración PHP, diccionario y límites.

## Requisitos e instalación de prueba

Objetivo: MySQL 8.0.21 o posterior de la familia 8, InnoDB, utf8mb4 y modo estricto. No asumir compatibilidad con MariaDB por tener sintaxis parecida. Confirmar producto, versión y permisos del alojamiento con `SELECT VERSION();` antes de adaptar o instalar. Si la versión anterior ya está instalada, seguir exclusivamente la ruta de migración descrita en CATALOGOS.md. Las zonas IANA (por ejemplo America/Ciudad_Juarez) requieren tablas de zonas horarias instaladas en MySQL. Verificar `SELECT CONVERT_TZ(UTC_TIMESTAMP(),'+00:00','America/Ciudad_Juarez');`: si devuelve NULL, resolverlo con el alojamiento antes de operar. No sustituir una zona por un desfase fijo para evadir cambios de horario. Las restricciones CHECK requieren una versión que las aplique; MySQL las incorporó en 8.0.16.

Con una base NUEVA seleccionada y un usuario de migraciones que pueda crear tablas, vistas, triggers y rutinas:

```bash
mysql -h HOST -u USUARIO -p BASE_NUEVA < 00_catalogos.sql
mysql -h HOST -u USUARIO -p BASE_NUEVA < 01_esquema.sql
mysql -h HOST -u USUARIO -p BASE_NUEVA < 02_nucleo.sql
```

Para pruebas, usar otra base nueva destinada exclusivamente a pruebas, importar 00, 01 y 02, y ejecutar:

```bash
mysql -h HOST -u USUARIO -p BASE_PRUEBAS < 03_pruebas.sql
mysql -h HOST -u USUARIO -p BASE_PRUEBAS < 05_pruebas_catalogos.sql
```

No incluir la contraseña en la línea de comandos. El cliente debe soportar DELIMITER. No usar `--force`: debe detenerse ante el primer error. Las migraciones DDL no son atómicas en conjunto: ante un fallo, revisar la base parcial y reiniciar solo en otra base vacía. No reimportar encima de datos existentes.

El SQL no crea un administrador ni una contraseña predeterminada. Los usuarios ficticios de las pruebas llevan hashes deliberadamente inválidos y jamás deben habilitar acceso web.

## Ejemplo: boletos para papá

Compra total $8,000 con tu tarjeta: debe a la subcuenta por cobrar de Papá y haber a la tarjeta. Gasto propio $0, por cobrar $8,000, deuda al banco $8,000.

Abono de Papá de $3,000: debe al banco y haber a la subcuenta por cobrar. No es ingreso ganado. Pendiente de Papá $5,000.

Pagar al banco $8,000 disminuye banco y tarjeta; no cambia lo que debe Papá. Si te paga directamente a tu tarjeta, el procedimiento de cobro permite usar esa cuenta como destino (reducción de pasivo); debe documentarse y conciliarse el abono real.

Si Papá asumirá intereses o comisiones, se requiere acordarlo y registrarlo explícitamente en una fase posterior: este núcleo no los agrega automáticamente. Si una parte es tuya y otra suya, el formulario compuesto y la distribución por conceptos quedan para la fase compartida.

## Estado de validación

Revisión estática y comprobación del contenido del paquete. No se ejecutó contra MySQL: el entorno de elaboración no dispone del servidor ni del cliente. Por tanto, ni la sintaxis dependiente del motor, ni los triggers, ni los bloqueos concurrentes se declaran verificados. Ejecutar las pruebas y revisar resultados en MySQL antes de continuar con datos reales.

Pendiente de prueba adicional: concurrencia, revocación simultánea, permisos del usuario SQL restringido, backups y restauración. La presencia de tablas de autenticación no implementa login, segundo factor, recuperación, rate limiting ni sesiones HTTP.

## Fuentes de referencia

- https://dev.mysql.com/doc/refman/8.0/en/constraints.html
- https://dev.mysql.com/blog-archive/mysql-8-0-16-introducing-check-constraint/
- https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-isolation-levels.html

## Próxima implementación

Bootstrap PHP y conexión PDO, creación inicial del propietario por consola, invitaciones, login y autorización centralizada. Después, alta de cuentas y formularios que consuman estas operaciones. No subir estos archivos SQL ni las pruebas a una carpeta pública del sitio.
