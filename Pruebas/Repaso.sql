SELECT c.nombres || ' ' || c.apellidos AS titular, 
       t.franquicia, t.cupo_asignado, t.saldo_utilizado,
       (t.cupo_asignado - t.saldo_utilizado) AS disponible,
       ROUND((t.saldo_utilizado / t.cupo_asignado) * 100, 2) AS porcentaje_utilizacion
FROM TARJETA_CREDITO t
JOIN PERSONA_NATURAL c ON t.id_cliente = c.id_cliente
WHERE t.estado = 'ACTIVA';