-- ============================================================================
-- BANCOSEGURO S.A. - SCRIPTS DE EXTRACCIÓN CONSOLIDADA (Q1 - Q15)
-- Motor: Oracle 19c Enterprise Edition
-- ============================================================================


-- ============================================================================
-- Q1: Listar cuentas MANCOMUNADAS con número, tipo, saldo, cotitulares,
-- fecha apertura
-- ============================================================================

SELECT 
    cb.numero_cuenta,
    cb.tipo_cuenta,
    cb.saldo,
    cb.fecha_apertura,
    (
        SELECT COUNT(*)
        FROM TITULAR_CUENTA tc
        WHERE tc.numero_cuenta = cb.numero_cuenta
    ) AS cantidad_cotitulares
FROM CUENTA_BANCARIA cb
WHERE cb.modalidad = 'MANCOMUNADA';


-- ============================================================================
-- Q2: Mostrar tarjetas ACTIVAS con titular, franquicia, cupo,
-- saldo utilizado, disponible, % utilización
-- ============================================================================

SELECT 
    tc.numero_tarjeta,
    pn.nombres || ' ' || pn.apellidos AS titular,
    tc.franquicia,
    tc.cupo_asignado AS cupo,
    tc.saldo_utilizado,
    (tc.cupo_asignado - tc.saldo_utilizado) AS saldo_disponible,
    ROUND((tc.saldo_utilizado / tc.cupo_asignado) * 100, 2) AS porcentaje_utilizacion
FROM TARJETA_CREDITO tc
JOIN PERSONA_NATURAL pn 
    ON tc.id_cliente = pn.id_cliente
WHERE tc.estado = 'ACTIVA';


-- ============================================================================
-- Q3: Listar préstamos DESEMBOLSADOS con cliente, tipo, monto,
-- plazo, tasa, fecha, saldo pendiente
-- ============================================================================

SELECT 
    p.id_prestamo,
    pn.nombres || ' ' || pn.apellidos AS cliente,
    p.tipo_prestamo,
    p.monto AS monto_original,
    p.plazo,
    p.tasa,

    (
        SELECT MIN(cp.fecha_vencimiento)
        FROM CUOTA_PRESTAMO cp
        WHERE cp.id_prestamo = p.id_prestamo
    ) AS fecha_colocacion_estimada,

    (
        p.monto -
        NVL(
            (
                SELECT SUM(pp.monto)
                FROM PAGO_PRESTAMO pp
                JOIN CUOTA_PRESTAMO cp
                    ON pp.id_cuota = cp.id_cuota
                WHERE cp.id_prestamo = p.id_prestamo
            ),
            0
        )
    ) AS saldo_pendiente

FROM PRESTAMO p
JOIN PERSONA_NATURAL pn
    ON p.id_cliente = pn.id_cliente
WHERE p.estado = 'DESEMBOLSADO';


-- ============================================================================
-- Q4: Clientes con al menos un producto de cada tipo
-- (cuenta, tarjeta y préstamo)
-- ============================================================================

SELECT 
    c.id_cliente,
    pn.nombres || ' ' || pn.apellidos AS cliente
FROM CLIENTE c
JOIN PERSONA_NATURAL pn
    ON c.id_cliente = pn.id_cliente
WHERE EXISTS (
        SELECT 1
        FROM TITULAR_CUENTA tc
        WHERE tc.id_cliente = c.id_cliente
      )
  AND EXISTS (
        SELECT 1
        FROM TARJETA_CREDITO t
        WHERE t.id_cliente = c.id_cliente
      )
  AND EXISTS (
        SELECT 1
        FROM PRESTAMO p
        WHERE p.id_cliente = c.id_cliente
      );


-- ============================================================================
-- Q5: Top 10 cuentas con mayor movimiento transaccional último mes
-- ============================================================================

SELECT *
FROM (
    SELECT 
        t.numero_cuenta,
        cb.tipo_cuenta,
        COUNT(t.id_transaccion) AS total_transacciones,
        SUM(t.monto) AS volumen_monetario_total
    FROM TRANSACCION t
    JOIN CUENTA_BANCARIA cb
        ON t.numero_cuenta = cb.numero_cuenta
    WHERE t.fecha_hora >= ADD_MONTHS(SYSDATE, -1)
    GROUP BY t.numero_cuenta, cb.tipo_cuenta
    ORDER BY total_transacciones DESC
)
WHERE ROWNUM <= 10;


-- ============================================================================
-- Q6: Préstamos con cuotas vencidas con días de mora
-- ============================================================================

