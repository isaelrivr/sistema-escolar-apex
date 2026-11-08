-- =============================================================================
-- PROYECTO: Sistema Escolar Pro - Tecnológico de La Laguna
-- ARCHIVO: db/dashboard_vistas.sql
-- DESCRIPCIÓN: Vistas analíticas y consultas de soporte para el Dashboard
--              Ejecutivo de la Página 1 en Oracle APEX.
-- EJECUCIÓN: Re-ejecutable (CREATE OR REPLACE FORCE VIEW).
-- =============================================================================

-- =============================================================================
-- SECCIÓN A: VISTA MAESTRA DE INDICADORES CLAVE (KPIS INSTITUCIONALES)
-- =============================================================================
CREATE OR REPLACE FORCE VIEW v_dash_kpis AS
WITH metrics_alumnos AS (
    SELECT 
        COUNT(*) AS total_alumnos,
        COUNT(CASE WHEN activo = 'S' THEN 1 END) AS alumnos_activos,
        COUNT(CASE WHEN activo = 'N' OR activo IS NULL THEN 1 END) AS alumnos_inactivos,
        ROUND(COUNT(CASE WHEN activo = 'S' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 1) AS tasa_retencion_pct
    FROM alumnos
),
metrics_docentes AS (
    SELECT 
        COUNT(p.id_profesor) AS total_docentes,
        COUNT(DISTINCT g.id_profesor) AS docentes_con_grupo
    FROM profesores p
    LEFT JOIN grupos g ON g.id_profesor = p.id_profesor
),
metrics_infraestructura AS (
    SELECT 
        (SELECT COUNT(*) FROM materias) AS total_materias,
        (SELECT COUNT(*) FROM grupos) AS total_grupos,
        (SELECT COUNT(*) FROM aulas) AS total_aulas,
        (SELECT COUNT(*) FROM ciclos) AS total_ciclos
    FROM dual
),
metrics_calificaciones AS (
    SELECT 
        ROUND(AVG(calificacion), 2) AS promedio_general,
        COUNT(calificacion) AS total_evaluaciones,
        COUNT(CASE WHEN calificacion >= 70 THEN 1 END) AS total_aprobados,
        COUNT(CASE WHEN calificacion < 70 THEN 1 END) AS total_reprobados,
        ROUND(COUNT(CASE WHEN calificacion >= 70 THEN 1 END) * 100.0 / NULLIF(COUNT(calificacion), 0), 1) AS tasa_aprobacion_pct
    FROM calificaciones
    WHERE calificacion IS NOT NULL
),
metrics_riesgo AS (
    SELECT 
        COUNT(DISTINCT n_control) AS alumnos_en_riesgo
    FROM (
        SELECT 
            n_control,
            AVG(calificacion) AS prom_alumno
        FROM calificaciones
        WHERE calificacion IS NOT NULL
        GROUP BY n_control
        HAVING AVG(calificacion) < 70
    )
)
SELECT 
    a.total_alumnos,
    a.alumnos_activos,
    a.alumnos_inactivos,
    a.tasa_retencion_pct,
    d.total_docentes,
    d.docentes_con_grupo,
    i.total_materias,
    i.total_grupos,
    i.total_aulas,
    i.total_ciclos,
    c.promedio_general,
    c.total_evaluaciones,
    c.total_aprobados,
    c.total_reprobados,
    c.tasa_aprobacion_pct,
    NVL(r.alumnos_en_riesgo, 0) AS alumnos_en_riesgo
FROM metrics_alumnos a
CROSS JOIN metrics_docentes d
CROSS JOIN metrics_infraestructura i
CROSS JOIN metrics_calificaciones c
CROSS JOIN metrics_riesgo r;


-- =============================================================================
-- SECCIÓN B: BLOQUE 1 - ALUMNADO Y DEMOGRAFÍA (6 VISTAS)
-- =============================================================================

-- 1. Alumnos por Municipio de La Laguna y Región
CREATE OR REPLACE FORCE VIEW v_dash_alumnos_por_municipio AS
SELECT 
    NVL(m.nombre, 'Sin Municipio') AS etiqueta,
    COUNT(a.n_control) AS valor,
    ROUND(COUNT(a.n_control) * 100.0 / NULLIF((SELECT COUNT(*) FROM alumnos), 0), 1) AS porcentaje
FROM alumnos a
LEFT JOIN municipios m ON m.id_municipio = a.id_municipio
GROUP BY m.nombre
ORDER BY valor DESC;

-- 2. Distribución de Alumnos por Género
CREATE OR REPLACE FORCE VIEW v_dash_genero AS
SELECT 
    CASE 
        WHEN a.sexo = 'H' THEN 'Hombres'
        WHEN a.sexo = 'M' THEN 'Mujeres'
        ELSE 'No especificado'
    END AS etiqueta,
    COUNT(*) AS valor,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM alumnos), 0), 1) AS porcentaje
