-- 1. Crear la tabla
CREATE TABLE John (
    id NUMBER PRIMARY KEY,
    nombre VARCHAR2(50),
    carrera VARCHAR2(50),
    promedio NUMBER(3,2)
);

-- 2. Insertar 4 registros
INSERT INTO John VALUES (1, 'John', 'Data Science', 9.5);
INSERT INTO estudiantes VALUES (2, 'Ana', 'IA', 9.8);
INSERT INTO estudiantes VALUES (3, 'Luis', 'Data Science', 8.5);
INSERT INTO estudiantes VALUES (4, 'Sofia', 'IA', 9.2);

-- 3. Confirmar los cambios
COMMIT;

SELECT * FROM John;
