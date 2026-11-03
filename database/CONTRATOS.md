# Contratos de integración y diccionario

## Catálogos

Los 11 campos antes enumerados se relacionan ahora con nueve catálogos mediante claves foráneas. Ver CATALOGOS.md. Los tipos de cuenta configuran su naturaleza; los roles configuran permisos. Los tipos de operación nuevos requieren implementación financiera: registrarlos en un catálogo no ejecuta reglas inexistentes.

## Seguridad y transacciones

Los procedimientos reciben el usuario desde la sesión autenticada en el servidor; jamás desde un campo editable enviado por el cliente. La credencial SQL de la aplicación no se entrega a usuarios finales. MySQL no tiene aquí aislamiento por fila para lecturas: toda consulta debe filtrar por el espacio previamente autorizado. El administrador de acceso no omite estos filtros.

Separar credencial de migraciones de credencial de aplicación. La de aplicación no debe tener INSERT/UPDATE/DELETE sobre operaciones, partidas o auditoría; conceder EXECUTE solo sobre las dos rutinas públicas y lecturas necesarias. Las rutinas son SQL SECURITY DEFINER; revisar que su definidor sea una cuenta técnica estable y con permisos mínimos. No conceder CREATE ROUTINE, TRIGGER ni privilegios globales a la aplicación. La gestión futura de usuarios/cuentas requiere servicios autorizados separados, no escrituras genéricas desde formularios.

Toda modificación financiera/configuración de cuentas/membresía usa primero el bloqueo de `espacios`, después usuario e integrante y finalmente cuentas. Esto serializa operaciones por espacio. No llamar las rutinas dentro de una transacción PHP: START TRANSACTION puede cerrar una transacción anterior en MySQL. Cada llamada constituye una unidad independiente. Ante deadlock o timeout, reintentar toda la llamada con la misma clave y datos, con límite y espera; no repetir errores de validación.

No pasar fechas futuras para confirmar; se utilizarán compromisos en otra fase. La conexión usa UTC para timestamps. PHP determina fecha efectiva según zona del espacio. Las rutinas calculan hoy en esa zona con CONVERT_TZ y rechazan la operación si MySQL no reconoce la zona; comprobar tablas de zonas del alojamiento antes del despliegue. Las pruebas usan +00:00 para no depender de esas tablas.

## Operaciones admitidas

`sp_registrar_operacion(usuario, espacio, clave, tipo, fecha, concepto, debe, haber, importe)`

| Tipo | Debe | Haber |
|---|---|---|
| APERTURA de dinero | Cuenta financiera ACTIVO | PATRIMONIO |
| APERTURA de deuda | PATRIMONIO | Tarjeta PASIVO |
| INGRESO | Cuenta financiera ACTIVO | INGRESO |
| GASTO | GASTO | Cuenta financiera ACTIVO o tarjeta PASIVO |
| TRANSFERENCIA | Cuenta financiera ACTIVO destino | Cuenta financiera ACTIVO origen |
| PAGO_TARJETA | Tarjeta PASIVO | Cuenta financiera ACTIVO |
| COMPRA_TERCERO | ACTIVO por cobrar a un contacto | Cuenta financiera ACTIVO o tarjeta PASIVO |
| COBRO_TERCERO | Cuenta financiera ACTIVO o tarjeta PASIVO | ACTIVO por cobrar a un contacto |

Importe: cadena decimal positiva sin separadores de miles, hasta 15 enteros y 4 decimales; MXN/USD exigen centavos exactos. Nunca usar float de JavaScript o PHP para construir cálculos contables. Debe y haber son identificadores de cuentas contables, no de cuentas financieras. Una operación de esta fase tiene dos partidas de una misma moneda.

Clave: entre 16 y 64 bytes, generada por el cliente/servidor para un intento lógico y conservada ante reintentos. Misma clave y mismo contenido devuelve el identificador original con repetida=1; distinto contenido falla. El SQL comprueba autor, fecha, concepto, cuentas e importe. La sesión tiene que seguir autorizada para reintentar.

`sp_reversar_operacion(usuario, espacio, original, clave, fecha, motivo)`

