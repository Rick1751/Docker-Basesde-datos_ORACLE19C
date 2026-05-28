-- Apagar la restricción C##
ALTER SESSION SET "_ORACLE_SCRIPT"=true;

-- Comando de creación normal de usuarios 
-- MODIFICAR EL CAMPO PROYECTO DB
CREATE USER laboratotio_7 IDENTIFIED BY 1234;
GRANT CONNECT, RESOURCE TO laboratotio_7;
ALTER USER laboratotio_7 QUOTA UNLIMITED ON USERS;

-- GRANT CREATE SESSION TO proyecto_dbAdmin;

-- Permisos necesarios para ejecutar todo el script
GRANT CONNECT, RESOURCE TO laboratotio_7;
GRANT CREATE TABLE TO laboratotio_7;
ALTER USER laboratotio_7 QUOTA UNLIMITED ON USERS;