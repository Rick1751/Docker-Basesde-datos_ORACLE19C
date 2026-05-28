/*==============================================================*/
/* DBMS name:      ORACLE Version 19c                           */
/*==============================================================*/
BEGIN
   FOR c IN (
      SELECT table_name
      FROM user_tables
   ) LOOP
      EXECUTE IMMEDIATE 'DROP TABLE "' || c.table_name || '" CASCADE CONSTRAINTS';
   END LOOP;
END;
/
/*==============================================================*/
/* Table: USUARIO_SISTEMA                                       */
/*==============================================================*/
CREATE TABLE USUARIO_SISTEMA (
   id_usuario           NUMBER NOT NULL,
   nombre_usuario       VARCHAR2(50) NOT NULL,
   rol                  VARCHAR2(20) NOT NULL,
   intentos_fallidos    NUMBER DEFAULT 0 NOT NULL,
   fecha_desbloqueo     TIMESTAMP,
   CONSTRAINT PK_USUARIO_SISTEMA PRIMARY KEY (id_usuario),
   CONSTRAINT ak_usuario_nombre UNIQUE (nombre_usuario)
);

/*==============================================================*/
/* Table: CLIENTE                                               */
/*==============================================================*/
CREATE TABLE CLIENTE (
   id_cliente           NUMBER NOT NULL,
   tipo_cliente         VARCHAR2(20) NOT NULL,
   nivel_riesgo         VARCHAR2(10) NOT NULL,
   scoring_crediticio   NUMBER NOT NULL,

   CONSTRAINT PK_CLIENTE PRIMARY KEY (id_cliente),

   CONSTRAINT Rule_1 CHECK (
      tipo_cliente IN ('PERSONA_NATURAL', 'PERSONA_JURIDICA')
   ),

   CONSTRAINT Rule_2 CHECK (
      nivel_riesgo IN ('BAJO', 'MEDIO', 'ALTO')
   )
);

/*==============================================================*/
/* Table: PERSONA_NATURAL                                       */
/*==============================================================*/
CREATE TABLE PERSONA_NATURAL (
   id_cliente           NUMBER NOT NULL,
   cedula_pasaporte     VARCHAR2(20) NOT NULL,
   nombres              VARCHAR2(100) NOT NULL,
   apellidos            VARCHAR2(100) NOT NULL,
   fecha_nacimiento     DATE NOT NULL,
   genero               VARCHAR2(20) NOT NULL,
   estado_civil         VARCHAR2(20) NOT NULL,
   nacionalidad         VARCHAR2(50) NOT NULL,

   CONSTRAINT PK_PERSONA_NATURAL PRIMARY KEY (id_cliente),

   CONSTRAINT ak_pers_nat_cedula UNIQUE (cedula_pasaporte),

   CONSTRAINT Rule_3 CHECK (
      estado_civil IN (
         'SOLTERO',
         'CASADO',
         'DIVORCIADO',
         'VIUDO',
         'UNION_LIBRE'
      )
   )
);

/*==============================================================*/
/* Table: PERSONA_JURIDICA                                      */
/*==============================================================*/
CREATE TABLE PERSONA_JURIDICA (
   id_cliente                 NUMBER NOT NULL,
   id_representante_legal     NUMBER NOT NULL,
   ruc                        VARCHAR2(13) NOT NULL,
   razon_social               VARCHAR2(150) NOT NULL,
   nombre_comercial           VARCHAR2(150) NOT NULL,
   fecha_constitucion         DATE NOT NULL,
   tipo_sociedad              VARCHAR2(50) NOT NULL,

   CONSTRAINT PK_PERSONA_JURIDICA PRIMARY KEY (id_cliente),

   CONSTRAINT ak_pers_jur_ruc UNIQUE (ruc)
);

/*==============================================================*/
/* Table: SUCURSAL                                              */
/*==============================================================*/
CREATE TABLE SUCURSAL (
   id_sucursal          NUMBER NOT NULL,
   nombre               VARCHAR2(150) NOT NULL,
   direccion            VARCHAR2(255) NOT NULL,
   ciudad               VARCHAR2(100) NOT NULL,

   CONSTRAINT PK_SUCURSAL PRIMARY KEY (id_sucursal)
);

