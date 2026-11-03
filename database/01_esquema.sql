-- Versión 2: importar primero 00_catalogos.sql.
-- Migración inicial: ejecutar UNA VEZ en una base vacía MySQL 8.0.21+.
-- No crea usuarios, contraseñas ni credenciales. No deshabilita foreign keys.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

CREATE TABLE monedas (
 codigo CHAR(3) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 nombre VARCHAR(60) NOT NULL,
 decimales TINYINT UNSIGNED NOT NULL,
 CONSTRAINT ck_moneda_decimales CHECK (decimales <= 4)
) ENGINE=InnoDB;
INSERT INTO monedas VALUES ('MXN','Peso mexicano',2),('USD','Dólar estadounidense',2);

CREATE TABLE usuarios (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL,
 correo_normalizado VARCHAR(254) NOT NULL UNIQUE,
 password_hash VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 estado VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'ACTIVO',
 administra_acceso BOOLEAN NOT NULL DEFAULT FALSE,
 version_sesiones INT UNSIGNED NOT NULL DEFAULT 1,
 creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 CONSTRAINT ck_usuario_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0),
 CONSTRAINT fk_usuarios_estado_cat FOREIGN KEY (estado) REFERENCES cat_estados_usuario(codigo)
) ENGINE=InnoDB;

CREATE TABLE tokens_acceso (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 tipo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 usuario_id BIGINT UNSIGNED NULL,
 correo_normalizado VARCHAR(254) NOT NULL,
 token_hash BINARY(32) NOT NULL UNIQUE,
 creado_por BIGINT UNSIGNED NULL,
 creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 vence_en DATETIME(6) NOT NULL,
 usado_en DATETIME(6) NULL,
 revocado_en DATETIME(6) NULL,
 FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
 FOREIGN KEY (creado_por) REFERENCES usuarios(id),
 CONSTRAINT ck_token_vigencia CHECK (vence_en > creado_en),
 CONSTRAINT ck_recuperacion_usuario CHECK (tipo <> 'RECUPERACION' OR usuario_id IS NOT NULL),
 CONSTRAINT fk_tokens_acceso_tipo_cat FOREIGN KEY (tipo) REFERENCES cat_tipos_token(codigo)
) ENGINE=InnoDB;

CREATE TABLE sesiones_usuario (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 usuario_id BIGINT UNSIGNED NOT NULL,
 token_hash BINARY(32) NOT NULL UNIQUE,
 version_usuario INT UNSIGNED NOT NULL,
 creado_en DATETIME(6) NOT NULL,
 ultima_actividad_en DATETIME(6) NOT NULL,
 vence_en DATETIME(6) NOT NULL,
 revocado_en DATETIME(6) NULL,
 FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
 INDEX ix_sesion_usuario (usuario_id, revocado_en),
 CONSTRAINT ck_sesion_vigencia CHECK (vence_en > creado_en)
) ENGINE=InnoDB;

