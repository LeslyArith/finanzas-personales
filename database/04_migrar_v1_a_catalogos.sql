-- SOLO para el paquete v1 ya instalado, sin modificaciones manuales.
-- Aplicación en mantenimiento, respaldo probado y copia de ensayo obligatorios.
-- No ejecutar 01_esquema.sql de nuevo. Importar 00_catalogos.sql antes.
SET NAMES utf8mb4;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
-- Validar antes con SHOW CREATE TABLE cuentas / cuentas_por_cobrar.
-- Estos nombres son los generados por MySQL al importar el paquete v1 original.
ALTER TABLE cuentas DROP FOREIGN KEY cuentas_ibfk_1;
ALTER TABLE cuentas_por_cobrar DROP FOREIGN KEY cuentas_por_cobrar_ibfk_2;
ALTER TABLE cuentas DROP CHECK ck_cuenta_naturaleza;
ALTER TABLE tokens_acceso DROP CHECK ck_recuperacion_usuario;
ALTER TABLE espacios DROP CHECK ck_espacio_propietario;
ALTER TABLE cuentas_por_cobrar DROP CHECK ck_cobrar_activo;
ALTER TABLE operaciones DROP CHECK ck_operacion_reverso, DROP CHECK ck_operacion_confirmacion;



ALTER TABLE usuarios
 MODIFY COLUMN estado VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'ACTIVO';

ALTER TABLE tokens_acceso
 MODIFY COLUMN tipo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL;

ALTER TABLE espacios
 MODIFY COLUMN tipo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL;

ALTER TABLE espacio_integrantes
 MODIFY COLUMN rol VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL;

ALTER TABLE cuentas_contables
 MODIFY COLUMN tipo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL;

ALTER TABLE cuentas
 MODIFY COLUMN naturaleza VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 MODIFY COLUMN tipo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL;

ALTER TABLE cuentas_por_cobrar
 MODIFY COLUMN naturaleza VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'ACTIVO';

ALTER TABLE operaciones
 MODIFY COLUMN tipo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 MODIFY COLUMN estado VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'BORRADOR';

ALTER TABLE auditoria
 MODIFY COLUMN accion VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL;

ALTER TABLE cuentas ADD CONSTRAINT fk_cuenta_contable_alcance
 FOREIGN KEY (espacio_id,moneda,cuenta_contable_id,naturaleza)
 REFERENCES cuentas_contables(espacio_id,moneda,id,tipo);
ALTER TABLE cuentas_por_cobrar ADD CONSTRAINT fk_cobrar_contable_alcance
 FOREIGN KEY (espacio_id,moneda,cuenta_contable_id,naturaleza)
 REFERENCES cuentas_contables(espacio_id,moneda,id,tipo);

ALTER TABLE usuarios
 ADD CONSTRAINT fk_usuarios_estado_cat FOREIGN KEY (estado) REFERENCES cat_estados_usuario(codigo);

ALTER TABLE tokens_acceso
 ADD CONSTRAINT fk_tokens_acceso_tipo_cat FOREIGN KEY (tipo) REFERENCES cat_tipos_token(codigo);

ALTER TABLE espacios
 ADD CONSTRAINT fk_espacios_tipo_cat FOREIGN KEY (tipo) REFERENCES cat_tipos_espacio(codigo);

ALTER TABLE espacio_integrantes
 ADD CONSTRAINT fk_espacio_integrantes_rol_cat FOREIGN KEY (rol) REFERENCES cat_roles_espacio(codigo);

ALTER TABLE cuentas_contables
 ADD CONSTRAINT fk_cuentas_contables_tipo_cat FOREIGN KEY (tipo) REFERENCES cat_tipos_contables(codigo);

ALTER TABLE cuentas
 ADD CONSTRAINT fk_cuentas_naturaleza_cat FOREIGN KEY (naturaleza) REFERENCES cat_tipos_contables(codigo),
 ADD CONSTRAINT fk_cuentas_tipo_naturaleza FOREIGN KEY (tipo,naturaleza) REFERENCES cat_tipos_cuenta(codigo,naturaleza);

ALTER TABLE cuentas_por_cobrar
 ADD CONSTRAINT fk_cuentas_por_cobrar_naturaleza_cat FOREIGN KEY (naturaleza) REFERENCES cat_tipos_contables(codigo);

ALTER TABLE operaciones
 ADD CONSTRAINT fk_operaciones_tipo_cat FOREIGN KEY (tipo) REFERENCES cat_tipos_operacion(codigo),
 ADD CONSTRAINT fk_operaciones_estado_cat FOREIGN KEY (estado) REFERENCES cat_estados_operacion(codigo);

ALTER TABLE auditoria
 ADD CONSTRAINT fk_auditoria_accion_cat FOREIGN KEY (accion) REFERENCES cat_acciones_auditoria(codigo);


ALTER TABLE tokens_acceso ADD CONSTRAINT ck_recuperacion_usuario
 CHECK (tipo <> 'RECUPERACION' OR usuario_id IS NOT NULL);
ALTER TABLE espacios ADD CONSTRAINT ck_espacio_propietario CHECK (
 (tipo='PERSONAL' AND propietario_personal_id IS NOT NULL) OR
 (tipo='GRUPO' AND propietario_personal_id IS NULL));
ALTER TABLE cuentas_por_cobrar ADD CONSTRAINT ck_cobrar_activo CHECK (naturaleza='ACTIVO');
ALTER TABLE operaciones ADD CONSTRAINT ck_operacion_reverso CHECK (
 (tipo='REVERSO' AND reversa_de IS NOT NULL) OR (tipo<>'REVERSO' AND reversa_de IS NULL)),
 ADD CONSTRAINT ck_operacion_confirmacion CHECK (
 (estado='BORRADOR' AND confirmado_en IS NULL) OR (estado='CONFIRMADA' AND confirmado_en IS NOT NULL));

DROP TRIGGER operacion_insertar;

DROP TRIGGER operacion_actualizar;

DROP TRIGGER operacion_eliminar;

DROP TRIGGER partida_insertar;

DROP TRIGGER partida_actualizar;

DROP TRIGGER partida_eliminar;

DROP TRIGGER contable_actualizar;

DROP TRIGGER cuenta_actualizar;

DROP PROCEDURE sp_registrar_operacion;

DROP PROCEDURE sp_reversar_operacion;

-- IMPORTAR INMEDIATAMENTE 02_nucleo.sql v2 antes de habilitar la aplicación.