/*==============================================================*/
/* Table: CUENTA_BANCARIA                                       */
/*==============================================================*/
CREATE TABLE CUENTA_BANCARIA (
   numero_cuenta        VARCHAR2(10) NOT NULL,
   tipo_cuenta          VARCHAR2(20) NOT NULL,
   modalidad            VARCHAR2(20) NOT NULL,
   tipo_firma           VARCHAR2(20),
   estado               VARCHAR2(20) DEFAULT 'ACTIVA' NOT NULL,
   fecha_apertura       DATE NOT NULL,
   saldo                NUMBER(12,2) NOT NULL,

   CONSTRAINT PK_CUENTA_BANCARIA PRIMARY KEY (numero_cuenta),

   CONSTRAINT Rule_4 CHECK (
      modalidad IN ('INDIVIDUAL', 'MANCOMUNADA')
   ),

   CONSTRAINT Rule_5 CHECK (
      tipo_firma IN ('CONJUNTA', 'INDISTINTA')
      OR tipo_firma IS NULL
   ),

   CONSTRAINT Rule_6 CHECK (
      estado IN ('ACTIVA', 'BLOQUEADA', 'CERRADA')
   )
);

/*==============================================================*/
/* Table: CUENTA_AHORRO                                         */
/*==============================================================*/
CREATE TABLE CUENTA_AHORRO (
   numero_cuenta            VARCHAR2(10) NOT NULL,
   tasa_interes_mensual     NUMBER(5,2) DEFAULT 0.5 NOT NULL,

   CONSTRAINT PK_CUENTA_AHORRO PRIMARY KEY (numero_cuenta)
);

/*==============================================================*/
/* Table: CUENTA_CORRIENTE                                      */
/*==============================================================*/
CREATE TABLE CUENTA_CORRIENTE (
   numero_cuenta               VARCHAR2(10) NOT NULL,
   limite_sobregiro            NUMBER(12,2) DEFAULT 0 NOT NULL,
   tasa_interes_sobregiro      NUMBER(5,2) DEFAULT 18 NOT NULL,

   CONSTRAINT PK_CUENTA_CORRIENTE PRIMARY KEY (numero_cuenta)
);

/*==============================================================*/
/* Table: TITULAR_CUENTA                                        */
/*==============================================================*/
CREATE TABLE TITULAR_CUENTA (
   id_cliente           NUMBER NOT NULL,
   numero_cuenta        VARCHAR2(10) NOT NULL,

   CONSTRAINT PK_TITULAR_CUENTA
      PRIMARY KEY (id_cliente, numero_cuenta)
);

/*==============================================================*/
/* Table: BENEFICIARIO_CUENTA                                   */
/*==============================================================*/
CREATE TABLE BENEFICIARIO_CUENTA (
   id_beneficiario      NUMBER NOT NULL,
   numero_cuenta        VARCHAR2(10) NOT NULL,
   nombres              VARCHAR2(150) NOT NULL,
   parentesco           VARCHAR2(50) NOT NULL,
   porcentaje_asignado  NUMBER NOT NULL,

   CONSTRAINT PK_BENEFICIARIO_CUENTA
      PRIMARY KEY (id_beneficiario)
);

