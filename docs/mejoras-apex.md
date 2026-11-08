# 📘 Guía Maestra de Mejoras e Implementación en Oracle APEX
## Sistema Escolar Pro — Tecnológico de La Laguna (App 107)

> **Destinatario:** Profesor evaluador / Administrador escolar  
> **Esquema Oracle Database:** `escolar_dev`  
> **Aplicación APEX:** `107 - Sistema Escolar Pro`  
> **Tema Base:** Universal Theme (Theme 42)  
> **Regla de oro:** No se modifican nombres de tablas físicas existentes ni esquemas de autenticación.

---

## 📑 Tabla de Contenidos
1. [Fase 1: Dashboard Ejecutivo Real (Página 1)](#fase-1-dashboard-ejecutivo-real-página-1)
2. [Fase 2: Pulido de Interfaz y Navegación](#fase-2-pulido-de-interfaz-y-navegación)
3. [Fase 3: Funcionalidad de Sistema Real (Kardex, Boletas, Asistencia, Auditoría)](#fase-3-funcionalidad-de-sistema-real)
4. [Fase 4: Rendimiento, Optimización y Mantenimiento](#fase-4-rendimiento-optimización-y-mantenimiento)
5. [Checklist Resumen para el Administrador](#checklist-resumen-para-el-administrador)

---

# Fase 1: Dashboard Ejecutivo Real (Página 1)

El objetivo de esta fase es sustituir todo el HTML estático o JavaScript con datos fijos por **vistas SQL dinámicas** y componentes nativos de Oracle APEX (Cards, Charts JET y Classic Reports).

### 1.1 Ejecución del Script de Vistas Analíticas
1. En el menú superior de APEX, ve a **SQL Workshop** > **SQL Scripts**.
2. Haz clic en **Upload** y sube el archivo [`db/dashboard_vistas.sql`](file:///C:/Users/isael/.gemini/antigravity/scratch/sistema-escolar-apex/db/dashboard_vistas.sql).
3. Haz clic en **Run** para compilar las 22 vistas analíticas (`v_dash_kpis`, 20 vistas de gráficas y `v_dash_materias_demanda`).
4. Verifica que todas las vistas se creen con estatus `VALID`.

---

### 1.2 Carga de la Hoja de Estilos CSS
1. Ve a **Shared Components** > **Static Application Files**.
2. Haz clic en **Upload File** y sube [`static/dashboard.css`](file:///C:/Users/isael/.gemini/antigravity/scratch/sistema-escolar-apex/static/dashboard.css).
3. En **App Builder** > **Page 1 (Hogar)**, en las propiedades de la página (panel derecho):
   - Ve a **CSS** > **File URLs**.
   - Ingresa: `#APP_FILES#dashboard.css`.

---

### 1.3 Región 1: Banner Hero Institucional con Identidad Oficial
Crea o edita la región superior del Dashboard con los datos oficiales:
* **Title:** `Hero Institucional`
* **Type:** `Static Content`
* **Template:** `Blank with Attributes`
* **Source (HTML):**
```html
<div class="sep-hero-banner">
  <div class="sep-hero-content">
    <h1 class="sep-hero-title">Sistema Escolar</h1>
    <div class="sep-hero-subtitle">Tecnológico de La Laguna</div>
  </div>
  <div class="sep-hero-logos">
    <img src="https://tl-mexico.org/wp-content/uploads/2021/04/logo-tecnm.png" alt="TecNM" title="Tecnológico Nacional de México" />
    <div class="logo-divider"></div>
    <img src="https://itlaguna.edu.mx/wp-content/uploads/2020/09/LOGOTIPO-ITL-OFICIAL-PNG.png" alt="ITL" title="Instituto Tecnológico de La Laguna" />
  </div>
</div>
```

---

### 1.4 Región 2: Módulos de Acceso Rápido (Declarative APEX Links)
En lugar de enlaces manuales tipo `f?p=...`, se utilizan enlaces nativos de APEX mediante una región de tipo **Cards**:
* **Title:** `Módulos de Gestión Rápida`
* **Type:** `Cards`
* **Source > Type:** `SQL Query`
* **SQL Query:**
```sql
SELECT 
    'Alumnos' AS titulo,
    (SELECT COUNT(*) || ' Registrados' FROM alumnos) AS subtitulo,
    'fa-users' AS icono,
    'sep-action-blue' AS clase_color,
    APEX_PAGE.GET_URL(p_page => '21') AS enlace
FROM dual
UNION ALL
SELECT 
    'Profesores' AS titulo,
    (SELECT COUNT(*) || ' Docentes' FROM profesores) AS subtitulo,
    'fa-graduation-cap' AS icono,
    'sep-action-emerald' AS clase_color,
    APEX_PAGE.GET_URL(p_page => '19') AS enlace
FROM dual
UNION ALL
SELECT 
    'Calificaciones' AS titulo,
    'Captura y Evaluación' AS subtitulo,
    'fa-edit' AS icono,
    'sep-action-amber' AS clase_color,
    APEX_PAGE.GET_URL(p_page => '28') AS enlace
FROM dual
UNION ALL
SELECT 
    'Kardex' AS titulo,
    'Historial Escolar' AS subtitulo,
    'fa-file-text-o' AS icono,
    'sep-action-purple' AS clase_color,
    APEX_PAGE.GET_URL(p_page => '30') AS enlace
FROM dual
UNION ALL
SELECT 
    'Mapa Alumnos' AS titulo,
    'Distribución Geo' AS subtitulo,
    'fa-map-marker' AS icono,
    'sep-action-rose' AS clase_color,
    APEX_PAGE.GET_URL(p_page => '23') AS enlace
FROM dual
UNION ALL
SELECT 
    'Grupos y Aulas' AS titulo,
    (SELECT COUNT(*) || ' Grupos' FROM grupos) AS subtitulo,
    'fa-cubes' AS icono,
    'sep-action-cyan' AS clase_color,
    APEX_PAGE.GET_URL(p_page => '25') AS enlace
FROM dual;
```
* **Attributes:**
  - **Card > Primary Key Column:** `TITULO`
  - **Title > Column:** `TITULO`
  - **Subtitle > Column:** `SUBTITULO`
  - **Icon > Icon Source:** `Icon Class` (`&ICONO.`)
  - **Card > Link > Type:** `Redirect to URL` -> Target: `&ENLACE.`

---

### 1.5 Región 3: Indicadores Académicos Institucionales (KPIs Ejecutivos)
* **Title:** `Indicadores Clave del Sistema`
* **Type:** `Cards` (o `Badge List`)
* **Template:** `Standard`
* **Source > Type:** `SQL Query`
* **SQL Query:**
```sql
SELECT 
    'PROMEDIO GENERAL' AS label,
    TO_CHAR(promedio_general, '990.0') AS valor,
    'Escala 0 - 100 • ' || TO_CHAR(total_evaluaciones, 'FM999,999') || ' evaluaciones' AS descripcion,
    'fa-line-chart' AS icono,
    'green' AS color_badge
FROM v_dash_kpis
UNION ALL
SELECT 
    'POBLACIÓN ESTUDIANTIL' AS label,
    TO_CHAR(total_alumnos, 'FM999,999') AS valor,
    total_activos || ' activos (' || tasa_retencion_pct || '% retención)' AS descripcion,
    'fa-graduation-cap' AS icono,
    'blue' AS color_badge
FROM v_dash_kpis
UNION ALL
SELECT 
    'PLANTILLA DOCENTE' AS label,
    TO_CHAR(total_docentes, 'FM999,999') AS valor,
    docentes_con_grupo || ' con grupo asignado en ciclo actual' AS descripcion,
    'fa-user-circle' AS icono,
    'purple' AS color_badge
FROM v_dash_kpis
UNION ALL
SELECT 
    'CAPACIDAD OPERATIVA' AS label,
    TO_CHAR(total_grupos, 'FM999,999') AS valor,
    total_aulas || ' aulas y laboratorios activos' AS descripcion,
    'fa-building' AS icono,
    'amber' AS color_badge
FROM v_dash_kpis
UNION ALL
SELECT 
    'ALUMNOS EN RIESGO' AS label,
    TO_CHAR(alumnos_en_riesgo, 'FM999,999') AS valor,
    'Promedio menor a 70.0 (Atención prioritaria)' AS descripcion,
    'fa-exclamation-triangle' AS icono,
    'rose' AS color_badge
FROM v_dash_kpis;
```

---

### 1.6 Regiones 4 a 7: Gráficas Analíticas Nativas de Oracle JET (20 Gráficas)
En Page Builder, organiza las 20 gráficas en 4 regiones tipo **Sub-Tabs** o **Collapsible Headers**:

#### Bloque A: Alumnado y Demografía
1. **Alumnos por Municipio:**
   - **Type:** `Chart` > **Chart Type:** `Bar (Horizontal)`
   - **SQL:** `SELECT etiqueta, valor FROM v_dash_alumnos_por_municipio WHERE ROWNUM <= 8;`
   - **Value:** `VALOR`, **Label:** `ETIQUETA`
2. **Distribución por Género:**
   - **Type:** `Chart` > **Chart Type:** `Donut`
   - **SQL:** `SELECT etiqueta, valor FROM v_dash_genero;`
   - **Value:** `VALOR`, **Label:** `ETIQUETA`
3. **Estatus de Alumnos (Activos vs Inactivos):**
   - **Type:** `Chart` > **Chart Type:** `Pie`
   - **SQL:** `SELECT etiqueta, valor FROM v_dash_activos;`
   - **Value:** `VALOR`, **Label:** `ETIQUETA`
4. **Alumnos por Estado de Nacimiento:**
   - **Type:** `Chart` > **Chart Type:** `Bar (Vertical)`
   - **SQL:** `SELECT etiqueta, valor FROM v_dash_alumnos_por_estado WHERE ROWNUM <= 8;`
5. **Evolución por Año de Ingreso:**
   - **Type:** `Chart` > **Chart Type:** `Line`
   - **SQL:** `SELECT etiqueta, valor FROM v_dash_alumnos_por_anio_ingreso;`
6. **Distribución por Rango de Edad:**
   - **Type:** `Chart` > **Chart Type:** `Bar`
   - **SQL:** `SELECT etiqueta, valor FROM v_dash_alumnos_por_edad;`

#### Bloque B: Materias y Carga Académica
7. **Top 10 Materias con Mayor Demanda:**
   - **Type:** `Chart` > **Chart Type:** `Bar (Horizontal)`
   - **SQL:** `SELECT etiqueta, valor FROM v_dash_top_materias;`
8. **Top 10 Materias con Mejor Promedio:**
   - **Type:** `Chart` > **Chart Type:** `Bar`
   - **SQL:** `SELECT etiqueta, valor FROM v_dash_materias_promedio;`
9. **Materias con Menor Promedio (Áreas de Oportunidad):**
   - **Type:** `Chart` > **Chart Type:** `Bar`
   - **SQL:** `SELECT etiqueta, valor FROM v_dash_materias_menor_promedio;`
10. **Distribución de Materias por Créditos:**
    - **Type:** `Chart` > **Chart Type:** `Donut`
    - **SQL:** `SELECT etiqueta, valor FROM v_dash_creditos_distribucion;`
11. **Histograma de Calificaciones por Rango:**
    - **Type:** `Chart` > **Chart Type:** `Bar`
    - **SQL:** `SELECT etiqueta, valor FROM v_dash_calificaciones_rangos;`

#### Bloque C: Grupos, Aulas y Capacidad
12. **Grupos Abiertos por Ciclo Escolar:**
    - **Type:** `Chart` > **Chart Type:** `Line / Bar`
    - **SQL:** `SELECT etiqueta, valor FROM v_dash_grupos_por_ciclo;`
13. **Ocupación de Grupos por Aula:**
    - **Type:** `Chart` > **Chart Type:** `Bar (Horizontal)`
    - **SQL:** `SELECT etiqueta, valor FROM v_dash_aulas_ocupacion;`
14. **Saturación de Alumnos por Grupo:**
    - **Type:** `Chart` > **Chart Type:** `Bar`
    - **SQL:** `SELECT etiqueta, valor FROM v_dash_grupos_tamano;`
15. **Grupos por Horario:**
    - **Type:** `Chart` > **Chart Type:** `Donut / Pie`
    - **SQL:** `SELECT etiqueta, valor FROM v_dash_horarios_frecuencia;`

#### Bloque D: Planta Docente y Rendimiento
16. **Top Docentes con Mayor Carga Horaria:**
    - **Type:** `Chart` > **Chart Type:** `Bar (Horizontal)`
    - **SQL:** `SELECT etiqueta, valor FROM v_dash_docentes_carga_grupos;`
17. **Promedio de Calificaciones por Docente:**
    - **Type:** `Chart` > **Chart Type:** `Bar`
    - **SQL:** `SELECT etiqueta, valor FROM v_dash_docentes_promedio_calif;`
18. **Alumnos Atendidos por Docente:**
    - **Type:** `Chart` > **Chart Type:** `Bar`
    - **SQL:** `SELECT etiqueta, valor FROM v_dash_docentes_alumnos_atendidos;`
19. **Docentes por Municipio de Residencia:**
    - **Type:** `Chart` > **Chart Type:** `Donut`
    - **SQL:** `SELECT etiqueta, valor FROM v_dash_docentes_por_municipio;`
20. **Evolución del Rendimiento por Ciclo:**
    - **Type:** `Chart` > **Chart Type:** `Line`
    - **SQL:** `SELECT etiqueta, valor FROM v_dash_rendimiento_ciclos;`

---

### 1.7 Región 8: Tabla de Materias con Mayor Demanda
* **Title:** `Materias con Mayor Demanda Estudiantil`
* **Type:** `Classic Report`
* **Template:** `Standard`
* **Source > Type:** `SQL Query`
* **SQL Query:**
```sql
SELECT 
    clave AS "Clave",
    materia AS "Nombre de la Asignatura",
    creditos AS "Créditos",
    total_grupos AS "Grupos Ofertados",
    total_inscritos AS "Alumnos Inscritos",
    promedio_calificacion AS "Promedio",
    badge_demanda_html AS "Estatus Demanda"
FROM v_dash_materias_demanda;
```
* **Attributes:**
  - En la columna `Estatus Demanda`, desactiva **Escape special characters** para renderizar la etiqueta HTML con estilo.