SELECT 
    p.id_prestamo,
    pn.nombres || ' ' || pn.apellidos AS cliente,
    cp.numero_cuota,
    cp.monto AS monto_cuota,
    cp.fecha_vencimiento,
    ROUND(TRUNC(SYSDATE) - cp.fecha_vencimiento) AS dias_mora

FROM CUOTA_PRESTAMO cp

JOIN PRESTAMO p
    ON cp.id_prestamo = p.id_prestamo

JOIN PERSONA_NATURAL pn
    ON p.id_cliente = pn.id_cliente

WHERE cp.fecha_vencimiento < TRUNC(SYSDATE)

AND NOT EXISTS (
    SELECT 1
    FROM PAGO_PRESTAMO pp
    WHERE pp.id_cuota = cp.id_cuota
)

ORDER BY dias_mora DESC;


-- ============================================================================
-- Q7: Clientes scoring < promedio con tarjetas > 80% utilización
-- ============================================================================

SELECT 
    c.id_cliente,
    pn.nombres || ' ' || pn.apellidos AS cliente,
    c.scoring_crediticio,
    tc.numero_tarjeta,

    ROUND(
        (tc.saldo_utilizado / tc.cupo_asignado) * 100,
        2
    ) AS porcentaje_utilizacion

FROM CLIENTE c

JOIN PERSONA_NATURAL pn
    ON c.id_cliente = pn.id_cliente

JOIN TARJETA_CREDITO tc
    ON c.id_cliente = tc.id_cliente

WHERE c.scoring_crediticio < (
        SELECT AVG(scoring_crediticio)
        FROM CLIENTE
      )

AND (tc.saldo_utilizado / tc.cupo_asignado) > 0.80;


-- ============================================================================
-- Q8: Saldo total por tipo de cuenta y sucursal
-- ============================================================================

SELECT 
    s.nombre AS sucursal,
    cb.tipo_cuenta,
    SUM(DISTINCT cb.saldo) AS saldo_total_custodia

FROM CUENTA_BANCARIA cb

JOIN TRANSACCION t
    ON cb.numero_cuenta = t.numero_cuenta

JOIN SUCURSAL s
    ON t.id_sucursal = s.id_sucursal

GROUP BY s.nombre, cb.tipo_cuenta

ORDER BY s.nombre, cb.tipo_cuenta;


-- ============================================================================
-- Q9: Reporte cartera préstamos
-- ============================================================================

SELECT 
    p.tipo_prestamo,

    COUNT(DISTINCT p.id_prestamo) AS numero_prestamos,

    SUM(p.monto) AS monto_total_colocado,

    SUM(
        p.monto -
        NVL(
            (
                SELECT SUM(pp.monto)
                FROM PAGO_PRESTAMO pp
                JOIN CUOTA_PRESTAMO cp2
                    ON pp.id_cuota = cp2.id_cuota
                WHERE cp2.id_prestamo = p.id_prestamo
            ),
            0
        )
    ) AS saldo_pendiente_total,

    ROUND(
        (
            COUNT(
                DISTINCT CASE
                    WHEN cp.fecha_vencimiento < TRUNC(SYSDATE)
                     AND NOT EXISTS (
                            SELECT 1
                            FROM PAGO_PRESTAMO pp
                            WHERE pp.id_cuota = cp.id_cuota
                        )
                    THEN p.id_prestamo
                END
            )
            /
            COUNT(DISTINCT p.id_prestamo)
        ) * 100,
        2
    ) AS tasa_morosidad_porcentaje

FROM PRESTAMO p

LEFT JOIN CUOTA_PRESTAMO cp
    ON p.id_prestamo = cp.id_prestamo

GROUP BY p.tipo_prestamo;


-- ============================================================================
-- Q10: Uso tarjetas por franquicia último trimestre
-- ============================================================================

SELECT 
    tc.franquicia,
    COUNT(ct.id_compra) AS cantidad_consumos,
    SUM(ct.monto) AS monto_total_consumido

FROM COMPRA_TARJETA ct

JOIN TARJETA_CREDITO tc
    ON ct.id_tarjeta = tc.id_tarjeta

WHERE ct.fecha >= ADD_MONTHS(SYSDATE, -3)

GROUP BY tc.franquicia;


-- ============================================================================
-- Q11: Intereses generados por tipo de producto último mes
-- ============================================================================

SELECT 
    'TARJETA_CREDITO' AS producto,

    SUM(
        tc.saldo_utilizado *
        ((tc.tasa_interes_anual / 100) / 12)
    ) AS interes_generado_mes

FROM TARJETA_CREDITO tc

UNION ALL

SELECT 
    'CUENTA_CORRIENTE' AS producto,

    SUM(
        cc.limite_sobregiro *
        ((cc.tasa_interes_sobregiro / 100) / 12)
    ) AS interes_generado_mes

