-- =============================================================================
-- PROYECTO: Sistema Escolar Pro - Tecnológico de La Laguna
-- ARCHIVO: db/auditoria.sql
-- DESCRIPCIÓN: Implementación de trazabilidad y auditoría completa:
--              1. Columnas de auditoría (creado_por, fecha_creacion, modificado_por, fecha_modificacion).
--              2. Triggers de actualización automática de autoría y fecha.
--              3. Tabla de Bitácora de Calificaciones con histórico de notas.
--              4. Vista de auditoría para reporte en Oracle APEX.
-- EJECUCIÓN: Totalmente idempotente (se puede ejecutar múltiples veces sin error).
-- =============================================================================

-- =============================================================================
-- 1. ADICIÓN SEGURA DE COLUMNAS DE AUDITORÍA A LAS TABLAS BASE
-- =============================================================================
DECLARE
    PROCEDURE agregar_col_si_no_existe(p_tabla VARCHAR2, p_col VARCHAR2, p_tipo VARCHAR2) IS
        v_existe NUMBER := 0;
    BEGIN
        SELECT COUNT(*) INTO v_existe
        FROM user_tab_cols
        WHERE table_name = UPPER(p_tabla) AND column_name = UPPER(p_col);
        
        IF v_existe = 0 THEN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || p_tabla || ' ADD (' || p_col || ' ' || p_tipo || ')';
            DBMS_OUTPUT.PUT_LINE('Columna ' || p_col || ' agregada a ' || p_tabla);
        END IF;
    END;
BEGIN
    -- Tablas a auditar
    FOR t IN (
        SELECT 'ALUMNOS' AS tbl FROM dual UNION ALL
        SELECT 'PROFESORES' FROM dual UNION ALL
        SELECT 'CALIFICACIONES' FROM dual UNION ALL
        SELECT 'GRUPOS' FROM dual UNION ALL
        SELECT 'MATERIAS' FROM dual UNION ALL
        SELECT 'AULAS' FROM dual UNION ALL
        SELECT 'CICLOS' FROM dual
    ) LOOP
        agregar_col_si_no_existe(t.tbl, 'creado_por', 'VARCHAR2(60)');
        agregar_col_si_no_existe(t.tbl, 'fecha_creacion', 'DATE DEFAULT SYSDATE');
        agregar_col_si_no_existe(t.tbl, 'modificado_por', 'VARCHAR2(60)');
        agregar_col_si_no_existe(t.tbl, 'fecha_modificacion', 'DATE');
    END LOOP;
END;
/

-- =============================================================================
-- 2. TRIGGERS DE AUDITORÍA AUTOMÁTICA EN TABLAS PRINCIPALES
-- =============================================================================

-- A. Trigger para ALUMNOS
CREATE OR REPLACE TRIGGER trg_aud_alumnos
BEFORE INSERT OR UPDATE ON alumnos
FOR EACH ROW
DECLARE
    v_user VARCHAR2(60);
BEGIN
    v_user := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
    IF INSERTING THEN
        :NEW.creado_por := NVL(:NEW.creado_por, v_user);
        :NEW.fecha_creacion := NVL(:NEW.fecha_creacion, SYSDATE);
    ELSIF UPDATING THEN
        :NEW.modificado_por := v_user;
        :NEW.fecha_modificacion := SYSDATE;
    END IF;
END;
/

-- B. Trigger para PROFESORES
CREATE OR REPLACE TRIGGER trg_aud_profesores
BEFORE INSERT OR UPDATE ON profesores
FOR EACH ROW
DECLARE
    v_user VARCHAR2(60);
BEGIN
    v_user := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
    IF INSERTING THEN
        :NEW.creado_por := NVL(:NEW.creado_por, v_user);
        :NEW.fecha_creacion := NVL(:NEW.fecha_creacion, SYSDATE);
    ELSIF UPDATING THEN
        :NEW.modificado_por := v_user;
        :NEW.fecha_modificacion := SYSDATE;
    END IF;
END;
/

-- C. Trigger para CALIFICACIONES
CREATE OR REPLACE TRIGGER trg_aud_calificaciones
BEFORE INSERT OR UPDATE ON calificaciones
FOR EACH ROW
DECLARE
    v_user VARCHAR2(60);
BEGIN
    v_user := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
    IF INSERTING THEN
        :NEW.creado_por := NVL(:NEW.creado_por, v_user);
        :NEW.fecha_creacion := NVL(:NEW.fecha_creacion, SYSDATE);
    ELSIF UPDATING THEN
        :NEW.modificado_por := v_user;
        :NEW.fecha_modificacion := SYSDATE;
    END IF;
END;
/

-- D. Trigger para GRUPOS
CREATE OR REPLACE TRIGGER trg_aud_grupos
BEFORE INSERT OR UPDATE ON grupos
FOR EACH ROW
DECLARE
    v_user VARCHAR2(60);
BEGIN
    v_user := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
    IF INSERTING THEN
        :NEW.creado_por := NVL(:NEW.creado_por, v_user);
        :NEW.fecha_creacion := NVL(:NEW.fecha_creacion, SYSDATE);
    ELSIF UPDATING THEN
        :NEW.modificado_por := v_user;
        :NEW.fecha_modificacion := SYSDATE;
    END IF;
END;
/

