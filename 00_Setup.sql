-- Apagar la restricción C##
ALTER SESSION SET "_ORACLE_SCRIPT"=true;

-- Comando de creación normal de usuarios 
-- MODIFICAR EL CAMPO PROYECTO DB
CREATE USER proyecto_db IDENTIFIED BY 1234;
GRANT CONNECT, RESOURCE TO proyecto_db;
ALTER USER proyecto_db QUOTA UNLIMITED ON USERS;