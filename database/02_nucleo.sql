-- Importar después de 01_esquema.sql con cliente compatible con DELIMITER.
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DELIMITER $$

CREATE TRIGGER operacion_insertar BEFORE INSERT ON operaciones FOR EACH ROW
BEGIN
 IF NEW.estado<>'BORRADOR' OR NEW.confirmado_en IS NOT NULL THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Crear primero un borrador';
 END IF;
END$$

CREATE TRIGGER operacion_actualizar BEFORE UPDATE ON operaciones FOR EACH ROW
BEGIN
 DECLARE v_total DECIMAL(30,4);
 DECLARE v_n INT;
 DECLARE v_cuentas INT;
 IF OLD.estado='CONFIRMADA' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Operacion confirmada inmutable: registrar reverso';
 END IF;
 IF NOT (NEW.espacio_id <=> OLD.espacio_id) OR NOT (NEW.moneda <=> OLD.moneda)
    OR NOT (NEW.id <=> OLD.id) OR NOT (NEW.creado_por <=> OLD.creado_por)
    OR NOT (NEW.clave_idempotencia <=> OLD.clave_idempotencia)
    OR NOT (NEW.tipo <=> OLD.tipo) OR NOT (NEW.reversa_de <=> OLD.reversa_de) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Identidad de operacion inmutable';
 END IF;
 IF NEW.estado='CONFIRMADA' THEN
  SELECT COUNT(*),COUNT(DISTINCT cuenta_contable_id),COALESCE(SUM(importe),0)
   INTO v_n,v_cuentas,v_total FROM asiento_partidas WHERE operacion_id=OLD.id;
  IF v_n<2 OR v_cuentas<2 OR v_total<>0 THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Asiento incompleto o desbalanceado';
  END IF;
 END IF;
END$$

CREATE TRIGGER operacion_eliminar BEFORE DELETE ON operaciones FOR EACH ROW
BEGIN
 IF OLD.estado='CONFIRMADA' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No eliminar operaciones confirmadas';
 END IF;
END$$

CREATE TRIGGER partida_insertar BEFORE INSERT ON asiento_partidas FOR EACH ROW
BEGIN
 DECLARE v_estado VARCHAR(30) DEFAULT NULL;
 DECLARE v_dec TINYINT;
 SELECT estado INTO v_estado FROM operaciones WHERE id=NEW.operacion_id FOR UPDATE;
 IF v_estado IS NULL OR v_estado<>'BORRADOR' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Solo insertar partidas en borradores';
 END IF;
 SELECT decimales INTO v_dec FROM monedas WHERE codigo=NEW.moneda;
 IF NEW.importe<>ROUND(NEW.importe,v_dec) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Importe no representable en la moneda';
 END IF;
END$$

CREATE TRIGGER partida_actualizar BEFORE UPDATE ON asiento_partidas FOR EACH ROW
BEGIN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Partidas inmutables: reemplazar borrador o reversar';
END$$

CREATE TRIGGER partida_eliminar BEFORE DELETE ON asiento_partidas FOR EACH ROW
BEGIN
 DECLARE v_estado VARCHAR(30) DEFAULT NULL;
 SELECT estado INTO v_estado FROM operaciones WHERE id=OLD.operacion_id FOR UPDATE;
 IF v_estado IS NULL OR v_estado<>'BORRADOR' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No eliminar partidas confirmadas';
 END IF;
END$$

-- Identidad/moneda/naturaleza contables no cambian una vez creadas.
CREATE TRIGGER contable_actualizar BEFORE UPDATE ON cuentas_contables FOR EACH ROW
BEGIN
 IF NEW.id<>OLD.id OR NEW.espacio_id<>OLD.espacio_id OR NEW.moneda<>OLD.moneda OR NEW.tipo<>OLD.tipo THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Identidad contable inmutable';
 END IF;
END$$