FROM alumnos a
GROUP BY a.sexo
ORDER BY valor DESC;

-- 3. Estatus de Alumnos (Activos vs Inactivos)
CREATE OR REPLACE FORCE VIEW v_dash_activos AS
SELECT 
    CASE 
        WHEN a.activo = 'S' THEN 'Alumnos Activos'
        WHEN a.activo = 'N' THEN 'Bajas / Inactivos'
        ELSE 'Sin Estatus'
    END AS etiqueta,
    COUNT(*) AS valor,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM alumnos), 0), 1) AS porcentaje
FROM alumnos a
GROUP BY a.activo
ORDER BY valor DESC;

-- 4. Alumnos por Estado de Nacimiento
CREATE OR REPLACE FORCE VIEW v_dash_alumnos_por_estado AS
SELECT 
    NVL(e.nombre, 'Sin Registro') AS etiqueta,
    COUNT(a.n_control) AS valor,
    ROUND(COUNT(a.n_control) * 100.0 / NULLIF((SELECT COUNT(*) FROM alumnos), 0), 1) AS porcentaje
FROM alumnos a
LEFT JOIN estados e ON e.id_estado = a.id_estado_nacimiento
GROUP BY e.nombre
ORDER BY valor DESC;

-- 5. Evolución de Matrícula por Año de Ingreso
CREATE OR REPLACE FORCE VIEW v_dash_alumnos_por_anio_ingreso AS
SELECT 
    NVL(TO_CHAR(a.anio_ingreso), 'Desconocido') AS etiqueta,
    COUNT(*) AS valor
FROM alumnos a
GROUP BY a.anio_ingreso
ORDER BY etiqueta ASC;

-- 6. Distribución de Alumnos por Rango de Edad
CREATE OR REPLACE FORCE VIEW v_dash_alumnos_por_edad AS
SELECT 
    rango_edad AS etiqueta,
    COUNT(*) AS valor,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM alumnos WHERE fecha_nacimiento IS NOT NULL), 0), 1) AS porcentaje
FROM (
    SELECT 
        CASE 
            WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_nacimiento)/12) < 19 THEN 'Menores de 19 años'
            WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_nacimiento)/12) BETWEEN 19 AND 21 THEN '19 a 21 años'
            WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_nacimiento)/12) BETWEEN 22 AND 24 THEN '22 a 24 años'
            WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_nacimiento)/12) >= 25 THEN '25 años o más'
            ELSE 'Sin fecha registrada'
        END AS rango_edad
    FROM alumnos
)
GROUP BY rango_edad
ORDER BY valor DESC;


-- =============================================================================
-- SECCIÓN C: BLOQUE 2 - MATERIAS Y CARGA ACADÉMICA (5 VISTAS)
-- =============================================================================

-- 7. Top 10 Materias con Mayor Demanda Estudiantil
CREATE OR REPLACE FORCE VIEW v_dash_top_materias AS
SELECT 
    m.clave || ' - ' || m.nombre AS etiqueta,
    COUNT(c.id_calificacion) AS valor
FROM materias m
JOIN grupos g ON g.id_materia = m.id_materia
JOIN calificaciones c ON c.id_grupo = g.id_grupo
GROUP BY m.clave, m.nombre
ORDER BY valor DESC
FETCH FIRST 10 ROWS ONLY;

-- 8. Top 10 Materias con Mejor Promedio de Calificación
CREATE OR REPLACE FORCE VIEW v_dash_materias_promedio AS
SELECT 
    m.clave || ' - ' || m.nombre AS etiqueta,
    ROUND(AVG(c.calificacion), 2) AS valor
FROM materias m
JOIN grupos g ON g.id_materia = m.id_materia
JOIN calificaciones c ON c.id_grupo = g.id_grupo
WHERE c.calificacion IS NOT NULL
GROUP BY m.clave, m.nombre
HAVING COUNT(c.calificacion) >= 10
ORDER BY valor DESC
FETCH FIRST 10 ROWS ONLY;

