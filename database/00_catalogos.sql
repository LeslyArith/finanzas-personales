-- Catálogos. Ejecutar una sola vez antes del esquema inicial o de la migración v1.
SET NAMES utf8mb4;

CREATE TABLE cat_estados_usuario (
 codigo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 es_sistema BOOLEAN NOT NULL DEFAULT FALSE,
 orden SMALLINT UNSIGNED NOT NULL DEFAULT 0,
 permite_acceso BOOLEAN NOT NULL DEFAULT FALSE,
 CONSTRAINT ck_cat_estados_usuario_nombre CHECK (CHAR_LENGTH(TRIM(nombre))>0)
) ENGINE=InnoDB;
INSERT INTO cat_estados_usuario(codigo,nombre,es_sistema,orden,permite_acceso) VALUES
 ('ACTIVO','Activo',TRUE,10,TRUE),
 ('BLOQUEADO','Bloqueado',TRUE,20,FALSE),
 ('INACTIVO','Inactivo',TRUE,30,FALSE);

CREATE TABLE cat_tipos_token (
 codigo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 es_sistema BOOLEAN NOT NULL DEFAULT FALSE,
 orden SMALLINT UNSIGNED NOT NULL DEFAULT 0,
 
 CONSTRAINT ck_cat_tipos_token_nombre CHECK (CHAR_LENGTH(TRIM(nombre))>0)
) ENGINE=InnoDB;
INSERT INTO cat_tipos_token(codigo,nombre,es_sistema,orden) VALUES
 ('INVITACION','Invitación',TRUE,10),
 ('RECUPERACION','Recuperación',TRUE,20);

CREATE TABLE cat_tipos_espacio (
 codigo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 es_sistema BOOLEAN NOT NULL DEFAULT FALSE,
 orden SMALLINT UNSIGNED NOT NULL DEFAULT 0,
 
 CONSTRAINT ck_cat_tipos_espacio_nombre CHECK (CHAR_LENGTH(TRIM(nombre))>0)
) ENGINE=InnoDB;
INSERT INTO cat_tipos_espacio(codigo,nombre,es_sistema,orden) VALUES
 ('PERSONAL','Personal',TRUE,10),
 ('GRUPO','Grupo',TRUE,20);

CREATE TABLE cat_roles_espacio (
 codigo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 es_sistema BOOLEAN NOT NULL DEFAULT FALSE,
 orden SMALLINT UNSIGNED NOT NULL DEFAULT 0,
 puede_registrar BOOLEAN NOT NULL DEFAULT FALSE,
 puede_reversar BOOLEAN NOT NULL DEFAULT FALSE,
 CONSTRAINT ck_cat_roles_espacio_nombre CHECK (CHAR_LENGTH(TRIM(nombre))>0)
) ENGINE=InnoDB;
INSERT INTO cat_roles_espacio(codigo,nombre,es_sistema,orden,puede_registrar,puede_reversar) VALUES
 ('ADMIN','Administrador',TRUE,10,TRUE,TRUE),
 ('INTEGRANTE','Integrante',TRUE,20,TRUE,FALSE),
 ('CONSULTA','Solo consulta',TRUE,30,FALSE,FALSE);

CREATE TABLE cat_tipos_contables (
 codigo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 es_sistema BOOLEAN NOT NULL DEFAULT FALSE,
 orden SMALLINT UNSIGNED NOT NULL DEFAULT 0,
 
 CONSTRAINT ck_cat_tipos_contables_nombre CHECK (CHAR_LENGTH(TRIM(nombre))>0)
) ENGINE=InnoDB;
INSERT INTO cat_tipos_contables(codigo,nombre,es_sistema,orden) VALUES
 ('ACTIVO','Activo',TRUE,10),
 ('PASIVO','Pasivo',TRUE,20),
 ('INGRESO','Ingreso',TRUE,30),
 ('GASTO','Gasto',TRUE,40),
 ('PATRIMONIO','Patrimonio',TRUE,50);

CREATE TABLE cat_tipos_cuenta (
 codigo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 es_sistema BOOLEAN NOT NULL DEFAULT FALSE,
 orden SMALLINT UNSIGNED NOT NULL DEFAULT 0,
 naturaleza VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 UNIQUE KEY uq_tipo_cuenta_naturaleza (codigo,naturaleza),
 FOREIGN KEY (naturaleza) REFERENCES cat_tipos_contables(codigo),
 CONSTRAINT ck_cat_tipos_cuenta_nombre CHECK (CHAR_LENGTH(TRIM(nombre))>0)
) ENGINE=InnoDB;
INSERT INTO cat_tipos_cuenta(codigo,nombre,es_sistema,orden,naturaleza) VALUES
 ('EFECTIVO','Efectivo',TRUE,10,'ACTIVO'),
 ('DEBITO','Cuenta bancaria o débito',TRUE,20,'ACTIVO'),
 ('AHORRO','Ahorro',TRUE,30,'ACTIVO'),
 ('CREDITO','Crédito',TRUE,40,'PASIVO');

CREATE TABLE cat_tipos_operacion (
 codigo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 es_sistema BOOLEAN NOT NULL DEFAULT FALSE,
 orden SMALLINT UNSIGNED NOT NULL DEFAULT 0,
 
 CONSTRAINT ck_cat_tipos_operacion_nombre CHECK (CHAR_LENGTH(TRIM(nombre))>0)
) ENGINE=InnoDB;
INSERT INTO cat_tipos_operacion(codigo,nombre,es_sistema,orden) VALUES
 ('APERTURA','Apertura',TRUE,10),
 ('INGRESO','Ingreso',TRUE,20),
 ('GASTO','Gasto',TRUE,30),
 ('TRANSFERENCIA','Transferencia',TRUE,40),
 ('PAGO_TARJETA','Pago de tarjeta',TRUE,50),
 ('COMPRA_TERCERO','Compra por cuenta de otra persona',TRUE,60),
 ('COBRO_TERCERO','Cobro a otra persona',TRUE,70),
 ('REVERSO','Reverso',TRUE,80);

CREATE TABLE cat_estados_operacion (
 codigo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 es_sistema BOOLEAN NOT NULL DEFAULT FALSE,
 orden SMALLINT UNSIGNED NOT NULL DEFAULT 0,
 
 CONSTRAINT ck_cat_estados_operacion_nombre CHECK (CHAR_LENGTH(TRIM(nombre))>0)
) ENGINE=InnoDB;
INSERT INTO cat_estados_operacion(codigo,nombre,es_sistema,orden) VALUES
 ('BORRADOR','Borrador',TRUE,10),
 ('CONFIRMADA','Confirmada',TRUE,20);

CREATE TABLE cat_acciones_auditoria (
 codigo VARCHAR(30) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 es_sistema BOOLEAN NOT NULL DEFAULT FALSE,
 orden SMALLINT UNSIGNED NOT NULL DEFAULT 0,
 
 CONSTRAINT ck_cat_acciones_auditoria_nombre CHECK (CHAR_LENGTH(TRIM(nombre))>0)
) ENGINE=InnoDB;
INSERT INTO cat_acciones_auditoria(codigo,nombre,es_sistema,orden) VALUES
 ('CONFIRMAR','Confirmar',TRUE,10),
 ('REVERSAR','Reversar',TRUE,20);

