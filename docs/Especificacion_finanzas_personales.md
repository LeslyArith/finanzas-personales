# Aplicación privada de finanzas personales y compartidas

Versión 1.0 — Especificación funcional para desarrollo

## Objetivo

Administrar dinero disponible, consumo propio, obligaciones y cuentas por cobrar. Cada persona mantiene un espacio privado y puede participar en grupos de pareja, casa, familia o viajes. La información compartida no expone las cuentas privadas.

## Plataforma prevista

PHP con estructura MVC, base de datos MySQL, jQuery y peticiones AJAX. Interfaz responsive, Select2 para selectores y formularios breves. Despliegue previsto en Hostinger. Las versiones y capacidades del alojamiento se verificarán antes de implementar; este documento no constituye una aplicación ejecutable ni migraciones SQL.

## Navegación y pantallas

| Pantalla | Información y acciones |
|---|---|
| Configuración inicial | Fecha de inicio, moneda, zona horaria, cuentas, saldos, deudas y compras a meses existentes. Revisión antes de confirmar. |
| Inicio | Dinero actual, reservas, pendientes por cobrar, deuda, próximos pagos y proyección hasta el siguiente ingreso. |
| Movimientos | Buscar y filtrar; registrar ingresos, gastos, transferencias y devoluciones. Ver desglose, comprobantes e historial. |
| Cuentas y tarjetas | Saldo por cuenta, moneda, historial; tarjetas con deuda, periodos, límite y mensualidades. |
| Calendario | Mes y año seleccionables; ingresos previstos, vencimientos, cobros, suscripciones y cortes informativos. |
| Resumen anual | Comparación mensual de ingresos y consumo propio; flujo de dinero separado; presupuesto, deuda y metas. Datos reales diferenciados de proyecciones. |
| Personas y deudas | Contactos con o sin usuario, detalle por origen, abonos, vencimientos y saldo en ambos sentidos. |
| Compras a meses | Compra original, capital pendiente, mensualidades pagadas, cobradas pendientes y futuras. |
| Suscripciones | Servicio, correo asociado, titular, frecuencia, importe, moneda y medio de pago. Sin almacenar contraseñas del servicio. |
| Presupuestos y metas | Presupuesto semanal, quincenal o mensual; ahorro, apartados y compromisos asociados. |
| Grupos | Integrantes, acuerdos vigentes, gastos, pagadores, reparto y liquidaciones. |
| Seguridad y configuración | Perfil, segundo factor, sesiones, invitaciones, categorías y exportación. |

Selector global: Mis finanzas o un grupo autorizado. Los permisos se aplican en el servidor, incluidos archivos y exportaciones.

## Formulario de gasto

Campos base: importe, moneda, fecha efectiva, cuenta o tarjeta y categoría. Concepto y comprobante opcionales. Opciones ampliables: compartido, varios medios de pago, varios conceptos y compra a meses. Antes de confirmar, mostrar cuánto sale de cada cuenta, cuánto corresponde al usuario, cuánto se genera por cobrar y cuánto aumenta la deuda.

## Reglas financieras

1. El consumo propio, los movimientos de dinero y la deuda se reportan por separado.
2. Transferir entre cuentas propias y retirar efectivo no genera ingreso ni gasto; las comisiones sí son gastos.
3. Pagar una tarjeta reduce dinero y deuda, sin repetir el gasto de compra.
4. Cobrar un adelanto reduce una cuenta por cobrar; recibir un préstamo aumenta una obligación. No son nuevos ingresos ganados.
5. Los compromisos programados no alteran saldos reales hasta confirmar el movimiento.
6. Los saldos iniciales son asientos de apertura, no ingresos del periodo.
7. Los importes usan DECIMAL y reglas explícitas de redondeo; los repartos suman exactamente el total.
8. Los asientos confirmados se corrigen mediante reversión y reemplazo vinculados; se conserva la trazabilidad.
9. Una operación confirmada y sus efectos se guardan en una transacción; una clave de idempotencia evita dobles registros.
10. Una cuenta utiliza una moneda. En cambio de moneda se conservan los dos importes, la tasa y las comisiones. Los reportes consolidados indican su criterio de conversión.
11. Una reserva reduce el disponible para nuevos usos, no el saldo bancario. Una reserva asociada a un compromiso no se descuenta dos veces.
12. Las consultas personales y de grupo no suman dos veces la misma participación.

