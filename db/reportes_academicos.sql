-- =============================================================================
-- PROYECTO: Sistema Escolar Pro - Tecnológico de La Laguna
-- ARCHIVO: db/reportes_academicos.sql
-- DESCRIPCIÓN: Vistas y consultas optimizadas para Kardex Imprimible, Boletas,
--              Listas de Asistencia, Búsqueda Global y Semáforo de Riesgo Académico.
-- EJECUCIÓN: Re-ejecutable de manera segura (CREATE OR REPLACE FORCE VIEW).
-- =============================================================================

-- =============================================================================
-- 1. VISTA DE KARDEX ESTUDIANTIL OFICIAL
-- Incluye desglose por ciclo, calificaciones, promedio general y créditos acumulados.
-- =============================================================================
CREATE OR REPLACE FORCE VIEW v_rep_kardex_alumno AS
SELECT 
    a.n_control,
    a.nombre || ' ' || a.apellidos AS alumno,
    a.nombre AS alumno_nombre,
    a.apellidos AS alumno_apellidos,
    a.curp,
    a.mail,
    a.telefono,
    a.anio_ingreso,
    ci.id_ciclo,
    ci.nombre AS ciclo,
    ci.fecha_ini AS fecha_ini_ciclo,
    m.id_materia,
    m.clave AS clave_materia,
    m.nombre AS materia,
    m.creditos AS creditos_materia,
    g.id_grupo,
    g.nombre AS grupo,
    p.nombre || ' ' || p.apellidos AS profesor,
    c.id_calificacion,
    c.calificacion,
    CASE 
        WHEN c.calificacion >= 70 THEN 'ACREDITADA'
        WHEN c.calificacion < 70 THEN 'NO ACREDITADA'
        ELSE 'EN CURSO'
    END AS estatus_materia,
    ROUND(AVG(c.calificacion) OVER (PARTITION BY a.n_control), 2) AS promedio_general,
    SUM(CASE WHEN c.calificacion >= 70 THEN m.creditos ELSE 0 END) OVER (PARTITION BY a.n_control) AS creditos_acumulados,
    SUM(m.creditos) OVER (PARTITION BY a.n_control) AS creditos_totales_cursados,
    ROUND(
        (SUM(CASE WHEN c.calificacion >= 70 THEN m.creditos ELSE 0 END) OVER (PARTITION BY a.n_control) * 100.0) /
        NULLIF(SUM(m.creditos) OVER (PARTITION BY a.n_control), 0), 1
    ) AS avance_porcentaje
FROM alumnos a
JOIN calificaciones c ON c.n_control = a.n_control
JOIN grupos g ON g.id_grupo = c.id_grupo
JOIN materias m ON m.id_materia = g.id_materia
JOIN ciclos ci ON ci.id_ciclo = g.id_ciclo
JOIN profesores p ON p.id_profesor = g.id_profesor;


-- =============================================================================
-- 2. VISTA DE BOLETA DE EVALUACIÓN SEMESTRAL
-- Filtrable por alumno y período semestral, con promedio específico del ciclo.
-- =============================================================================
CREATE OR REPLACE FORCE VIEW v_rep_boleta_ciclo AS
SELECT 
    a.n_control,
    a.nombre || ' ' || a.apellidos AS alumno,
    a.curp,
    ci.id_ciclo,
    ci.nombre AS ciclo,
    m.clave AS clave_materia,
    m.nombre AS materia,
    m.creditos AS creditos,
    g.nombre AS grupo,
    p.nombre || ' ' || p.apellidos AS profesor,
    c.calificacion,
    CASE 
        WHEN c.calificacion >= 70 THEN 'Aprobada'
        WHEN c.calificacion < 70 THEN 'No Acreditada'
        ELSE 'Pendiente'
    END AS resultado,
    ROUND(AVG(c.calificacion) OVER (PARTITION BY a.n_control, ci.id_ciclo), 2) AS promedio_ciclo,
    SUM(CASE WHEN c.calificacion >= 70 THEN m.creditos ELSE 0 END) OVER (PARTITION BY a.n_control, ci.id_ciclo) AS creditos_aprobados_ciclo
FROM alumnos a
JOIN calificaciones c ON c.n_control = a.n_control
JOIN grupos g ON g.id_grupo = c.id_grupo
JOIN materias m ON m.id_materia = g.id_materia
JOIN ciclos ci ON ci.id_ciclo = g.id_ciclo
JOIN profesores p ON p.id_profesor = g.id_profesor;


-- =============================================================================
-- 3. VISTA DE LISTA DE ASISTENCIA POR GRUPO
-- Optimizado para impresión institucional y exportación a Excel / PDF por materia.
-- =============================================================================
CREATE OR REPLACE FORCE VIEW v_rep_lista_asistencia AS
SELECT 
    g.id_grupo,
    g.nombre AS grupo,
    g.horario,
    ci.id_ciclo,
    ci.nombre AS ciclo,
    m.clave AS clave_materia,
    m.nombre AS materia,
    m.creditos,
    p.nombre || ' ' || p.apellidos AS profesor,
    NVL(au.nombre, 'Sin Aula Asignada') AS aula,
    ROW_NUMBER() OVER (PARTITION BY g.id_grupo ORDER BY a.apellidos, a.nombre) AS numero_lista,
    a.n_control,
    a.apellidos || ', ' || a.nombre AS alumno_nombre_completo,
    a.mail,
    a.telefono,
    a.sexo,
    a.activo