/*==============================================================*/
/* Table: TARJETA_CREDITO                                       */
/*==============================================================*/
CREATE TABLE TARJETA_CREDITO (
   id_tarjeta             NUMBER NOT NULL,
   numero_tarjeta         VARCHAR2(16) NOT NULL,
   cvv                    VARCHAR2(4) NOT NULL,
   cupo_asignado          NUMBER(12,2) NOT NULL,
   franquicia             VARCHAR2(20) NOT NULL,
   fecha_vencimiento      DATE NOT NULL,
   fecha_emision          DATE NOT NULL,
   saldo_utilizado        NUMBER(12,2) DEFAULT 0 NOT NULL,
   fecha_corte            NUMBER NOT NULL,
   fecha_pago             NUMBER NOT NULL,
   tasa_interes_anual     NUMBER(5,2) DEFAULT 24 NOT NULL,
   estado                 VARCHAR2(20) NOT NULL,
   pago_minimo            NUMBER(12,2) NOT NULL,
   id_cliente             NUMBER NOT NULL,
   TAR_id_tarjeta         NUMBER,

   CONSTRAINT PK_TARJETA_CREDITO PRIMARY KEY (id_tarjeta),

   CONSTRAINT ak_tarjeta_numero UNIQUE (numero_tarjeta),

   CONSTRAINT Rule_7 CHECK (tasa_interes_anual = 24),

   CONSTRAINT Rule_8 CHECK (
      fecha_corte BETWEEN 1 AND 31
   ),

   CONSTRAINT Rule_9 CHECK (
      fecha_pago BETWEEN 1 AND 31
   ),

   CONSTRAINT Rule_10 CHECK (
      estado IN (
         'ACTIVA',
         'BLOQUEADA',
         'VENCIDA',
         'CANCELADA'
      )
   ),

   CONSTRAINT Rule_11 CHECK (
      franquicia IN (
         'VISA',
         'MASTERCARD',
         'AMEX'
      )
   )
);

/*==============================================================*/
/* Table: COMPRA_TARJETA                                        */
/*==============================================================*/
CREATE TABLE COMPRA_TARJETA (
   id_compra           NUMBER NOT NULL,
   monto               NUMBER(12,2) NOT NULL,
   fecha               DATE NOT NULL,
   descripcion         VARCHAR2(255) NOT NULL,
   id_tarjeta          NUMBER NOT NULL,

   CONSTRAINT PK_COMPRA_TARJETA PRIMARY KEY (id_compra)
);

/*==============================================================*/
/* Table: PRESTAMO                                              */
/*==============================================================*/
CREATE TABLE PRESTAMO (
   id_prestamo             NUMBER NOT NULL,
   id_cliente              NUMBER NOT NULL,
   tipo_prestamo           VARCHAR2(50) NOT NULL,
   monto                   NUMBER(12,2) NOT NULL,
   plazo                   NUMBER NOT NULL,
   tasa                    NUMBER(5,2) NOT NULL,
   garantias               VARCHAR2(500) NOT NULL,
   estado                  VARCHAR2(20) NOT NULL,
   sistema_amortizacion    VARCHAR2(50) NOT NULL,

   CONSTRAINT PK_PRESTAMO PRIMARY KEY (id_prestamo),

   CONSTRAINT Rule_12 CHECK (
      plazo BETWEEN 12 AND 60
   ),

   CONSTRAINT Rule_13 CHECK (
      estado IN (
         'SOLICITADO',
         'EN_ANALISIS',
         'APROBADO',
         'RECHAZADO',
         'DESEMBOLSADO',
         'CANCELADO'
      )
   )
);

/*==============================================================*/
/* Table: CUOTA_PRESTAMO                                        */
/*==============================================================*/
CREATE TABLE CUOTA_PRESTAMO (
   id_cuota              NUMBER NOT NULL,
   id_prestamo           NUMBER NOT NULL,
   numero_cuota          NUMBER NOT NULL,
   monto                 NUMBER(12,2) NOT NULL,
   fecha_vencimiento     DATE NOT NULL,

   CONSTRAINT PK_CUOTA_PRESTAMO PRIMARY KEY (id_cuota)
);

/*==============================================================*/
/* Table: PAGO_PRESTAMO                                         */
/*==============================================================*/
CREATE TABLE PAGO_PRESTAMO (
   id_pago             NUMBER NOT NULL,
   id_cuota            NUMBER NOT NULL,
   monto               NUMBER(12,2) NOT NULL,
   fecha_pago          DATE NOT NULL,
   recargo_mora        NUMBER(12,2) NOT NULL,

   CONSTRAINT PK_PAGO_PRESTAMO PRIMARY KEY (id_pago)
);