CREATE TABLE segundos_factores (
 usuario_id BIGINT UNSIGNED PRIMARY KEY,
 secreto_cifrado VARBINARY(512) NOT NULL,
 version_clave VARCHAR(40) CHARACTER SET ascii NOT NULL,
 confirmado_en DATETIME(6) NULL,
 ultimo_paso_aceptado BIGINT UNSIGNED NULL,
 FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;
CREATE TABLE codigos_recuperacion (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 usuario_id BIGINT UNSIGNED NOT NULL,
 codigo_hash VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 usado_en DATETIME(6) NULL,
 FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;

CREATE TABLE espacios (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 tipo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 propietario_personal_id BIGINT UNSIGNED NULL UNIQUE,
 nombre VARCHAR(120) NOT NULL,
 moneda_referencia CHAR(3) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 zona_horaria VARCHAR(64) NOT NULL DEFAULT 'America/Ciudad_Juarez',
 fecha_inicio DATE NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 FOREIGN KEY (propietario_personal_id) REFERENCES usuarios(id),
 FOREIGN KEY (moneda_referencia) REFERENCES monedas(codigo),
 CONSTRAINT ck_espacio_propietario CHECK (
  (tipo='PERSONAL' AND propietario_personal_id IS NOT NULL) OR
  (tipo='GRUPO' AND propietario_personal_id IS NULL)),
 CONSTRAINT fk_espacios_tipo_cat FOREIGN KEY (tipo) REFERENCES cat_tipos_espacio(codigo)
) ENGINE=InnoDB;

CREATE TABLE espacio_integrantes (
 espacio_id BIGINT UNSIGNED NOT NULL,
 usuario_id BIGINT UNSIGNED NOT NULL,
 rol VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 incorporado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 retirado_en DATETIME(6) NULL,
 PRIMARY KEY (espacio_id,usuario_id),
 FOREIGN KEY (espacio_id) REFERENCES espacios(id),
 FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
 CONSTRAINT ck_integrante_retiro CHECK ((activo=TRUE AND retirado_en IS NULL) OR activo=FALSE),
 CONSTRAINT fk_espacio_integrantes_rol_cat FOREIGN KEY (rol) REFERENCES cat_roles_espacio(codigo)
) ENGINE=InnoDB;

CREATE TABLE contactos (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 espacio_id BIGINT UNSIGNED NOT NULL,
 nombre VARCHAR(120) NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 UNIQUE KEY uq_contacto_espacio (espacio_id,id),
 FOREIGN KEY (espacio_id) REFERENCES espacios(id)
) ENGINE=InnoDB;

CREATE TABLE cuentas_contables (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 espacio_id BIGINT UNSIGNED NOT NULL,
 moneda CHAR(3) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 nombre VARCHAR(120) NOT NULL,
 tipo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 UNIQUE KEY uq_contable_alcance (espacio_id,moneda,id),
 UNIQUE KEY uq_contable_tipo (espacio_id,moneda,id,tipo),
 FOREIGN KEY (espacio_id) REFERENCES espacios(id),
 FOREIGN KEY (moneda) REFERENCES monedas(codigo),
 CONSTRAINT fk_cuentas_contables_tipo_cat FOREIGN KEY (tipo) REFERENCES cat_tipos_contables(codigo)
) ENGINE=InnoDB;

CREATE TABLE cuentas (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 espacio_id BIGINT UNSIGNED NOT NULL,
 moneda CHAR(3) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 cuenta_contable_id BIGINT UNSIGNED NOT NULL UNIQUE,
 naturaleza VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 tipo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 nombre VARCHAR(120) NOT NULL,
 institucion VARCHAR(120) NULL,
 ultimos_cuatro CHAR(4) CHARACTER SET ascii NULL,
 archivada_en DATETIME(6) NULL,
 UNIQUE KEY uq_cuenta_alcance (espacio_id,id),
 FOREIGN KEY (espacio_id,moneda,cuenta_contable_id,naturaleza)
  REFERENCES cuentas_contables(espacio_id,moneda,id,tipo),
 CONSTRAINT ck_cuenta_cuatro CHECK (ultimos_cuatro IS NULL OR ultimos_cuatro REGEXP '^[0-9]{4}$'),
 CONSTRAINT fk_cuentas_naturaleza_cat FOREIGN KEY (naturaleza) REFERENCES cat_tipos_contables(codigo),
 CONSTRAINT fk_cuentas_tipo_naturaleza FOREIGN KEY (tipo,naturaleza) REFERENCES cat_tipos_cuenta(codigo,naturaleza)
) ENGINE=InnoDB;

-- Subcuenta por persona y moneda. Separa cuentas por cobrar de efectivo.
CREATE TABLE cuentas_por_cobrar (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 espacio_id BIGINT UNSIGNED NOT NULL,
 contacto_id BIGINT UNSIGNED NOT NULL,
 moneda CHAR(3) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 cuenta_contable_id BIGINT UNSIGNED NOT NULL UNIQUE,
 naturaleza VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'ACTIVO',
 UNIQUE KEY uq_cobrar_persona_moneda (espacio_id,contacto_id,moneda),
 FOREIGN KEY (espacio_id,contacto_id) REFERENCES contactos(espacio_id,id),
 FOREIGN KEY (espacio_id,moneda,cuenta_contable_id,naturaleza)
  REFERENCES cuentas_contables(espacio_id,moneda,id,tipo),
 CONSTRAINT ck_cobrar_activo CHECK (naturaleza='ACTIVO'),
 CONSTRAINT fk_cuentas_por_cobrar_naturaleza_cat FOREIGN KEY (naturaleza) REFERENCES cat_tipos_contables(codigo)
) ENGINE=InnoDB;

CREATE TABLE operaciones (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 espacio_id BIGINT UNSIGNED NOT NULL,
 moneda CHAR(3) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 creado_por BIGINT UNSIGNED NOT NULL,
 clave_idempotencia VARBINARY(64) NOT NULL,
 tipo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 fecha_efectiva DATE NOT NULL,
 concepto VARCHAR(255) NOT NULL,
 estado VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'BORRADOR',
 reversa_de BIGINT UNSIGNED NULL UNIQUE,
 creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 confirmado_en DATETIME(6) NULL,
 UNIQUE KEY uq_operacion_alcance (espacio_id,moneda,id),
 UNIQUE KEY uq_operacion_idempotente (espacio_id,clave_idempotencia),
 FOREIGN KEY (espacio_id) REFERENCES espacios(id),
 FOREIGN KEY (creado_por) REFERENCES usuarios(id),
 FOREIGN KEY (moneda) REFERENCES monedas(codigo),
 FOREIGN KEY (espacio_id,moneda,reversa_de) REFERENCES operaciones(espacio_id,moneda,id),
 INDEX ix_operacion_fecha (espacio_id,estado,fecha_efectiva),
 CONSTRAINT ck_operacion_reverso CHECK (
  (tipo='REVERSO' AND reversa_de IS NOT NULL) OR
  (tipo<>'REVERSO' AND reversa_de IS NULL)),
 CONSTRAINT ck_operacion_confirmacion CHECK (
  (estado='BORRADOR' AND confirmado_en IS NULL) OR
  (estado='CONFIRMADA' AND confirmado_en IS NOT NULL)),
 CONSTRAINT ck_operacion_clave CHECK (OCTET_LENGTH(clave_idempotencia) BETWEEN 16 AND 64),
 CONSTRAINT fk_operaciones_tipo_cat FOREIGN KEY (tipo) REFERENCES cat_tipos_operacion(codigo),
 CONSTRAINT fk_operaciones_estado_cat FOREIGN KEY (estado) REFERENCES cat_estados_operacion(codigo)
) ENGINE=InnoDB;

-- Asiento de una moneda por operación en esta fase. Debe positivo, haber negativo.
CREATE TABLE asiento_partidas (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 espacio_id BIGINT UNSIGNED NOT NULL,
 moneda CHAR(3) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 operacion_id BIGINT UNSIGNED NOT NULL,
 cuenta_contable_id BIGINT UNSIGNED NOT NULL,
 importe DECIMAL(19,4) NOT NULL,
 FOREIGN KEY (espacio_id,moneda,operacion_id) REFERENCES operaciones(espacio_id,moneda,id),
 FOREIGN KEY (espacio_id,moneda,cuenta_contable_id) REFERENCES cuentas_contables(espacio_id,moneda,id),
 INDEX ix_partida_cuenta (espacio_id,moneda,cuenta_contable_id),
 CONSTRAINT ck_partida_no_cero CHECK (importe<>0)
) ENGINE=InnoDB;

CREATE TABLE auditoria (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 espacio_id BIGINT UNSIGNED NOT NULL,
 actor_id BIGINT UNSIGNED NOT NULL,
 operacion_id BIGINT UNSIGNED NOT NULL,
 moneda CHAR(3) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 accion VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 creado_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 FOREIGN KEY (actor_id) REFERENCES usuarios(id),
 FOREIGN KEY (espacio_id,moneda,operacion_id) REFERENCES operaciones(espacio_id,moneda,id),
 CONSTRAINT fk_auditoria_accion_cat FOREIGN KEY (accion) REFERENCES cat_acciones_auditoria(codigo)
) ENGINE=InnoDB;

CREATE VIEW v_saldos_contables AS
 SELECT c.espacio_id,c.id AS cuenta_contable_id,c.moneda,c.tipo,
 COALESCE(SUM(CASE WHEN o.estado='CONFIRMADA' THEN p.importe ELSE 0 END),0) AS saldo_deudor
 FROM cuentas_contables c
 LEFT JOIN asiento_partidas p ON p.cuenta_contable_id=c.id
 LEFT JOIN operaciones o ON o.id=p.operacion_id
 GROUP BY c.espacio_id,c.id,c.moneda,c.tipo;

CREATE VIEW v_saldos_cuentas AS
 SELECT c.espacio_id,c.id AS cuenta_id,c.nombre,c.tipo,c.moneda,
 CASE WHEN c.naturaleza='PASIVO' THEN -s.saldo_deudor ELSE s.saldo_deudor END AS saldo
 FROM cuentas c JOIN v_saldos_contables s ON s.cuenta_contable_id=c.cuenta_contable_id;

-- Estas vistas NO implementan permisos por usuario. PHP debe filtrar por espacio autorizado.

CREATE VIEW v_por_cobrar AS
 SELECT c.espacio_id,c.contacto_id,p.nombre,c.moneda,s.saldo_deudor AS saldo
 FROM cuentas_por_cobrar c JOIN contactos p ON p.id=c.contacto_id
 JOIN v_saldos_contables s ON s.cuenta_contable_id=c.cuenta_contable_id;
