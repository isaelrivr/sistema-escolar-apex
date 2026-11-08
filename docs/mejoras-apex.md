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


---

# Fase 2: Pulido de Interfaz y Navegación

En esta fase se garantiza una experiencia de usuario institucional, profesional y 100% en español, eliminando inconsistencias visuales, íconos erróneos e interfaces en inglés.

### 2.1 Estandarización del Menú de Navegación e Iconografía
Los íconos y textos del menú lateral y de hamburguesa se han unificado de forma coherente. Si configuras la aplicación directamente en **Shared Components** > **Lists** > **Navigation Menu**, verifica la siguiente correspondencia:

| Opción de Menú | Ícono FontAwesome | Tipo / Destino | Descripción |
| :--- | :--- | :--- | :--- |
| **Inicio** | `fa-home` | Página 1 (`HOGAR`) | Dashboard analítico institucional |
| **Alumnos** | `fa-users` | Página 21 | Reporte interactivo del padrón escolar |
| **Profesores** | `fa-graduation-cap` | Página 19 | Catálogo de la plantilla docente |
| **Materias** | `fa-book` | Página 15 | Catálogo de asignaturas y créditos |
| **Grupos** | `fa-cubes` | Página 25 | Asignación de grupos por ciclo |
| **Aulas** | `fa-door-open` | Página 13 | *Corrige el ícono erróneo `fa-alert`* |
| **Ciclos** | `fa-calendar` | Página 11 | Ciclos escolares y períodos vigentes |
| **Mapa de Alumnos** | `fa-map-marker` | Página 23 | Georreferenciación de estudiantes |
| **Captura de Calificaciones** | `fa-edit` | Página 28 | Interactive Grid de evaluación semestral |
| **Kardex** | `fa-file-text-o` | Página 30 | Historial y constancias académicas |
| **Estados** | `fa-map` | Página 9 | Entidades federativas |
| **Municipios** | `fa-building-o` | Página 17 | Municipios y localidades |
| **Administración** | `fa-user-wrench` | Página 10000 | Configuración interna |

---

### 2.2 Unificación de Títulos de Páginas y Formularios
Para mantener una jerarquía gramatical correcta, los listados de consulta van en **plural** y las pantallas de formulario DML van en **singular**:

* **Página 19:** `Profesores` (Listado)
* **Página 20:** `Profesor` (Formulario modal: Nombre, Apellidos, Dirección, Municipio, Correo, Teléfono)
* **Página 21:** `Alumnos` (Listado)
* **Página 22:** `Alumno` (Formulario modal: Matrícula, Nombre, CURP, Contacto, Estatus)
* **Página 23:** `Mapa de Alumnos`
* **Página 25:** `Grupos`
* **Página 27:** `Inscripciones`
* **Página 28:** `Captura de Calificaciones`
* **Página 30:** `Kardex del Alumno`

---

### 2.3 Página de Login Institucional (Página 9999)
Configuración de la pantalla de bienvenida y autenticación:
1. **Page Title:** `Sistema Escolar — Tecnológico de La Laguna`
2. **Region Name:** `Sistema Escolar — Tecnológico de La Laguna`
3. **Subtítulo institucional:** `Plataforma de Gestión y Analítica Académica`
4. **Campos del formulario:**
   - `P9999_USERNAME`: Etiqueta y placeholder: `Usuario`.
   - `P9999_PASSWORD`: Etiqueta y placeholder: `Contraseña`.
   - `P9999_REMEMBER`: Etiqueta: `Recordar usuario`.
   - Botón `LOGIN`: Etiqueta: `Iniciar Sesión` (Ícono: `fa-sign-in`).

---

### 2.4 Estandarización de Botones de Acción
Todas las páginas de formulario DML y reportes utilizan los verbos estándar en español:
* **Crear:** Para altas y nuevas inserciones (`p_button_name => 'CREATE'`, Etiqueta: `Crear`).
* **Guardar:** Para actualizaciones (`p_button_name => 'SAVE'`, Etiqueta: `Guardar`).
* **Cancelar:** Para cerrar modales sin guardar (`p_button_name => 'CANCEL'`, Etiqueta: `Cancelar`).
* **Eliminar:** Para bajas lógicas o físicas con confirmación (`p_button_name => 'DELETE'`, Etiqueta: `Eliminar`).