Genera las partidas opuestas del original, sin borrarlo ni cambiarlo. Solo un reverso por original, en el mismo espacio y moneda. Un reverso no se reversa: un reemplazo se registra como una nueva operación con referencia funcional en la futura capa PHP. En grupos, el catálogo de roles debe conceder puede_reversar y el rol debe estar activo. La fecha no precede al original.

## Diccionario resumido

| Entidad | Campos y significado |
|---|---|
| usuarios | correo_normalizado único; password_hash obtenido con APIs seguras de PHP; estado; administra_acceso no concede lectura financiera; version_sesiones permite revocación. |
| tokens_acceso | Hash binario de token aleatorio de alta/recuperación, destinatario, expiración, uso y revocación. El consumo atómico se implementará en PHP/servicio transaccional. |
| sesiones_usuario | Hash de sesión, versión de usuario y fechas; la aplicación debe verificar inactividad, vencimiento y revocación. |
| segundos_factores | Secreto cifrado autenticado, versión de clave externa y último paso TOTP aceptado para impedir reutilización. |
| codigos_recuperacion | Hash individual, consumo atómico pendiente de implementar. |
| espacios | Personal con propietario único o grupo sin propietario personal; moneda de referencia y fecha de inicio. |
| espacio_integrantes | Rol y acceso actual a grupo; historial detallado de cambios corresponde a auditoría de membresía futura. |
| contactos | Personas/comercios del espacio; no implica identidad de usuario ni aceptación de deuda. |
| cuentas_contables | Clasificación ACTIVO/PASIVO/INGRESO/GASTO/PATRIMONIO; moneda y espacio inmutables. |
| cuentas | Alias, tipo y referencia contable única; solo últimos cuatro dígitos opcionales. No guarda saldo editable. |
| cuentas_por_cobrar | Subcuenta contable por contacto y moneda; es dinero esperado y no efectivo disponible. |
| operaciones | Identidad idempotente, tipo, fecha efectiva, autor, estado y referencia al original si es reverso. |
| asiento_partidas | Debe positivo y haber negativo; ámbito y moneda protegidos por claves foráneas compuestas. |
| auditoria | Confirmación o reversión, actor y fecha. Auditoría de accesos y cambios de configuración se implementará aparte. |

## Interpretación de saldos

`v_saldos_contables.saldo_deudor` suma solo partidas de operaciones confirmadas, incluyendo reversos. En activo/gasto se interpreta positivo; para ingreso/pasivo/patrimonio normalmente se invierte el signo al presentar. `v_saldos_cuentas` presenta dinero en ACTIVO y deuda en PASIVO; una tarjeta con saldo negativo tiene saldo a favor.

`v_por_cobrar` presenta saldo por persona/moneda, nunca sumarlo al efectivo. El reporte de consumo toma cuentas GASTO; el de ingresos toma INGRESO, y el de flujo toma entradas y salidas de cuentas de dinero. La consulta anual debe filtrar fecha efectiva, espacio y moneda de forma consistente.

## Límites explícitos de este núcleo

- No hay interfaz, endpoints, autorización de lecturas implementada ni flujo de autenticación funcional.
- No hay categorías jerárquicas todavía: las cuentas GASTO/INGRESO se utilizan como clasificación inicial y se vincularán después.
- No hay calendario, planes a meses, límites/cortes de tarjetas, préstamos con intereses, presupuestos, inversiones ni cambio de moneda.
- Cobros a terceros reducen el saldo global por persona; la asignación a boletos/compras concretas y sus vencimientos se agrega con el detalle de deudas.
- No acepta anticipos que excedan el por cobrar. No incluye apertura de cuentas por cobrar anteriores; se incorporará con deudas existentes.
- Una sola apertura vigente por cuenta financiera; el detalle de planes existentes deberá desglosar esa apertura, no repetirla.
- Las rutinas no impiden sobregiros: la política por cuenta se definirá en el módulo correspondiente.
- No permite editar identidad de cuentas; evitar asignar una misma cuenta contable como cuenta de efectivo y cuenta por cobrar mediante las futuras altas autorizadas.
- No hay borrado en cascada de movimientos; respaldos y conservación deben definirse antes de producción.

Estas limitaciones son trabajo pendiente identificado, no funcionalidades entregadas.
