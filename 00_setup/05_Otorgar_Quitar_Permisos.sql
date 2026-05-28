-- ====================================================================
-- Guia (ORACLE 19C)
-- ====================================================================

-- 1. Conectar como administrador  (SYS)
connect sys/admin@localhost:1521/ORCL19C as sysdba;

-- 2. Conectar como usuario de desarrollo principal (ora2)
connect ora2/ora2@localhost:1521/ORCL19C;

-- 3. Conectar como usuario de pruebas (prueba1)
connect prueba1/prueba1@localhost:1521/ORCL19C;


-- ====================================================================
-- CONTROL DE PERMISOS Y PRIVILEGIOS (GRANT Y REVOKE)
-- ====================================================================

-- [1] CONECTAR COMO SYSTEM/SYS PARA DAR PERMISO DE SINÓNIMOS
connect sys/admin@localhost:1521/ORCL19C as sysdba;

-- Otorgar permiso al usuario secundario para crear sus propios sinónimos
GRANT create synonym TO prueba1;


-- [2] CONECTAR COMO DUEÑO (ORA2) PARA OTORGAR PERMISOS DE TABLA
connect ora2/ora2@localhost:1521/ORCL19C;

-- Conceder todos los permisos de edición sobre la tabla departamentos
GRANT select, insert, update, delete ON departamentos TO prueba1;


-- [3] CONECTAR COMO PRUEBA1 PARA VERIFICAR QUE LOS PERMISOS FUNCIONAN
connect prueba1/prueba1@localhost:1521/ORCL19C;

-- Probar permiso de lectura (SELECT)
SELECT * FROM ora2.departamentos;

-- Probar permiso de escritura (INSERT)
INSERT INTO departamentos VALUES (3, 'PRESUPUESTO');
COMMIT;


-- [4] CONECTAR COMO DUEÑO (ORA2) PARA QUITAR LOS PERMISOS
connect ora2/ora2@localhost:1521/ORCL19C;

-- Revocar (quitar) todos los accesos otorgados a la tabla
REVOKE select, insert, update, delete ON departamentos FROM prueba1;


-- [5] CONECTAR COMO PRUEBA1 PARA VERIFICAR QUE YA NO TIENE PERMISOS
connect prueba1/prueba1@localhost:1521/ORCL19C;

-- Esta inserción debe fallar (Dará error por falta de privilegios)
INSERT INTO departamentos VALUES (4, 'NOMINA');