-- 9. Top 10 Materias con Menor Promedio (Áreas de Oportunidad)
CREATE OR REPLACE FORCE VIEW v_dash_materias_menor_promedio AS
SELECT 
    m.clave || ' - ' || m.nombre AS etiqueta,
    ROUND(AVG(c.calificacion), 2) AS valor
FROM materias m
JOIN grupos g ON g.id_materia = m.id_materia
JOIN calificaciones c ON c.id_grupo = g.id_grupo
WHERE c.calificacion IS NOT NULL
GROUP BY m.clave, m.nombre
HAVING COUNT(c.calificacion) >= 10
ORDER BY valor ASC
FETCH FIRST 10 ROWS ONLY;

-- 10. Distribución de Catálogo de Materias por Valor en Créditos
CREATE OR REPLACE FORCE VIEW v_dash_creditos_distribucion AS
SELECT 
    m.creditos || ' Créditos' AS etiqueta,
    COUNT(*) AS valor
FROM materias m
GROUP BY m.creditos
ORDER BY m.creditos ASC;

-- 11. Histograma Institucional de Calificaciones por Rango
CREATE OR REPLACE FORCE VIEW v_dash_calificaciones_rangos AS
SELECT 
    rango AS etiqueta,
    COUNT(*) AS valor,
    ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM calificaciones WHERE calificacion IS NOT NULL), 0), 1) AS porcentaje
FROM (
    SELECT 
        CASE 
            WHEN calificacion >= 90 THEN 'Excelente (90 - 100)'
            WHEN calificacion >= 80 THEN 'Notable (80 - 89)'
            WHEN calificacion >= 70 THEN 'Suficiente (70 - 79)'
            ELSE 'No Acreditada (< 70)'
        END AS rango
    FROM calificaciones
    WHERE calificacion IS NOT NULL
)
GROUP BY rango
ORDER BY 
    CASE rango
        WHEN 'Excelente (90 - 100)' THEN 1
        WHEN 'Notable (80 - 89)' THEN 2
        WHEN 'Suficiente (70 - 79)' THEN 3
        ELSE 4
    END;


-- =============================================================================
-- SECCIÓN D: BLOQUE 3 - GRUPOS, AULAS Y CAPACIDAD OPERATIVA (4 VISTAS)
-- =============================================================================

-- 12. Apertura de Grupos por Ciclo Escolar
CREATE OR REPLACE FORCE VIEW v_dash_grupos_por_ciclo AS
SELECT 
    c.nombre AS etiqueta,
    COUNT(g.id_grupo) AS valor
FROM ciclos c
LEFT JOIN grupos g ON g.id_ciclo = c.id_ciclo
GROUP BY c.id_ciclo, c.nombre, c.fecha_ini
ORDER BY c.fecha_ini ASC;

-- 13. Ocupación y Asignación de Grupos por Aula
CREATE OR REPLACE FORCE VIEW v_dash_aulas_ocupacion AS
SELECT 
    NVL(a.nombre, 'Sin Aula Asignada') AS etiqueta,
    COUNT(g.id_grupo) AS valor
FROM aulas a
LEFT JOIN grupos g ON g.id_aula = a.id_aula
GROUP BY a.nombre
ORDER BY valor DESC
FETCH FIRST 12 ROWS ONLY;

-- 14. Tamaño y Saturación de Alumnos por Grupo
CREATE OR REPLACE FORCE VIEW v_dash_grupos_tamano AS
SELECT 
    m.clave || ' (' || g.nombre || ')' AS etiqueta,
    COUNT(c.id_calificacion) AS valor
FROM grupos g
JOIN materias m ON m.id_materia = g.id_materia
LEFT JOIN calificaciones c ON c.id_grupo = g.id_grupo
GROUP BY g.id_grupo, m.clave, g.nombre
ORDER BY valor DESC
FETCH FIRST 15 ROWS ONLY;

-- 15. Distribución de Grupos por Horario
CREATE OR REPLACE FORCE VIEW v_dash_horarios_frecuencia AS
SELECT 
    NVL(g.horario, 'Sin Horario Definido') AS etiqueta,
    COUNT(*) AS valor
FROM grupos g
GROUP BY g.horario
ORDER BY valor DESC
FETCH FIRST 10 ROWS ONLY;


-- =============================================================================
-- SECCIÓN E: BLOQUE 4 - PLANTA DOCENTE Y RENDIMIENTO INSTITUCIONAL (5 VISTAS)
-- =============================================================================