## Casos de aceptación

### Gasto compartido con tarjeta

Compra de comida por $1,200 entre tres personas: gasto propio $400, cuentas por cobrar $800 y deuda de tarjeta $1,200. El grupo registra $1,200. Cada deudor tiene nombre e importe. Un abono de $400 aumenta banco y reduce la cuenta por cobrar, sin ingreso ganado. Pagar la tarjeta reduce banco y deuda. Los $800 por cobrar no se consideran efectivo disponible.

### Compra a meses anterior al inicio

Compra original de $12,000 a doce meses sin intereses, seis mensualidades completamente pagadas: apertura de deuda por $6,000 y seis vencimientos pendientes de $1,000. No crear el gasto original en el mes de alta ni salidas bancarias anteriores. Si solo hay cinco pagadas y la sexta está cobrada pendiente, la deuda es $7,000: distinguir lo ya exigible de lo futuro. Con intereses, anticipos o devoluciones se captura el saldo y calendario documentados, sin inferirlos solo por división.

### Deuda inicial de tarjeta

Los planes existentes desglosan el total inicial; no se agregan otra vez encima del total. La confirmación de apertura exige cuadrar compras normales, capital de planes, intereses y comisiones. Diferencias quedan identificadas para revisión.

### Calendario y reporte anual

Una mensualidad incluida en el vencimiento de tarjeta no genera otro pago previsto independiente. El corte es informativo. Los pendientes vencidos continúan al siguiente mes. El reporte de consumo reconoce la compra propia cuando ocurre; el reporte de pagos muestra las salidas por fecha. Los periodos de tarjeta conservan fechas reales y valores confirmados del estado de cuenta; lo estimado lleva etiqueta.

### Devoluciones y cambios

Una devolución compartida ajusta gasto propio, cuentas por cobrar y medio de pago según el reparto aplicable. Si alguien ya abonó, puede originarse un saldo a su favor. Cambiar un reparto conserva historial y no altera silenciosamente registros privados ajenos. Condonar deuda exige una operación explícita y su efecto financiero.

## Identidad y privacidad

Registro público deshabilitado. Invitaciones individuales temporales de un solo uso. Roles de administración de acceso separados de roles de grupo. Ser administrador de acceso no otorga acceso funcional a finanzas privadas; la administración del servidor o base de datos es un nivel técnico distinto.

Un contacto no requiere usuario. Vincularlo con un usuario exige invitación y aceptación. Una deuda registrada por una persona es inicialmente su registro: no se publica como deuda aceptada en las finanzas del otro. Se distinguen propuesta, aceptada y en revisión.

Los grupos admiten administrador, integrante y consulta. La salida revoca acceso y mantiene historial. Todo archivo y exportación verifica autorización actual. Compartir una compra no comparte saldo bancario ni otros movimientos. Pueden existir gastos ocasionales entre contactos sin grupo permanente.

## Seguridad requerida

HTTPS, hashes de contraseña mediante APIs de PHP y parámetros revisados al implementar; tokens aleatorios almacenados como hash; recuperación con vencimiento y un solo uso. Segundo factor con secreto cifrado, claves fuera de la base de datos y códigos de recuperación con hash. Limitación de intentos y mensajes que no revelen usuarios existentes.

Sesiones con cookies seguras, protección CSRF, renovación tras autenticación y cambios de privilegio, límites de inactividad y duración absoluta y revocación. Autorización por objeto en toda petición. Consultas parametrizadas, validación de entrada y escape de salida según contexto. Archivos privados con límites y tipos permitidos; sin ejecución de archivos subidos.

Credenciales, respaldos y registros fuera del acceso web público. No guardar CVV, NIP, números completos de tarjeta ni contraseñas bancarias. Errores públicos genéricos, auditoría sin secretos, respaldos protegidos y restauración probada. Pruebas con datos ficticios. Revisión del alojamiento y configuración antes de producción.