FROM grupos g
JOIN materias m ON m.id_materia = g.id_materia
JOIN ciclos ci ON ci.id_ciclo = g.id_ciclo
JOIN profesores p ON p.id_profesor = g.id_profesor
LEFT JOIN aulas au ON au.id_aula = g.id_aula
JOIN calificaciones c ON c.id_grupo = g.id_grupo
JOIN alumnos a ON a.n_control = c.n_control;


-- =============================================================================
-- 4. VISTA DE BÚSQUEDA GLOBAL INSTITUCIONAL
-- Permite búsqueda unificada y rápida por nombre, matrícula, CURP o correo.
-- =============================================================================
CREATE OR REPLACE FORCE VIEW v_busqueda_global_alumnos AS
WITH stats_alumno AS (
    SELECT 
        n_control,
        ROUND(AVG(calificacion), 2) AS prom_general,
        COUNT(calificacion) AS total_materias
    FROM calificaciones
    WHERE calificacion IS NOT NULL
    GROUP BY n_control
)
SELECT 
    a.n_control,
    a.nombre || ' ' || a.apellidos AS alumno,
    a.curp,
    a.mail,
    a.telefono,
    a.activo,
    CASE WHEN a.activo = 'S' THEN 'Activo' ELSE 'Baja / Inactivo' END AS estatus,
    NVL(s.prom_general, 0) AS promedio_general,
    a.creditos AS creditos_registrados,
    NVL(s.total_materias, 0) AS total_materias_evaluadas,
    UPPER(a.n_control || ' ' || a.nombre || ' ' || a.apellidos || ' ' || a.curp || ' ' || a.mail) AS texto_busqueda
FROM alumnos a
LEFT JOIN stats_alumno s ON s.n_control = a.n_control;


-- =============================================================================
-- 5. VISTA DE SEMÁFORO DE RIESGO ACADÉMICO
-- Clasifica a los alumnos en Verde, Amarillo o Rojo para intervención temprana.
-- =============================================================================
CREATE OR REPLACE FORCE VIEW v_alumnos_semaforo_riesgo AS
WITH metrics AS (
    SELECT 
        a.n_control,
        a.nombre || ' ' || a.apellidos AS alumno,
        a.curp,
        a.mail,
        a.telefono,
        a.activo,
        NVL(ROUND(AVG(c.calificacion), 2), 0) AS promedio_general,
        COUNT(c.id_calificacion) AS total_materias,
        COUNT(CASE WHEN c.calificacion < 70 THEN 1 END) AS materias_reprobadas,
        COUNT(CASE WHEN c.calificacion >= 70 THEN 1 END) AS materias_aprobadas,
        NVL(a.creditos, 0) AS creditos_actuales
    FROM alumnos a
    LEFT JOIN calificaciones c ON c.n_control = a.n_control
    GROUP BY a.n_control, a.nombre, a.apellidos, a.curp, a.mail, a.telefono, a.activo, a.creditos
)
SELECT 
    m.n_control,
    m.alumno,
    m.curp,
    m.mail,
    m.telefono,
    m.activo,
    m.promedio_general,
    m.total_materias,
    m.materias_reprobadas,
    m.materias_aprobadas,
    m.creditos_actuales,
    CASE 
        WHEN m.activo = 'N' THEN 'ALTO'
        WHEN m.promedio_general < 70 AND m.total_materias > 0 THEN 'ALTO'
        WHEN m.materias_reprobadas >= 2 THEN 'ALTO'
        WHEN m.promedio_general BETWEEN 70 AND 79.99 THEN 'MEDIO'
        ELSE 'BAJO'
    END AS nivel_riesgo,
    CASE 
        WHEN m.activo = 'N' THEN 'Inactivo / Baja escolar'
        WHEN m.promedio_general < 70 AND m.total_materias > 0 THEN 'Promedio no aprobatorio (< 70.0)'
        WHEN m.materias_reprobadas >= 2 THEN 'Acumulación de materias reprobadas'
        WHEN m.promedio_general BETWEEN 70 AND 79.99 THEN 'Rendimiento en zona de observación'
        ELSE 'Desempeño regular y al corriente'
    END AS motivo_riesgo,
    CASE 
        WHEN m.activo = 'N' OR (m.promedio_general < 70 AND m.total_materias > 0) OR m.materias_reprobadas >= 2 THEN
            '<span class="t-Badge t-Badge--danger t-Badge--subtle">Riesgo Alto</span>'
        WHEN m.promedio_general BETWEEN 70 AND 79.99 THEN
            '<span class="t-Badge t-Badge--warning t-Badge--subtle">Riesgo Medio</span>'
        ELSE
            '<span class="t-Badge t-Badge--success t-Badge--subtle">Riesgo Bajo</span>'
    END AS semaforo_html
FROM metrics m
ORDER BY 
    CASE 
        WHEN m.activo = 'N' OR (m.promedio_general < 70 AND m.total_materias > 0) OR m.materias_reprobadas >= 2 THEN 1
        WHEN m.promedio_general BETWEEN 70 AND 79.99 THEN 2
        ELSE 3
    END ASC,
    m.promedio_general ASC;