-- 16. Top 10 Profesores con Mayor Carga de Grupos
CREATE OR REPLACE FORCE VIEW v_dash_docentes_carga_grupos AS
SELECT 
    p.nombre || ' ' || p.apellidos AS etiqueta,
    COUNT(g.id_grupo) AS valor
FROM profesores p
JOIN grupos g ON g.id_profesor = p.id_profesor
GROUP BY p.id_profesor, p.nombre, p.apellidos
ORDER BY valor DESC
FETCH FIRST 10 ROWS ONLY;

-- 17. Promedio de Calificaciones Otorgadas por Profesor
CREATE OR REPLACE FORCE VIEW v_dash_docentes_promedio_calif AS
SELECT 
    p.nombre || ' ' || p.apellidos AS etiqueta,
    ROUND(AVG(c.calificacion), 2) AS valor
FROM profesores p
JOIN grupos g ON g.id_profesor = p.id_profesor
JOIN calificaciones c ON c.id_grupo = g.id_grupo
WHERE c.calificacion IS NOT NULL
GROUP BY p.id_profesor, p.nombre, p.apellidos
HAVING COUNT(c.calificacion) >= 15
ORDER BY valor DESC
FETCH FIRST 10 ROWS ONLY;

-- 18. Alumnos Atendidos e Inscritos por Profesor
CREATE OR REPLACE FORCE VIEW v_dash_docentes_alumnos_atendidos AS
SELECT 
    p.nombre || ' ' || p.apellidos AS etiqueta,
    COUNT(c.id_calificacion) AS valor
FROM profesores p
JOIN grupos g ON g.id_profesor = p.id_profesor
JOIN calificaciones c ON c.id_grupo = g.id_grupo
GROUP BY p.id_profesor, p.nombre, p.apellidos
ORDER BY valor DESC
FETCH FIRST 10 ROWS ONLY;

-- 19. Procedencia y Residencia de Profesores por Municipio
CREATE OR REPLACE FORCE VIEW v_dash_docentes_por_municipio AS
SELECT 
    NVL(m.nombre, 'Sin Municipio') AS etiqueta,
    COUNT(p.id_profesor) AS valor
FROM profesores p
LEFT JOIN municipios m ON m.id_municipio = p.id_municipio
GROUP BY m.nombre
ORDER BY valor DESC;

-- 20. Rendimiento Académico Histórico por Ciclo Escolar
CREATE OR REPLACE FORCE VIEW v_dash_rendimiento_ciclos AS
SELECT 
    c.nombre AS etiqueta,
    ROUND(AVG(cal.calificacion), 2) AS valor
FROM ciclos c
JOIN grupos g ON g.id_ciclo = c.id_ciclo
JOIN calificaciones cal ON cal.id_grupo = g.id_grupo
WHERE cal.calificacion IS NOT NULL
GROUP BY c.id_ciclo, c.nombre, c.fecha_ini
ORDER BY c.fecha_ini ASC;


-- =============================================================================
-- SECCIÓN F: TABLA DETALLADA DE MATERIAS CON MAYOR DEMANDA (CLASSIC REPORT)
-- =============================================================================
CREATE OR REPLACE FORCE VIEW v_dash_materias_demanda AS
SELECT 
    m.id_materia,
    m.clave,
    m.nombre AS materia,
    m.creditos,
    COUNT(DISTINCT g.id_grupo) AS total_grupos,
    COUNT(c.id_calificacion) AS total_inscritos,
    ROUND(AVG(c.calificacion), 1) AS promedio_calificacion,
    CASE 
        WHEN COUNT(c.id_calificacion) >= 40 THEN 'Alta Demanda'
        ELSE 'Regular'
    END AS estado_demanda,
    CASE 
        WHEN COUNT(c.id_calificacion) >= 40 THEN 
            '<span class="t-Badge t-Badge--danger t-Badge--subtle">Alta Demanda</span>'
        ELSE 
            '<span class="t-Badge t-Badge--info t-Badge--subtle">Regular</span>'
    END AS badge_demanda_html
FROM materias m
LEFT JOIN grupos g ON g.id_materia = m.id_materia
LEFT JOIN calificaciones c ON c.id_grupo = g.id_grupo
GROUP BY m.id_materia, m.clave, m.nombre, m.creditos
ORDER BY total_inscritos DESC;