/*==============================================================*/
/* Table: INVERSION                                             */
/*==============================================================*/
CREATE TABLE INVERSION (
   id_inversion             NUMBER NOT NULL,
   id_cliente               NUMBER NOT NULL,
   tipo_inversion           VARCHAR2(20) NOT NULL,
   plazo_dias               NUMBER NOT NULL,
   tasa_interes             NUMBER(5,2) NOT NULL,
   monto                    NUMBER(12,2) NOT NULL,
   fecha_inicio             DATE NOT NULL,
   fecha_vencimiento        DATE NOT NULL,
   estado                   VARCHAR2(20) NOT NULL,
   opcion_vencimiento       VARCHAR2(20) NOT NULL,
   fecha_cancelacion        DATE,
   cancelacion_anticipada   VARCHAR2(2) NOT NULL,
   penalizacion_interes     NUMBER NOT NULL,

   CONSTRAINT PK_INVERSION PRIMARY KEY (id_inversion),

   CONSTRAINT Rule_20 CHECK (monto >= 1000),

   CONSTRAINT Rule_21 CHECK (
      plazo_dias IN (30,60,90,180,360)
   ),

   CONSTRAINT Rule_22 CHECK (
      tasa_interes BETWEEN 4 AND 7
   ),

   CONSTRAINT Rule_23 CHECK (
      estado IN (
         'ACTIVA',
         'VENCIDA',
         'RENOVADA',
         'CANCELADA'
      )
   ),

   CONSTRAINT Rule_24 CHECK (
      opcion_vencimiento IN (
         'RENOVAR',
         'LIQUIDAR'
      )
   ),

   CONSTRAINT Rule_25 CHECK (
      cancelacion_anticipada IN ('SI','NO')
   ),

   CONSTRAINT Rule_26 CHECK (
      penalizacion_interes = 50
   )
);

/*==============================================================*/
/* Table: TRANSACCION                                           */
/*==============================================================*/
CREATE TABLE TRANSACCION (
   id_transaccion       NUMBER NOT NULL,
   numero_cuenta        VARCHAR2(10) NOT NULL,
   cuenta_destino       VARCHAR2(10),
   naturaleza           VARCHAR2(10) NOT NULL,
   tipo_transaccion     VARCHAR2(20) NOT NULL,
   monto                NUMBER(12,2) NOT NULL,
   fecha_hora           DATE NOT NULL,
   canal                VARCHAR2(20) NOT NULL,
   id_sucursal          NUMBER NOT NULL,
   id_usuario           NUMBER NOT NULL,
   forma_pago           VARCHAR2(20) NOT NULL,
   estado               VARCHAR2(20) NOT NULL,
   token_validado       NUMBER(1) DEFAULT 0 NOT NULL,

   CONSTRAINT PK_TRANSACCION PRIMARY KEY (id_transaccion),

   CONSTRAINT Rule_14 CHECK (
      tipo_transaccion IN (
         'DEPOSITO',
         'RETIRO',
         'TRANSFERENCIA',
         'PAGO',
         'COMPRA',
         'AJUSTE'
      )
   ),

   CONSTRAINT Rule_15 CHECK (
      canal IN (
         'VENTANILLA',
         'ATM',
         'WEB',
         'MOVIL'
      )
   ),

   CONSTRAINT Rule_16 CHECK (
      forma_pago IN (
         'EFECTIVO',
         'CHEQUE'
      )
   ),

   CONSTRAINT Rule_17 CHECK (
      estado IN (
         'EFECTIVIZADO',
         'PENDIENTE',
         'APROBADA'
      )
   ),

   CONSTRAINT Rule_18 CHECK (monto > 0),

   CONSTRAINT Rule_19 CHECK (
      token_validado IN (0,1)
   )
);

/*==============================================================*/
/* Table: ACCESO_SISTEMA                                        */
/*==============================================================*/
CREATE TABLE ACCESO_SISTEMA (
   id_acceso            NUMBER NOT NULL,
   fecha_hora           TIMESTAMP NOT NULL,
   intento              NUMBER NOT NULL,
   id_usuario           NUMBER NOT NULL,
   direccion_ip         VARCHAR2(45) NOT NULL,
   resultados           VARCHAR2(10) NOT NULL,

   CONSTRAINT PK_ACCESO_SISTEMA PRIMARY KEY (id_acceso)
);