-- E. Trigger para MATERIAS
CREATE OR REPLACE TRIGGER trg_aud_materias
BEFORE INSERT OR UPDATE ON materias
FOR EACH ROW
DECLARE
    v_user VARCHAR2(60);
BEGIN
    v_user := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
    IF INSERTING THEN
        :NEW.creado_por := NVL(:NEW.creado_por, v_user);
        :NEW.fecha_creacion := NVL(:NEW.fecha_creacion, SYSDATE);
    ELSIF UPDATING THEN
        :NEW.modificado_por := v_user;
        :NEW.fecha_modificacion := SYSDATE;
    END IF;
END;
/

-- =============================================================================
-- 3. TABLA DE BITÁCORA HISTÓRICA PARA CAMBIOS EN CALIFICACIONES
-- =============================================================================
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE bitacora_calificaciones (
            id_bitacora            NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
            id_calificacion        NUMBER NOT NULL,
            n_control              VARCHAR2(15) NOT NULL,
            id_grupo               NUMBER NOT NULL,
            calificacion_anterior  NUMBER(5,2),
            calificacion_nueva     NUMBER(5,2),
            tipo_operacion         VARCHAR2(10) NOT NULL,
            usuario                VARCHAR2(60) NOT NULL,
            fecha_registro         DATE DEFAULT SYSDATE NOT NULL,
            ip_origen              VARCHAR2(60)
        )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            NULL; -- Tabla ya existe
        ELSE
            RAISE;
        END IF;
END;
/

-- =============================================================================
-- 4. TRIGGER DE AUDITORÍA DETALLADA PARA CALIFICACIONES
-- Registra cada inserción, modificación de calificación o borrado.
-- =============================================================================
CREATE OR REPLACE TRIGGER trg_bitacora_calificaciones
AFTER INSERT OR UPDATE OR DELETE ON calificaciones
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(10);
    v_usuario   VARCHAR2(60);
    v_ip        VARCHAR2(60);
BEGIN
    v_usuario := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
    v_ip      := SYS_CONTEXT('USERENV', 'IP_ADDRESS');

    IF INSERTING THEN
        v_operacion := 'INSERT';
        INSERT INTO bitacora_calificaciones (
            id_calificacion, n_control, id_grupo,
            calificacion_anterior, calificacion_nueva,
            tipo_operacion, usuario, fecha_registro, ip_origen
        ) VALUES (
            :NEW.id_calificacion, :NEW.n_control, :NEW.id_grupo,
            NULL, :NEW.calificacion,
            v_operacion, v_usuario, SYSDATE, v_ip
        );
    ELSIF UPDATING THEN
        -- Solo registrar en bitácora si hubo un cambio real en la calificación
        IF NVL(:OLD.calificacion, -1) != NVL(:NEW.calificacion, -1) THEN
            v_operacion := 'UPDATE';
            INSERT INTO bitacora_calificaciones (
                id_calificacion, n_control, id_grupo,
                calificacion_anterior, calificacion_nueva,
                tipo_operacion, usuario, fecha_registro, ip_origen
            ) VALUES (
                :NEW.id_calificacion, :NEW.n_control, :NEW.id_grupo,
                :OLD.calificacion, :NEW.calificacion,
                v_operacion, v_usuario, SYSDATE, v_ip
            );
        END IF;
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        INSERT INTO bitacora_calificaciones (
            id_calificacion, n_control, id_grupo,
            calificacion_anterior, calificacion_nueva,
            tipo_operacion, usuario, fecha_registro, ip_origen
        ) VALUES (
            :OLD.id_calificacion, :OLD.n_control, :OLD.id_grupo,
            :OLD.calificacion, NULL,
            v_operacion, v_usuario, SYSDATE, v_ip
        );
    END IF;
END;
/

-- =============================================================================
-- 5. VISTA DE CONSULTA PARA REPORTE DE BITÁCORA EN APEX
-- Conecta datos del alumno, materia, grupo y docente para auditorías visuales.
-- =============================================================================
CREATE OR REPLACE FORCE VIEW v_bitacora_calificaciones AS
SELECT 
    b.id_bitacora,
    b.fecha_registro,
    b.tipo_operacion,
    CASE b.tipo_operacion
        WHEN 'INSERT' THEN '<span class="t-Badge t-Badge--success t-Badge--subtle">Alta</span>'
        WHEN 'UPDATE' THEN '<span class="t-Badge t-Badge--warning t-Badge--subtle">Modificación</span>'
        WHEN 'DELETE' THEN '<span class="t-Badge t-Badge--danger t-Badge--subtle">Eliminación</span>'
    END AS operacion_badge_html,
    b.usuario,
    b.n_control,
    a.nombre || ' ' || a.apellidos AS alumno,
    m.clave AS clave_materia,
    m.nombre AS materia,
    g.nombre AS grupo,
    p.nombre || ' ' || p.apellidos AS profesor,
    b.calificacion_anterior,
    b.calificacion_nueva,
    b.ip_origen
FROM bitacora_calificaciones b
LEFT JOIN alumnos a ON a.n_control = b.n_control
LEFT JOIN grupos g ON g.id_grupo = b.id_grupo
LEFT JOIN materias m ON m.id_materia = g.id_materia
LEFT JOIN profesores p ON p.id_profesor = g.id_profesor
ORDER BY b.fecha_registro DESC;