## Modelo lógico de datos

Este inventario guía el diseño físico: las claves, índices y restricciones deberán concretarse en migraciones revisadas.

| Dominio | Entidades |
|---|---|
| Identidad | usuarios, invitaciones, sesiones_usuario, recuperaciones_acceso, segundos_factores, codigos_recuperacion, roles de acceso |
| Espacios | espacios, espacio_integrantes, invitaciones_grupo; espacio personal único por usuario |
| Catálogos | monedas, instituciones_financieras, categorias, contactos, etiquetas |
| Cuentas | cuentas, tarjetas_credito, cuentas_contables |
| Registro financiero | operaciones, operacion_conceptos, asientos, asiento_partidas, transferencias, operacion_etiquetas |
| Crédito | periodos_tarjeta, periodo_tarjeta_movimientos, planes_mensualidades, mensualidades, aplicaciones_pago_tarjeta |
| Deudas | deudas, deuda_cargos, deuda_vencimientos, deuda_aplicaciones |
| Repartos | gastos_compartidos, gasto_compartido_conceptos, gasto_compartido_pagadores, gasto_compartido_repartos, liquidaciones_grupo, acuerdos_reparto |
| Programación | servicios_suscripciones, reglas_recurrencia, compromisos, compromiso_aplicaciones |
| Planeación | presupuestos, presupuesto_detalles, metas_ahorro, apartados, apartado_movimientos, compromiso_apartados |
| Control | conciliaciones, conciliacion_detalles, archivos, vínculos autorizados de comprobantes, auditoria |

Las operaciones compartidas usarán una identidad común para evitar duplicar obligaciones: un registro compartido y sus proyecciones personales deben estar vinculados. No se podrá registrar una segunda deuda manual por el mismo origen sin advertencia y revisión. Contactos y participantes de operaciones ocasionales no dependerán de un grupo obligatorio.

El libro interno será de partida doble con referencias al espacio propietario. Las relaciones deberán impedir mezclar objetos de distintos espacios sin una vinculación compartida autorizada. El balance contable entre monedas requiere una política explícita y no se valida sumando cantidades de monedas distintas.

## Fases y criterios de entrega

| Fase | Entrega | Criterio principal |
|---|---|---|
| 1 | Acceso, espacios, cuentas, apertura y movimientos | Aislamiento entre usuarios, saldos cuadrados, transferencias atómicas y guardados idempotentes. |
| 2 | Tarjetas, planes existentes, deudas y conciliación | Apertura sin duplicados, pagos sin repetir gastos y vencimientos verificables. |
| 3 | Contactos, gastos compartidos, grupos y abonos | Repartos exactos, privacidad de cuentas y cobros con historial. |
| 4 | Calendario, recurrencias y suscripciones | Programado separado de confirmado; vencimientos de tarjeta sin doble conteo. |
| 5 | Presupuestos, metas y dashboard anual | Separación de consumo, flujo y proyección; cifras rastreables al movimiento original. |

La estructura compartida se contempla en fase 1, aunque sus pantallas se entreguen después. Importación bancaria e inversiones quedan como ampliaciones posteriores; no se presupone conexión automática con bancos.

## Pruebas mínimas transversales

- Intentar consultar, modificar o descargar datos ajenos debe fallar incluso cambiando identificadores.
- Reutilizar invitaciones o tokens vencidos debe fallar; revocar sesión o membresía debe retirar acceso.
- Un fallo intermedio de transferencia no modifica ningún saldo.
- Repetir una petición de guardado no duplica el movimiento.
- Repartir $100 entre tres personas produce participaciones que suman $100.
- Reembolsos, anticipos, abonos parciales y reversión mantienen saldos y trazabilidad.
- Los totales del dashboard coinciden con el detalle bajo los mismos filtros y criterio de fecha.
- Se puede restaurar un respaldo en un entorno de prueba.

## Siguiente entregable técnico

Migraciones SQL de fase 1, diccionario de columnas y restricciones, contratos de operaciones y pruebas del núcleo financiero. Confirmar versiones de PHP/MySQL y estructura de despliegue antes de generar código dependiente del alojamiento.
