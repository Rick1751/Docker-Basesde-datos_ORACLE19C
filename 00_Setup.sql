-- Apagar la restricción C##
ALTER SESSION SET "_ORACLE_SCRIPT"=true;

-- Comando de creación normal de usuarios 
-- MODIFICAR EL CAMPO PROYECTO DB
CREATE USER proyecto_dbAdmin IDENTIFIED BY 1234;
GRANT CONNECT, RESOURCE TO proyecto_db;
ALTER USER proyecto_db QUOTA UNLIMITED ON USERS;

-- GRANT CREATE SESSION TO proyecto_dbAdmin;

-- Permisos necesarios para ejecutar todo el script
GRANT CONNECT, RESOURCE TO proyecto_dbAdmin;
GRANT CREATE TABLE TO proyecto_dbAdmin;
ALTER USER proyecto_dbAdmin QUOTA UNLIMITED ON USERS;