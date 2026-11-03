-- SOLO sobre una base de pruebas vacía, después de 01 y 02.
-- Crea datos ficticios persistentes; no ejecutar sobre datos personales.
INSERT INTO usuarios(nombre,correo_normalizado,password_hash) VALUES
 ('Prueba','prueba@example.invalid','NO_ES_UN_HASH_VALIDO'),
 ('Otra persona','otra@example.invalid','NO_ES_UN_HASH_VALIDO');
SET @u=LAST_INSERT_ID();
INSERT INTO espacios(tipo,propietario_personal_id,nombre,moneda_referencia,fecha_inicio)
 VALUES('PERSONAL',@u,'Pruebas','MXN',CURRENT_DATE());
UPDATE espacios SET zona_horaria='+00:00' WHERE propietario_personal_id=@u;
SET @e=LAST_INSERT_ID();
INSERT INTO cuentas_contables(espacio_id,moneda,nombre,tipo) VALUES
 (@e,'MXN','Banco','ACTIVO'),(@e,'MXN','Tarjeta','PASIVO'),
 (@e,'MXN','Comida','GASTO'),(@e,'MXN','Sueldo','INGRESO'),
 (@e,'MXN','Apertura','PATRIMONIO'),(@e,'MXN','Papá por cobrar','ACTIVO');
SET @b=LAST_INSERT_ID();
SET @t=@b+1; SET @g=@b+2; SET @i=@b+3; SET @p=@b+4; SET @cxc=@b+5;
INSERT INTO cuentas(espacio_id,moneda,cuenta_contable_id,naturaleza,tipo,nombre) VALUES
 (@e,'MXN',@b,'ACTIVO','DEBITO','Banco'),(@e,'MXN',@t,'PASIVO','CREDITO','Tarjeta');
INSERT INTO contactos(espacio_id,nombre) VALUES(@e,'Papá');
SET @contacto=LAST_INSERT_ID();
INSERT INTO cuentas_por_cobrar(espacio_id,contacto_id,moneda,cuenta_contable_id)
 VALUES(@e,@contacto,'MXN',@cxc);

DELIMITER $$
CREATE PROCEDURE test_assert(IN p_ok BOOLEAN,IN p_mensaje VARCHAR(128))
BEGIN
 IF p_ok IS NULL OR NOT p_ok THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=p_mensaje; END IF;
END$$
CREATE PROCEDURE test_rechazos()
BEGIN
 DECLARE fallo BOOLEAN DEFAULT FALSE;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET fallo=TRUE;
  CALL sp_registrar_operacion(@u+1,@e,'no-autorizado-0001','GASTO',CURRENT_DATE(),'Ajeno',@g,@b,'10');
 END;
 CALL test_assert(fallo,'FALLO: acceso ajeno permitido');
 SET fallo=FALSE;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET fallo=TRUE;
  CALL sp_registrar_operacion(@u,@e,'decimal-invalido-01','GASTO',CURRENT_DATE(),'Decimal',@g,@b,'0.001');
 END;
 CALL test_assert(fallo,'FALLO: fraccion invalida aceptada');
 SET fallo=FALSE;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET fallo=TRUE;
  CALL sp_registrar_operacion(@u,@e,'compra-papa-00001','COMPRA_TERCERO',CURRENT_DATE(),'Boletos',@cxc,@t,'9000');
 END;
 CALL test_assert(fallo,'FALLO: idempotencia con distinto importe aceptada');
 SET fallo=FALSE;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET fallo=TRUE;
  CALL sp_registrar_operacion(@u,@e,'sobrepago-papa-001','COBRO_TERCERO',CURRENT_DATE(),'Abono excesivo',@b,@cxc,'9000');
 END;
 CALL test_assert(fallo,'FALLO: sobrepago aceptado');
 SET fallo=FALSE;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET fallo=TRUE;
  UPDATE operaciones SET concepto='Alterado' WHERE id=@original;
 END;
 CALL test_assert(fallo,'FALLO: se modifico operacion confirmada');
