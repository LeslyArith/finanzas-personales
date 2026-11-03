-- Ejecutar DESPUÉS de 03_pruebas.sql en la misma BASE DE PRUEBAS, no en producción.
-- No depende de conservar variables de sesión entre archivos.
SET @u=(SELECT id FROM usuarios WHERE correo_normalizado='prueba@example.invalid');
SET @e=(SELECT id FROM espacios WHERE propietario_personal_id=@u);
SET @g=(SELECT id FROM cuentas_contables WHERE espacio_id=@e AND nombre='Comida');
INSERT INTO cat_tipos_cuenta(codigo,nombre,naturaleza) VALUES('BILLETERA','Billetera digital','ACTIVO');
INSERT INTO cuentas_contables(espacio_id,moneda,nombre,tipo) VALUES(@e,'MXN','Billetera digital','ACTIVO');
SET @billetera=LAST_INSERT_ID();
INSERT INTO cuentas(espacio_id,moneda,cuenta_contable_id,naturaleza,tipo,nombre)
 VALUES(@e,'MXN',@billetera,'ACTIVO','BILLETERA','Billetera digital');
CALL sp_registrar_operacion(@u,@e,'catalogo-gasto-0001','GASTO',CURRENT_DATE(),'Compra con nuevo tipo',@g,@billetera,'10');

INSERT INTO cuentas_contables(espacio_id,moneda,nombre,tipo) VALUES(@e,'MXN','Cuenta para rechazo','ACTIVO');
SET @invalida=LAST_INSERT_ID();
INSERT INTO cuentas_contables(espacio_id,moneda,nombre,tipo) VALUES(@e,'MXN','Naturaleza incompatible','PASIVO');
SET @incompatible=LAST_INSERT_ID();

DELIMITER $$
CREATE PROCEDURE test_catalogos()
BEGIN
 DECLARE v_fallo BOOLEAN DEFAULT FALSE;
 IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND data_type='enum') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Quedan columnas con enumeraciones';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM v_saldos_cuentas WHERE cuenta_id=(SELECT id FROM cuentas WHERE cuenta_contable_id=@billetera) AND saldo=-10) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Nuevo tipo no opera como activo';
 END IF;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23000' SET v_fallo=TRUE;
  INSERT INTO cuentas(espacio_id,moneda,cuenta_contable_id,naturaleza,tipo,nombre)
   VALUES(@e,'MXN',@invalida,'ACTIVO','TIPO_INEXISTENTE','Debe fallar');
 END;
 IF NOT v_fallo THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Catalogo sin integridad'; END IF;
 SET v_fallo=FALSE;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23000' SET v_fallo=TRUE;
  INSERT INTO cuentas(espacio_id,moneda,cuenta_contable_id,naturaleza,tipo,nombre)
   VALUES(@e,'MXN',@incompatible,'PASIVO','BILLETERA','Debe fallar por naturaleza');
 END;
 IF NOT v_fallo THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Naturaleza incompatible aceptada'; END IF;
END$$
DELIMITER ;
CALL test_catalogos();
DROP PROCEDURE test_catalogos;

-- Rol nuevo sin cambiar la rutina: la autoridad depende de permisos, no del nombre.
INSERT INTO cat_roles_espacio(codigo,nombre,puede_registrar,puede_reversar)
 VALUES('CAPTURISTA','Capturista',TRUE,FALSE);
INSERT INTO espacios(tipo,nombre,moneda_referencia,zona_horaria,fecha_inicio)
 VALUES('GRUPO','Grupo de prueba de roles','MXN','+00:00',CURRENT_DATE());
SET @grupo=LAST_INSERT_ID();
INSERT INTO espacio_integrantes(espacio_id,usuario_id,rol) VALUES(@grupo,@u,'CAPTURISTA');
INSERT INTO cuentas_contables(espacio_id,moneda,nombre,tipo) VALUES(@grupo,'MXN','Banco de grupo','ACTIVO');
SET @gb=LAST_INSERT_ID();
INSERT INTO cuentas_contables(espacio_id,moneda,nombre,tipo) VALUES(@grupo,'MXN','Ingresos','INGRESO');
SET @gi=LAST_INSERT_ID();
INSERT INTO cuentas(espacio_id,moneda,cuenta_contable_id,naturaleza,tipo,nombre)
 VALUES(@grupo,'MXN',@gb,'ACTIVO','DEBITO','Banco de grupo');
CALL sp_registrar_operacion(@u,@grupo,'rol-nuevo-ingreso-01','INGRESO',CURRENT_DATE(),'Ingreso autorizado',@gb,@gi,'100');
SET @op=(SELECT id FROM operaciones WHERE espacio_id=@grupo AND clave_idempotencia='rol-nuevo-ingreso-01');
DELIMITER $$
CREATE PROCEDURE test_permisos_catalogo()
BEGIN
 DECLARE v_fallo BOOLEAN DEFAULT FALSE;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_fallo=TRUE;
  CALL sp_reversar_operacion(@u,@grupo,@op,'rol-no-reverso-0001',CURRENT_DATE(),'Debe fallar');
 END;
 IF NOT v_fallo THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Rol reverso sin permiso'; END IF;
END$$
DELIMITER ;
CALL test_permisos_catalogo();
DROP PROCEDURE test_permisos_catalogo;
SELECT 'PRUEBAS DE CATALOGOS COMPLETADAS' AS resultado;
