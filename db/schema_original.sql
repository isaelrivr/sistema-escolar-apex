-- =============================================================================
-- PROYECTO: Sistema Escolar Pro - Tecnológico de La Laguna
-- ESQUEMA: escolar_dev (Oracle Autonomous Database / APEX)
-- DESCRIPCIÓN: Diccionario de datos y estructura de tablas base del sistema.
-- REGLA: No modificar los nombres de tablas ni columnas existentes.
-- =============================================================================

-- 1. TABLA: ESTADOS
-- Entidades federativas de la República Mexicana
CREATE TABLE IF NOT EXISTS estados (
    id_estado   NUMBER PRIMARY KEY,
    nombre      VARCHAR2(60) NOT NULL,
    clave_curp  VARCHAR2(2)
);

-- 2. TABLA: MUNICIPIOS
-- Municipios asociados a cada estado
CREATE TABLE IF NOT EXISTS municipios (
    id_municipio NUMBER PRIMARY KEY,
    id_estado    NUMBER NOT NULL,
    nombre       VARCHAR2(80) NOT NULL,
    CONSTRAINT fk_mun_estado FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
);

-- 3. TABLA: CICLOS
-- Ciclos escolares y períodos semestrales
CREATE TABLE IF NOT EXISTS ciclos (
    id_ciclo    NUMBER PRIMARY KEY,
    nombre      VARCHAR2(30) NOT NULL,
    fecha_ini   DATE,
    fecha_fin   DATE
);

-- 4. TABLA: AULAS
-- Espacios físicos, aulas y laboratorios
CREATE TABLE IF NOT EXISTS aulas (
    id_aula     NUMBER PRIMARY KEY,
    nombre      VARCHAR2(40) NOT NULL
);

-- 5. TABLA: MATERIAS
-- Catálogo de asignaturas del plan de estudios
CREATE TABLE IF NOT EXISTS materias (
    id_materia  NUMBER PRIMARY KEY,
    clave       VARCHAR2(20) NOT NULL,
    nombre      VARCHAR2(100) NOT NULL,
    creditos    NUMBER(2,0) NOT NULL
);

-- 6. TABLA: PROFESORES
-- Cuerpo docente institucional
CREATE TABLE IF NOT EXISTS profesores (
    id_profesor  NUMBER PRIMARY KEY,
    nombre       VARCHAR2(60) NOT NULL,
    apellidos    VARCHAR2(80) NOT NULL,
    direccion    VARCHAR2(200),
    id_municipio NUMBER,
    telefono     VARCHAR2(20),
    mail         VARCHAR2(120),
    CONSTRAINT fk_prof_mun FOREIGN KEY (id_municipio) REFERENCES municipios(id_municipio)
);

-- 7. TABLA: ALUMNOS
-- Estudiantes inscritos en la institución
CREATE TABLE IF NOT EXISTS alumnos (
    n_control            VARCHAR2(15) PRIMARY KEY,
    nombre               VARCHAR2(60) NOT NULL,
    apellidos            VARCHAR2(80) NOT NULL,
    direccion            VARCHAR2(200),
    latitud              NUMBER(9,6),
    longitud             NUMBER(9,6),
    id_municipio         NUMBER,
    mail                 VARCHAR2(120),
    telefono             VARCHAR2(20),
    anio_ingreso         NUMBER(4,0),
    id_ciclo             NUMBER,
    activo               CHAR(1) DEFAULT 'S',
    creditos             NUMBER(4,0) DEFAULT 0,
    curp                 VARCHAR2(18),
    fecha_nacimiento     DATE,
    sexo                 VARCHAR2(1),
    id_estado_nacimiento NUMBER,
    CONSTRAINT fk_alum_mun FOREIGN KEY (id_municipio) REFERENCES municipios(id_municipio),
    CONSTRAINT fk_alum_ciclo FOREIGN KEY (id_ciclo) REFERENCES ciclos(id_ciclo),
    CONSTRAINT fk_alum_edo FOREIGN KEY (id_estado_nacimiento) REFERENCES estados(id_estado)
);

-- 8. TABLA: GRUPOS
-- Secciones o grupos ofertados por ciclo, materia, aula y docente
CREATE TABLE IF NOT EXISTS grupos (
    id_grupo    NUMBER PRIMARY KEY,
    id_materia  NUMBER NOT NULL,
    id_profesor NUMBER NOT NULL,
    id_aula     NUMBER,
    id_ciclo    NUMBER NOT NULL,
    nombre      VARCHAR2(20) NOT NULL,
    horario     VARCHAR2(60),
    CONSTRAINT fk_grp_materia FOREIGN KEY (id_materia) REFERENCES materias(id_materia),
    CONSTRAINT fk_grp_profesor FOREIGN KEY (id_profesor) REFERENCES profesores(id_profesor),
    CONSTRAINT fk_grp_aula FOREIGN KEY (id_aula) REFERENCES aulas(id_aula),
    CONSTRAINT fk_grp_ciclo FOREIGN KEY (id_ciclo) REFERENCES ciclos(id_ciclo)
);

-- 9. TABLA: CALIFICACIONES (Gestión de Inscripción y Evaluación)
-- Nota: La inscripción del alumno al grupo se registra en esta tabla.
CREATE TABLE IF NOT EXISTS calificaciones (
    id_calificacion NUMBER PRIMARY KEY,
    n_control       VARCHAR2(15) NOT NULL,
    id_grupo        NUMBER NOT NULL,
    calificacion    NUMBER(5,2),
    CONSTRAINT fk_calif_alumno FOREIGN KEY (n_control) REFERENCES alumnos(n_control),
    CONSTRAINT fk_calif_grupo FOREIGN KEY (id_grupo) REFERENCES grupos(id_grupo)
);