FROM CUENTA_CORRIENTE cc

UNION ALL

SELECT 
    'INVERSION' AS producto,

    SUM(
        i.monto *
        ((i.tasa_interes / 100) / 12)
    ) AS interes_generado_mes

FROM INVERSION i

WHERE i.fecha_inicio >= ADD_MONTHS(SYSDATE, -1);


-- ============================================================================
-- Q12: Clientes problemáticos
-- scoring < 500, mora > 30 días, tarjeta > 90% uso
-- ============================================================================

SELECT DISTINCT 
    c.id_cliente,
    pn.nombres || ' ' || pn.apellidos AS cliente,
    c.scoring_crediticio

FROM CLIENTE c

JOIN PERSONA_NATURAL pn
    ON c.id_cliente = pn.id_cliente

JOIN PRESTAMO p
    ON c.id_cliente = p.id_cliente

JOIN CUOTA_PRESTAMO cp
    ON p.id_prestamo = cp.id_prestamo

JOIN TARJETA_CREDITO tc
    ON c.id_cliente = tc.id_cliente

WHERE c.scoring_crediticio < 500

AND (tc.saldo_utilizado / tc.cupo_asignado) > 0.90

AND cp.fecha_vencimiento < TRUNC(SYSDATE) - 30

AND NOT EXISTS (
    SELECT 1
    FROM PAGO_PRESTAMO pp
    WHERE pp.id_cuota = cp.id_cuota
);


-- ============================================================================
-- Q13: Comportamiento transaccional por canal últimos 6 meses
-- ============================================================================

SELECT 
    t.canal,
    COUNT(t.id_transaccion) AS volumen_transacciones,
    SUM(t.monto) AS monto_total_canal,
    ROUND(AVG(t.monto), 2) AS ticket_promedio

FROM TRANSACCION t

WHERE t.fecha_hora >= ADD_MONTHS(SYSDATE, -6)

GROUP BY t.canal

ORDER BY volumen_transacciones DESC;


-- ============================================================================
-- Q14: Ranking 20 clientes más rentables
-- ============================================================================

SELECT *
FROM (
    SELECT 
        c.id_cliente,

        pn.nombres || ' ' || pn.apellidos AS cliente,

        (
            NVL(
                (
                    SELECT SUM(cb.saldo)
                    FROM TITULAR_CUENTA tc
                    JOIN CUENTA_BANCARIA cb
                        ON tc.numero_cuenta = cb.numero_cuenta
                    WHERE tc.id_cliente = c.id_cliente
                ),
                0
            )

            +

            NVL(
                (
                    SELECT SUM(p.monto * (p.tasa / 100))
                    FROM PRESTAMO p
                    WHERE p.id_cliente = c.id_cliente
                ),
                0
            )

            +

            NVL(
                (
                    SELECT SUM(
                        tc.saldo_utilizado *
                        (tc.tasa_interes_anual / 100)
                    )
                    FROM TARJETA_CREDITO tc
                    WHERE tc.id_cliente = c.id_cliente
                ),
                0
            )

            +

            NVL(
                (
                    SELECT SUM(i.monto)
                    FROM INVERSION i
                    WHERE i.id_cliente = c.id_cliente
                ),
                0
            )

        ) AS rentabilidad_estimada

    FROM CLIENTE c

    JOIN PERSONA_NATURAL pn
        ON c.id_cliente = pn.id_cliente

    ORDER BY rentabilidad_estimada DESC
)
WHERE ROWNUM <= 20;


-- ============================================================================
-- Q15: Detectar transacciones potencialmente fraudulentas
-- ============================================================================

SELECT 
    t.id_transaccion,
    t.numero_cuenta,
    t.canal,
    t.monto,
    t.fecha_hora,
    t.token_validado,

    CASE

        WHEN t.canal IN ('WEB', 'MOVIL')
         AND t.token_validado = 0
        THEN 'ALTA - INYECCION DIGITAL SIN TOKEN'

        WHEN t.monto > (
                SELECT AVG(sub.monto) * 3
                FROM TRANSACCION sub
                WHERE sub.canal = t.canal
             )
        THEN 'CRITICA - VOLUMEN ANOMALO'

        ELSE 'MODERADA'

    END AS motivo_alerta

FROM TRANSACCION t

WHERE (
        t.canal IN ('WEB', 'MOVIL')
        AND t.token_validado = 0
      )

OR t.monto > (
        SELECT AVG(sub.monto) * 3
        FROM TRANSACCION sub
        WHERE sub.canal = t.canal
   );