/*==============================================================*/
/* Table: BITACORA_OPERACIONES                                  */
/*==============================================================*/
CREATE TABLE BITACORA_OPERACIONES (
   id_bitacora          NUMBER NOT NULL,
   id_usuario           NUMBER NOT NULL,
   fecha_hora           TIMESTAMP NOT NULL,
   operacion            VARCHAR2(10) NOT NULL,
   nombre_tabla         VARCHAR2(50) NOT NULL,

   CONSTRAINT PK_BITACORA_OPERACIONES
      PRIMARY KEY (id_bitacora)
);

/*==============================================================*/
/* Table: TELEFONO_CLIENTE                                      */
/*==============================================================*/
CREATE TABLE TELEFONO_CLIENTE (
   id_telefono          NUMBER NOT NULL,
   id_cliente           NUMBER NOT NULL,
   tipo_telefono        VARCHAR2(20) NOT NULL,
   numero               VARCHAR2(20) NOT NULL,

   CONSTRAINT PK_TELEFONO_CLIENTE
      PRIMARY KEY (id_telefono)
);

/*==============================================================*/
/* Table: CORREO_CLIENTE                                        */
/*==============================================================*/
CREATE TABLE CORREO_CLIENTE (
   id_correo            NUMBER NOT NULL,
   id_cliente           NUMBER NOT NULL,
   email                VARCHAR2(100) NOT NULL,

   CONSTRAINT PK_CORREO_CLIENTE PRIMARY KEY (id_correo)
);

/*==============================================================*/
/* Table: DIRECCION_CLIENTE                                     */
/*==============================================================*/
CREATE TABLE DIRECCION_CLIENTE (
   id_direccion         NUMBER NOT NULL,
   id_cliente           NUMBER NOT NULL,
   tipo_direccion       VARCHAR2(20) NOT NULL,
   direccion_comp       VARCHAR2(255) NOT NULL,

   CONSTRAINT PK_DIRECCION_CLIENTE
      PRIMARY KEY (id_direccion)
);

/*==============================================================*/
/* Table: ACCIONISTA_EMPRESA                                    */
/*==============================================================*/
CREATE TABLE ACCIONISTA_EMPRESA (
   PER_id_cliente         NUMBER NOT NULL,
   id_cliente             NUMBER NOT NULL,
   id_accionista          NUMBER NOT NULL,
   porcentaje_acciones    NUMBER NOT NULL,

   CONSTRAINT PK_ACCIONISTA_EMPRESA
      PRIMARY KEY (PER_id_cliente, id_cliente)
);

/*==============================================================*/
/* FOREIGN KEYS                                                 */
/*==============================================================*/

ALTER TABLE PERSONA_NATURAL
ADD CONSTRAINT fk_PERSONA_NATURAL_id_cliente
FOREIGN KEY (id_cliente)
REFERENCES CLIENTE(id_cliente);

ALTER TABLE PERSONA_JURIDICA
ADD CONSTRAINT fk_PERSONA_JURIDICA_id_cliente
FOREIGN KEY (id_cliente)
REFERENCES CLIENTE(id_cliente);

ALTER TABLE PERSONA_JURIDICA
ADD CONSTRAINT fk_PERSONA_JURIDICA_rep_legal
FOREIGN KEY (id_representante_legal)
REFERENCES PERSONA_NATURAL(id_cliente);

ALTER TABLE CUENTA_AHORRO
ADD CONSTRAINT fk_CUENTA_AHORRO_num_cta
FOREIGN KEY (numero_cuenta)
REFERENCES CUENTA_BANCARIA(numero_cuenta);

ALTER TABLE CUENTA_CORRIENTE
ADD CONSTRAINT fk_CUENTA_CORRIENTE_num_cta
FOREIGN KEY (numero_cuenta)
REFERENCES CUENTA_BANCARIA(numero_cuenta);

ALTER TABLE TITULAR_CUENTA
ADD CONSTRAINT fk_TITULAR_CUENTA_id_cliente
FOREIGN KEY (id_cliente)
REFERENCES CLIENTE(id_cliente);

ALTER TABLE TITULAR_CUENTA
ADD CONSTRAINT fk_TITULAR_CUENTA_num_cta
FOREIGN KEY (numero_cuenta)
REFERENCES CUENTA_BANCARIA(numero_cuenta);