---

### 2.5 Reglas de Validación en Español
En los formularios de Alumnos (Página 22), Profesores (Página 20) y Captura de Calificaciones (Página 28), se crean las siguientes validaciones nativas de APEX:

#### 1. Validación de Formato Oficial de CURP (Página 22)
* **Name:** `VAL_CURP_FORMATO`
* **Type:** `Item matches Regular Expression`
* **Item:** `P22_CURP`
* **Regular Expression:** `^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]$`
* **Error Message:** `La CURP ingresada no cumple con la estructura oficial de 18 caracteres de la RENAPO.`

#### 2. Validación de Correo Electrónico Institucional Único (Página 22 y 20)
* **Name:** `VAL_ALUMNO_CORREO_UNICO`
* **Type:** `Rows returned does NOT exist`
* **SQL Query:**
```sql
SELECT 1 
FROM alumnos 
WHERE UPPER(mail) = UPPER(:P22_MAIL) 
  AND n_control != NVL(:P22_N_CONTROL, '0');
```
* **Error Message:** `El correo electrónico ya se encuentra registrado para otro estudiante.`

#### 3. Validación de Calificación en Rango Escolar 0 a 100 (Página 28)
* **Name:** `VAL_RANGO_CALIFICACION`
* **Type:** `Item in range`
* **Item:** `CALIFICACION`
* **Minimum Value:** `0`
* **Maximum Value:** `100`
* **Error Message:** `La calificación debe estar comprendida dentro de la escala oficial de 0.00 a 100.00.`

---

### 2.6 Configuración de Filtros en Cascada (Cascading LOV) Estado -> Municipio
Para evitar que un usuario seleccione un municipio que no corresponda al estado del alumno o profesor, se implementa una lista dependiente en cascada:

1. **Item de Estado (`P22_ID_ESTADO_NACIMIENTO`):**
   - **Type:** `Select List`
   - **List of Values > Type:** `SQL Query`
   - **Query:**
     ```sql
     SELECT nombre AS d, id_estado AS r 
     FROM estados 
     ORDER BY nombre;
     ```

2. **Item de Municipio (`P22_ID_MUNICIPIO`):**
   - **Type:** `Select List`
   - **Cascading LOV Parent Item(s):** `P22_ID_ESTADO_NACIMIENTO`
   - **Page Items to Submit:** `P22_ID_ESTADO_NACIMIENTO`
   - **List of Values > SQL Query:**
     ```sql
     SELECT nombre AS d, id_municipio AS r 
     FROM municipios 
     WHERE id_estado = :P22_ID_ESTADO_NACIMIENTO 
     ORDER BY nombre;
     ```
   - **Parent Required:** `Yes` (o deshabilitado hasta que se elija un estado).

---

### 2.7 Configuración del Tema Institucional en Theme Roller
Para dotar al sistema de la paleta oficial del **Tecnológico Nacional de México (TecNM)** y del **Instituto Tecnológico de La Laguna (ITL)** sin depender de reglas CSS sueltas:

1. Ejecuta la aplicación y abre la barra de desarrollador inferior de APEX.
2. Haz clic en **Theme Roller** (Paleta de colores).
3. Configura los siguientes parámetros oficiales:
   - **Header Accent:** `#0f172a` (Pizarra Oscuro Ejecutivo)
   - **Primary Accent:** `#1b365d` (Azul TecNM Oficial)
   - **Secondary Accent:** `#b8860b` (Dorado Tecnológico / Engrane ITL)
   - **Success Accent:** `#2f7d5b` (Verde Laguna)
   - **Body Background:** `#f8fafc` (Gris tenue institucional)
   - **Base Font Family:** `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`
   - **Container Border Radius:** `10px`
4. Haz clic en **Save As** con el nombre `Tec Laguna Theme` y luego en **Set as Current**.