CREATE TRIGGER cuenta_actualizar BEFORE UPDATE ON cuentas FOR EACH ROW
BEGIN
 IF NEW.id<>OLD.id OR NEW.espacio_id<>OLD.espacio_id OR NEW.moneda<>OLD.moneda
    OR NEW.cuenta_contable_id<>OLD.cuenta_contable_id OR NEW.naturaleza<>OLD.naturaleza OR NEW.tipo<>OLD.tipo THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Identidad de cuenta inmutable';
 END IF;
 IF NEW.archivada_en IS NOT NULL AND OLD.archivada_en IS NULL
    AND EXISTS(SELECT 1 FROM v_saldos_cuentas WHERE cuenta_id=OLD.id AND saldo<>0) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Resolver saldo antes de archivar';
 END IF;
END$$

CREATE PROCEDURE sp_registrar_operacion(
 IN p_usuario BIGINT UNSIGNED, IN p_espacio BIGINT UNSIGNED,
 IN p_clave VARBINARY(64), IN p_tipo VARCHAR(30), IN p_fecha DATE,
 IN p_concepto VARCHAR(255), IN p_debe BIGINT UNSIGNED,
 IN p_haber BIGINT UNSIGNED, IN p_importe VARCHAR(40)
)
SQL SECURITY DEFINER
principal: BEGIN
 DECLARE v_zona VARCHAR(64);
 DECLARE v_hoy DATE;
 DECLARE v_esp_tipo VARCHAR(30) DEFAULT NULL;
 DECLARE v_prop BIGINT UNSIGNED;
 DECLARE v_rol VARCHAR(30) DEFAULT NULL;
 DECLARE v_puede BOOLEAN DEFAULT FALSE;
 DECLARE v_usuario VARCHAR(30) DEFAULT NULL;
 DECLARE v_inicio DATE;
 DECLARE v_moneda CHAR(3) DEFAULT NULL;
 DECLARE v_moneda_h CHAR(3) DEFAULT NULL;
 DECLARE v_tipo_d VARCHAR(30);
 DECLARE v_tipo_h VARCHAR(30);
 DECLARE v_fin_d INT;
 DECLARE v_fin_h INT;
 DECLARE v_cxc_d INT;
 DECLARE v_cxc_h INT;
 DECLARE v_pendiente DECIMAL(30,4);
 DECLARE v_n INT;
 DECLARE v_id BIGINT UNSIGNED DEFAULT NULL;
 DECLARE v_dec TINYINT;
 DECLARE v_importe DECIMAL(19,4);
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

 -- Contrato: llamada independiente; no invocar dentro de otra transacción.
 START TRANSACTION;
 -- Bloqueo común del espacio: toda mutación/revocación debe tomarlo primero.
 SELECT tipo,propietario_personal_id,fecha_inicio,zona_horaria INTO v_esp_tipo,v_prop,v_inicio,v_zona
  FROM espacios WHERE id=p_espacio AND activo=TRUE FOR UPDATE;
 SELECT u.estado INTO v_usuario FROM usuarios u JOIN cat_estados_usuario eu ON eu.codigo=u.estado
  WHERE u.id=p_usuario AND eu.activo=TRUE AND eu.permite_acceso=TRUE FOR UPDATE;
 IF v_esp_tipo IS NULL OR v_usuario IS NULL THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Acceso denegado';
 END IF;
 IF v_esp_tipo='PERSONAL' THEN
  IF v_prop<>p_usuario THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Acceso denegado'; END IF;
 ELSE
  SELECT ei.rol,cr.puede_registrar INTO v_rol,v_puede FROM espacio_integrantes ei
   JOIN cat_roles_espacio cr ON cr.codigo=ei.rol
   WHERE ei.espacio_id=p_espacio AND ei.usuario_id=p_usuario AND ei.activo=TRUE AND cr.activo=TRUE FOR UPDATE;
  IF v_rol IS NULL OR v_puede=FALSE THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Acceso denegado';
  END IF;
 END IF;
 SET v_hoy=DATE(CONVERT_TZ(UTC_TIMESTAMP(),'+00:00',v_zona));
 IF v_hoy IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Zona horaria no disponible en MySQL'; END IF;
 IF p_tipo IS NULL OR p_tipo NOT IN ('APERTURA','INGRESO','GASTO','TRANSFERENCIA','PAGO_TARJETA','COMPRA_TERCERO','COBRO_TERCERO')
    OR p_fecha IS NULL OR p_fecha<v_inicio OR p_fecha>v_hoy
    OR p_clave IS NULL OR OCTET_LENGTH(p_clave) NOT BETWEEN 16 AND 64
    OR p_concepto IS NULL OR CHAR_LENGTH(TRIM(p_concepto))=0
    OR p_debe IS NULL OR p_haber IS NULL OR p_debe=p_haber THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Datos de operacion invalidos';
 END IF;
 IF p_tipo='APERTURA' AND p_fecha<>v_inicio THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Apertura debe usar fecha de inicio';
 END IF;
 -- Validar texto ANTES de convertir: no redondear silenciosamente fracciones.
 IF p_importe IS NULL OR p_importe NOT REGEXP '^[0-9]{1,15}([.][0-9]{1,4})?$' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Importe decimal invalido';
 END IF;
 SET v_importe=CAST(p_importe AS DECIMAL(19,4));
 IF v_importe<=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Importe debe ser positivo'; END IF;
 SELECT moneda,tipo INTO v_moneda,v_tipo_d FROM cuentas_contables
  WHERE id=p_debe AND espacio_id=p_espacio AND activo=TRUE FOR UPDATE;
 SELECT moneda,tipo INTO v_moneda_h,v_tipo_h FROM cuentas_contables
  WHERE id=p_haber AND espacio_id=p_espacio AND activo=TRUE FOR UPDATE;
 IF v_moneda IS NULL OR v_moneda_h IS NULL OR v_moneda<>v_moneda_h THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Cuentas invalidas o monedas diferentes';
 END IF;
 SELECT decimales INTO v_dec FROM monedas WHERE codigo=v_moneda;
 IF v_importe<>ROUND(v_importe,v_dec) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Importe no representable en la moneda';
 END IF;
 SELECT id INTO v_id FROM operaciones
  WHERE espacio_id=p_espacio AND clave_idempotencia=p_clave FOR UPDATE;
 IF v_id IS NOT NULL THEN
  SELECT COUNT(*) INTO v_n FROM operaciones o WHERE o.id=v_id AND o.creado_por=p_usuario
   AND o.tipo=p_tipo AND o.fecha_efectiva=p_fecha AND BINARY o.concepto=BINARY p_concepto
   AND o.estado='CONFIRMADA' AND o.moneda=v_moneda
   AND (SELECT COUNT(*) FROM asiento_partidas WHERE operacion_id=o.id)=2
   AND EXISTS(SELECT 1 FROM asiento_partidas WHERE operacion_id=o.id AND cuenta_contable_id=p_debe AND importe=v_importe)
   AND EXISTS(SELECT 1 FROM asiento_partidas WHERE operacion_id=o.id AND cuenta_contable_id=p_haber AND importe=-v_importe);
  IF v_n<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Clave reutilizada con datos diferentes'; END IF;
  COMMIT;
  SELECT v_id AS operacion_id,TRUE AS repetida;
  LEAVE principal;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM cat_tipos_operacion WHERE codigo=p_tipo AND activo=TRUE) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Tipo de operacion desactivado';
 END IF;
 SELECT COUNT(*) INTO v_fin_d FROM cuentas c JOIN cat_tipos_cuenta tc ON tc.codigo=c.tipo
  WHERE c.cuenta_contable_id=p_debe AND c.archivada_en IS NULL AND tc.activo=TRUE;
 SELECT COUNT(*) INTO v_fin_h FROM cuentas c JOIN cat_tipos_cuenta tc ON tc.codigo=c.tipo
  WHERE c.cuenta_contable_id=p_haber AND c.archivada_en IS NULL AND tc.activo=TRUE;
 SELECT COUNT(*) INTO v_cxc_d FROM cuentas_por_cobrar WHERE cuenta_contable_id=p_debe;
 SELECT COUNT(*) INTO v_cxc_h FROM cuentas_por_cobrar WHERE cuenta_contable_id=p_haber;
 IF p_tipo='COBRO_TERCERO' THEN
  SELECT COALESCE(SUM(ap.importe),0) INTO v_pendiente FROM asiento_partidas ap
   JOIN operaciones o ON o.id=ap.operacion_id
   WHERE ap.cuenta_contable_id=p_haber AND o.estado='CONFIRMADA';
  IF v_importe>v_pendiente THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Cobro excede pendiente; anticipos requieren otro flujo';
  END IF;
 END IF;
 IF NOT (
  (p_tipo='COMPRA_TERCERO' AND v_cxc_d=1 AND v_fin_d=0 AND v_fin_h=1 AND v_tipo_h IN ('ACTIVO','PASIVO')) OR
  (p_tipo='COBRO_TERCERO' AND v_fin_d=1 AND v_tipo_d IN ('ACTIVO','PASIVO') AND v_cxc_h=1 AND v_fin_h=0) OR
  (p_tipo='INGRESO' AND v_fin_d=1 AND v_tipo_d='ACTIVO' AND v_tipo_h='INGRESO') OR
  (p_tipo='GASTO' AND v_tipo_d='GASTO' AND v_fin_h=1 AND v_tipo_h IN ('ACTIVO','PASIVO')) OR
  (p_tipo='TRANSFERENCIA' AND v_fin_d=1 AND v_fin_h=1 AND v_tipo_d='ACTIVO' AND v_tipo_h='ACTIVO') OR
  (p_tipo='PAGO_TARJETA' AND v_fin_d=1 AND v_fin_h=1 AND v_tipo_d='PASIVO' AND v_tipo_h='ACTIVO') OR
  (p_tipo='APERTURA' AND ((v_fin_d=1 AND v_tipo_d='ACTIVO' AND v_tipo_h='PATRIMONIO') OR
                        (v_tipo_d='PATRIMONIO' AND v_fin_h=1 AND v_tipo_h='PASIVO')))
 ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Cuentas incompatibles con tipo de operacion'; END IF;
 IF p_tipo='APERTURA' AND EXISTS (
  SELECT 1 FROM operaciones o JOIN asiento_partidas ap ON ap.operacion_id=o.id
   WHERE o.espacio_id=p_espacio AND o.tipo='APERTURA' AND o.estado='CONFIRMADA'
   AND ap.cuenta_contable_id IN (p_debe,p_haber)
   AND ap.cuenta_contable_id IN (SELECT cuenta_contable_id FROM cuentas)
   AND NOT EXISTS(SELECT 1 FROM operaciones r WHERE r.reversa_de=o.id AND r.estado='CONFIRMADA')
 ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Cuenta ya tiene apertura vigente'; END IF;
 INSERT INTO operaciones(espacio_id,moneda,creado_por,clave_idempotencia,tipo,fecha_efectiva,concepto)
  VALUES(p_espacio,v_moneda,p_usuario,p_clave,p_tipo,p_fecha,p_concepto);
 SET v_id=LAST_INSERT_ID();
 INSERT INTO asiento_partidas(espacio_id,moneda,operacion_id,cuenta_contable_id,importe) VALUES
  (p_espacio,v_moneda,v_id,p_debe,v_importe),(p_espacio,v_moneda,v_id,p_haber,-v_importe);
 UPDATE operaciones SET estado='CONFIRMADA',confirmado_en=UTC_TIMESTAMP(6) WHERE id=v_id;
 INSERT INTO auditoria(espacio_id,actor_id,operacion_id,moneda,accion)
  VALUES(p_espacio,p_usuario,v_id,v_moneda,'CONFIRMAR');
 COMMIT;
 SELECT v_id AS operacion_id,FALSE AS repetida;
END$$

CREATE PROCEDURE sp_reversar_operacion(
 IN p_usuario BIGINT UNSIGNED,IN p_espacio BIGINT UNSIGNED,
 IN p_original BIGINT UNSIGNED,IN p_clave VARBINARY(64),IN p_fecha DATE,IN p_motivo VARCHAR(255)
)
SQL SECURITY DEFINER
principal: BEGIN
 DECLARE v_zona VARCHAR(64);
 DECLARE v_hoy DATE;
 DECLARE v_prop BIGINT UNSIGNED;
 DECLARE v_tipo VARCHAR(30) DEFAULT NULL;
 DECLARE v_rol VARCHAR(30) DEFAULT NULL;
 DECLARE v_puede BOOLEAN DEFAULT FALSE;
 DECLARE v_usuario VARCHAR(30) DEFAULT NULL;
 DECLARE v_moneda CHAR(3) DEFAULT NULL;
 DECLARE v_fecha DATE;
 DECLARE v_id BIGINT UNSIGNED DEFAULT NULL;
 DECLARE v_n INT;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
 START TRANSACTION;
 SELECT tipo,propietario_personal_id,zona_horaria INTO v_tipo,v_prop,v_zona FROM espacios WHERE id=p_espacio AND activo=TRUE FOR UPDATE;
 SELECT u.estado INTO v_usuario FROM usuarios u JOIN cat_estados_usuario eu ON eu.codigo=u.estado
  WHERE u.id=p_usuario AND eu.activo=TRUE AND eu.permite_acceso=TRUE FOR UPDATE;
 IF v_tipo IS NULL OR v_usuario IS NULL THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Acceso denegado';
 END IF;
 IF v_tipo='PERSONAL' THEN
  IF v_prop<>p_usuario THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Acceso denegado'; END IF;
 ELSE
  SELECT ei.rol,cr.puede_reversar INTO v_rol,v_puede FROM espacio_integrantes ei
   JOIN cat_roles_espacio cr ON cr.codigo=ei.rol
   WHERE ei.espacio_id=p_espacio AND ei.usuario_id=p_usuario AND ei.activo=TRUE AND cr.activo=TRUE FOR UPDATE;
  IF v_rol IS NULL OR v_puede=FALSE THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Rol sin permiso para reversar'; END IF;
 END IF;
 SET v_hoy=DATE(CONVERT_TZ(UTC_TIMESTAMP(),'+00:00',v_zona));
 IF v_hoy IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Zona horaria no disponible en MySQL'; END IF;
 IF p_clave IS NULL OR OCTET_LENGTH(p_clave) NOT BETWEEN 16 AND 64
    OR p_motivo IS NULL OR CHAR_LENGTH(TRIM(p_motivo))=0 OR p_fecha IS NULL THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Datos de reverso invalidos';
 END IF;
 SELECT moneda,fecha_efectiva INTO v_moneda,v_fecha FROM operaciones
  WHERE id=p_original AND espacio_id=p_espacio AND estado='CONFIRMADA' AND tipo<>'REVERSO' FOR UPDATE;
 IF v_moneda IS NULL OR p_fecha<v_fecha OR p_fecha>v_hoy THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Original o fecha invalidos';
 END IF;
 SELECT id INTO v_id FROM operaciones WHERE espacio_id=p_espacio AND clave_idempotencia=p_clave FOR UPDATE;
 IF v_id IS NOT NULL THEN
  SELECT COUNT(*) INTO v_n FROM operaciones WHERE id=v_id AND reversa_de=p_original AND creado_por=p_usuario
   AND tipo='REVERSO' AND estado='CONFIRMADA' AND fecha_efectiva=p_fecha AND BINARY concepto=BINARY p_motivo;
  IF v_n<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Clave reutilizada con datos diferentes'; END IF;
  COMMIT; SELECT v_id AS operacion_id,TRUE AS repetida; LEAVE principal;
 END IF;
 IF EXISTS(SELECT 1 FROM operaciones WHERE reversa_de=p_original) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Original ya reversado';
 END IF;
 INSERT INTO operaciones(espacio_id,moneda,creado_por,clave_idempotencia,tipo,fecha_efectiva,concepto,reversa_de)
  VALUES(p_espacio,v_moneda,p_usuario,p_clave,'REVERSO',p_fecha,p_motivo,p_original);
 SET v_id=LAST_INSERT_ID();
 INSERT INTO asiento_partidas(espacio_id,moneda,operacion_id,cuenta_contable_id,importe)
  SELECT espacio_id,moneda,v_id,cuenta_contable_id,-importe FROM asiento_partidas WHERE operacion_id=p_original;
 UPDATE operaciones SET estado='CONFIRMADA',confirmado_en=UTC_TIMESTAMP(6) WHERE id=v_id;
 INSERT INTO auditoria(espacio_id,actor_id,operacion_id,moneda,accion)
  VALUES(p_espacio,p_usuario,v_id,v_moneda,'REVERSAR');
 COMMIT; SELECT v_id AS operacion_id,FALSE AS repetida;
END$$
DELIMITER ;