ALTER TABLE BENEFICIARIO_CUENTA
ADD CONSTRAINT fk_BENEFICIARIO_CUENTA_num_cta
FOREIGN KEY (numero_cuenta)
REFERENCES CUENTA_BANCARIA(numero_cuenta);

ALTER TABLE TARJETA_CREDITO
ADD CONSTRAINT fk_TARJETA_CREDITO_id_cliente
FOREIGN KEY (id_cliente)
REFERENCES CLIENTE(id_cliente);

ALTER TABLE TARJETA_CREDITO
ADD CONSTRAINT fk_TARJETA_CREDITO_principal
FOREIGN KEY (TAR_id_tarjeta)
REFERENCES TARJETA_CREDITO(id_tarjeta);

ALTER TABLE COMPRA_TARJETA
ADD CONSTRAINT fk_COMPRA_TARJETA_id_tarjeta
FOREIGN KEY (id_tarjeta)
REFERENCES TARJETA_CREDITO(id_tarjeta);

ALTER TABLE PRESTAMO
ADD CONSTRAINT fk_PRESTAMO_id_cliente
FOREIGN KEY (id_cliente)
REFERENCES CLIENTE(id_cliente);

ALTER TABLE CUOTA_PRESTAMO
ADD CONSTRAINT fk_CUOTA_PRESTAMO_id_prestamo
FOREIGN KEY (id_prestamo)
REFERENCES PRESTAMO(id_prestamo);

ALTER TABLE PAGO_PRESTAMO
ADD CONSTRAINT fk_PAGO_PRESTAMO_id_cuota
FOREIGN KEY (id_cuota)
REFERENCES CUOTA_PRESTAMO(id_cuota);

ALTER TABLE INVERSION
ADD CONSTRAINT fk_INVERSION_id_cliente
FOREIGN KEY (id_cliente)
REFERENCES CLIENTE(id_cliente);

ALTER TABLE TRANSACCION
ADD CONSTRAINT fk_TRANSACCION_cuenta_origen
FOREIGN KEY (numero_cuenta)
REFERENCES CUENTA_BANCARIA(numero_cuenta);

ALTER TABLE TRANSACCION
ADD CONSTRAINT fk_TRANSACCION_id_sucursal
FOREIGN KEY (id_sucursal)
REFERENCES SUCURSAL(id_sucursal);

ALTER TABLE TRANSACCION
ADD CONSTRAINT fk_TRANSACCION_id_usuario
FOREIGN KEY (id_usuario)
REFERENCES USUARIO_SISTEMA(id_usuario);

ALTER TABLE ACCESO_SISTEMA
ADD CONSTRAINT fk_ACCESO_SISTEMA_id_usuario
FOREIGN KEY (id_usuario)
REFERENCES USUARIO_SISTEMA(id_usuario);

ALTER TABLE BITACORA_OPERACIONES
ADD CONSTRAINT fk_BITACORA_OPER_id_usuario
FOREIGN KEY (id_usuario)
REFERENCES USUARIO_SISTEMA(id_usuario);

ALTER TABLE TELEFONO_CLIENTE
ADD CONSTRAINT fk_TELEFONO_CLIENTE_id_cliente
FOREIGN KEY (id_cliente)
REFERENCES CLIENTE(id_cliente);

ALTER TABLE CORREO_CLIENTE
ADD CONSTRAINT fk_CORREO_CLIENTE_id_cliente
FOREIGN KEY (id_cliente)
REFERENCES CLIENTE(id_cliente);

ALTER TABLE DIRECCION_CLIENTE
ADD CONSTRAINT fk_DIR_CLIENTE_id
FOREIGN KEY (id_cliente)
REFERENCES CLIENTE(id_cliente);

ALTER TABLE ACCIONISTA_EMPRESA
ADD CONSTRAINT fk_ACCIONISTA_EMPRESA_cliente
FOREIGN KEY (id_cliente)
REFERENCES CLIENTE(id_cliente);

ALTER TABLE ACCIONISTA_EMPRESA
ADD CONSTRAINT fk_ACCIONISTA_EMPRESA_empresa
FOREIGN KEY (PER_id_cliente)
REFERENCES PERSONA_JURIDICA(id_cliente);