END$$
DELIMITER ;

CALL sp_registrar_operacion(@u,@e,'apertura-banco-001','APERTURA',CURRENT_DATE(),'Saldo inicial',@b,@p,'10000');
CALL sp_registrar_operacion(@u,@e,'compra-papa-00001','COMPRA_TERCERO',CURRENT_DATE(),'Boletos',@cxc,@t,'8000');
SET @original=(SELECT id FROM operaciones WHERE espacio_id=@e AND clave_idempotencia='compra-papa-00001');
CALL sp_registrar_operacion(@u,@e,'compra-papa-00001','COMPRA_TERCERO',CURRENT_DATE(),'Boletos',@cxc,@t,'8000');
CALL test_assert((SELECT COUNT(*)=1 FROM operaciones WHERE id=@original),'Compra duplicada');
CALL test_assert((SELECT saldo=8000 FROM v_por_cobrar WHERE contacto_id=@contacto),'Por cobrar incorrecto');
CALL test_assert((SELECT saldo_deudor=0 FROM v_saldos_contables WHERE cuenta_contable_id=@g),'Compra ajena contada como gasto');
CALL sp_registrar_operacion(@u,@e,'abono-papa-000001','COBRO_TERCERO',CURRENT_DATE(),'Abono de papa',@b,@cxc,'3000');
CALL test_assert((SELECT saldo=5000 FROM v_por_cobrar WHERE contacto_id=@contacto),'Abono incorrecto');
CALL test_assert((SELECT saldo=13000 FROM v_saldos_cuentas WHERE espacio_id=@e AND tipo='DEBITO'),'Banco incorrecto');
CALL test_assert((SELECT saldo_deudor=0 FROM v_saldos_contables WHERE cuenta_contable_id=@i),'Cobro contado como ingreso');
CALL test_rechazos();
CALL test_assert((SELECT COUNT(*)=3 FROM operaciones WHERE espacio_id=@e),'Fallos dejaron operaciones parciales');
CALL sp_registrar_operacion(@u,@e,'pago-tarjeta-00001','PAGO_TARJETA',CURRENT_DATE(),'Pago de tarjeta',@t,@b,'8000');
CALL test_assert((SELECT saldo=0 FROM v_saldos_cuentas WHERE espacio_id=@e AND tipo='CREDITO'),'Deuda tarjeta incorrecta');
CALL test_assert((SELECT saldo=5000 FROM v_saldos_cuentas WHERE espacio_id=@e AND tipo='DEBITO'),'Saldo banco incorrecto');
CALL test_assert((SELECT saldo=5000 FROM v_por_cobrar WHERE contacto_id=@contacto),'Pago banco altero deuda de papa');
SET @abono=(SELECT id FROM operaciones WHERE espacio_id=@e AND clave_idempotencia='abono-papa-000001');
CALL sp_reversar_operacion(@u,@e,@abono,'reverso-abono-0001',CURRENT_DATE(),'Abono no recibido');
CALL sp_reversar_operacion(@u,@e,@abono,'reverso-abono-0001',CURRENT_DATE(),'Abono no recibido');
CALL test_assert((SELECT saldo=8000 FROM v_por_cobrar WHERE contacto_id=@contacto),'Reverso incorrecto');
CALL test_assert((SELECT saldo=2000 FROM v_saldos_cuentas WHERE espacio_id=@e AND tipo='DEBITO'),'Reverso banco incorrecto');
CALL test_assert(NOT EXISTS(SELECT operacion_id FROM asiento_partidas GROUP BY operacion_id HAVING SUM(importe)<>0),'Libro desbalanceado');
SELECT 'PRUEBAS COMPLETADAS' AS resultado;
DROP PROCEDURE test_rechazos;
DROP PROCEDURE test_assert;
