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

### 1.3 Región 1: Banner Hero Institucional con Identidad Oficial TecNM / ITL
Crea o edita la región superior del Dashboard aplicando la identidad visual institucional:
* **Title:** `Hero Institucional`
* **Type:** `Static Content`
* **Template:** `Blank with Attributes`
* **Color de Fondo:** Azul TecNM (`#1B3A6B`) con línea inferior dorada de 3px (`#C2A96F`)
* **Source (HTML):**
```html
<div class="sep-hero-banner">
  <div class="sep-hero-content">
    <h1 class="sep-hero-title">Sistema Escolar</h1>
    <div class="sep-hero-subtitle">Tecnológico de La Laguna</div>
  </div>
  <div class="sep-hero-logos">
    <img src="#APP_FILES#TecNMX-1024x324.png" alt="TecNM — Instituto Tecnológico de La Laguna" title="Tecnológico Nacional de México / Instituto Tecnológico de La Laguna" />
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
Configuración de la pantalla de bienvenida y autenticación bajo los estándares visuales del Tecnológico:
1. **Page Title:** `Sistema Escolar — Tecnológico de La Laguna`
2. **Region Name:** `Sistema Escolar — Tecnológico de La Laguna`
3. **Subtítulo institucional:** `Tecnológico de La Laguna`
4. **Fondo de la página:** Fondo claro `#F3F5F9`.
5. **Tarjeta de autenticación:** Tarjeta centrada en color blanco `#FFFFFF` con sombra suave.
6. **Logotipo:** Centrado, utilizando `#APP_FILES#TecNMX-1024x324.png` (`p_region_image`), con una franja dorada de 3px (`#C2A96F`) debajo del encabezado.
7. **Botón Iniciar Sesión (`LOGIN`):** Fondo en azul TecNM `#1B3A6B`, borde dorado `#C2A96F` y efecto hover en azul profundo `#12284A`.
8. **Campos del formulario:**
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

### 2.7 Configuración del Tema Institucional en Theme Roller y Tokens CSS

El sistema adopta íntegramente la paleta oficial del **Tecnológico de La Laguna (TecNM)** extraída del logotipo institucional (`static/TecNMX-1024x324.png`):

| Token Institucional | Valor Hex | Uso en la Aplicación |
| :--- | :--- | :--- |
| **Azul TecNM (primario)** | `#1B3A6B` | Encabezado superior, menú lateral, botones primarios, títulos y enlaces |
| **Azul profundo (hover/hero)** | `#12284A` | Fondo del hero banner, estado hover de botones y navegación activa |
| **Dorado Tec Laguna (acento)** | `#C2A96F` | Franja inferior del hero (3px), bordes de botones, acento en gráficas |
| **Dorado oscuro (hover acentos)** | `#A08A52` | Subtítulo en login, hover de acentos dorados, íconos de capacidad |
| **Dorado claro** | `#DFCE9F` | Subtítulo "Tecnológico de La Laguna" en el hero banner del home |
| **Carbón (texto)** | `#282828` | Tipografía principal y datos de lectura en tablas y formularios |
| **Fondo de página** | `#F3F5F9` | Fondo claro neutro en todo el sistema y en la pantalla de login |
| **Tarjetas y Contenedores** | `#FFFFFF` | Fondo de regiones, tarjetas de KPIs, módulos y modales |

#### Valores Exactos para Theme Roller (Captura en APEX):
1. Ejecuta la aplicación y abre la barra de desarrollador inferior de APEX.
2. Haz clic en **Theme Roller** (ícono de paleta de colores).
3. Captura los siguientes valores en los selectores correspondientes:
   - **Header / Menú:** `#1B3A6B`
   - **Primary Accent (Color Primary):** `#1B3A6B`
   - **Secondary Accent (Acentos):** `#C2A96F`
   - **Body Background:** `#F3F5F9`
   - **Card / Region Background:** `#FFFFFF`
   - **Text Primary (Carbón):** `#282828`
   - **Base Font Family:** `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`
   - **Container Border Radius:** `10px`
4. Haz clic en **Save As** con el nombre `Tec Laguna Oficial` y luego en **Set as Current**.

#### Variables CSS Definidas en `static/app.css` (`:root`):
```css
:root {
  --tec-azul: #1B3A6B;          /* Azul TecNM primario */
  --tec-azul-oscuro: #12284A;   /* Azul profundo hover / hero */
  --tec-dorado: #C2A96F;        /* Dorado Tec Laguna acento */
  --tec-dorado-oscuro: #A08A52; /* Dorado oscuro hover */
  --tec-dorado-claro: #DFCE9F;  /* Dorado tenue subtítulos */
  --tec-carbon: #282828;        /* Color principal de texto */
  --tec-fondo: #F3F5F9;         /* Fondo neutro del sistema */
  --tec-tarjeta: #FFFFFF;       /* Fondo de tarjetas */

  /* Serie Cromática de Azules y Dorado para Gráficas */
  --chart-blue-1: #1B3A6B;      /* Azul principal */
  --chart-blue-2: #3F5F92;      /* Azul medio */
  --chart-blue-3: #7C93B8;      /* Azul suave */
  --chart-blue-4: #B7C3D8;      /* Azul claro */
  --chart-gold: #C2A96F;        /* Dorado para resaltar el dato principal */
}
```

---

### 2.8 Carga del Logotipo Institucional y Configuración de Barra Superior

El logotipo oficial [`static/TecNMX-1024x324.png`](file:///C:/Users/isael/.gemini/antigravity/scratch/sistema-escolar-apex/static/TecNMX-1024x324.png) unifica el escudo del ITL y el emblema nacional del TecNM:

#### Paso 1: Subida del Archivo a Static Application Files
1. En APEX App Builder, ingresa a la aplicación **107**.
2. Ve a **Shared Components** > **Static Application Files** (Archivos de aplicación estáticos).
3. Haz clic en **Create File** (o **Upload File**).
4. Selecciona el archivo `static/TecNMX-1024x324.png` desde tu equipo local.
5. Haz clic en **Upload**.
6. Verifica que la referencia quede registrada como: `#APP_FILES#TecNMX-1024x324.png`.

#### Paso 2: Configuración del Application Logo en la Barra Superior
1. Ve a **Shared Components** > **User Interface Attributes** (Atributos de interfaz de usuario).
2. En la pestaña **User Interface**, ubica la sección **Logo**.
3. Configura:
   - **Logo Type:** `Image`
   - **Image URL:** `#APP_FILES#TecNMX-1024x324.png`
   - **Logo Alt Text:** `Tecnológico de La Laguna — TecNM`
   - **Logo Attributes:** `style="max-height: 38px; width: auto;"`
4. Haz clic en **Apply Changes**.


---

# Fase 3: Funcionalidad de Sistema Real

En esta fase se incorporan herramientas de valor institucional indispensables para la gestión escolar: Kardex oficial imprimible en PDF, boleta de calificaciones por ciclo, listas de asistencia para docentes, buscador global, semáforo de riesgo académico y auditoría transaccional con triggers.

### 3.1 Kardex Estudiantil Imprimible en PDF (Página 30)
Para que el reporte de Kardex cumpla con el estándar oficial de una constancia académica:

1. **Ejecución del Script de Reportes:**
   - En **SQL Workshop** > **SQL Scripts**, sube y ejecuta [`db/reportes_academicos.sql`](file:///C:/Users/isael/.gemini/antigravity/scratch/sistema-escolar-apex/db/reportes_academicos.sql).
2. **Encabezado Institucional del Kardex (Región Static Content):**
   - Agrega en la parte superior de la Página 30 una región con template `Blank with Attributes` y el siguiente HTML:
     ```html
     <div class="kardex-print-header">
       <div class="kardex-logos">
         <img src="https://tl-mexico.org/wp-content/uploads/2021/04/logo-tecnm.png" alt="TecNM" style="height: 48px;" />
         <img src="https://itlaguna.edu.mx/wp-content/uploads/2020/09/LOGOTIPO-ITL-OFICIAL-PNG.png" alt="ITL" style="height: 48px;" />
       </div>
       <div class="kardex-meta-institucional">
         <h2>TECNOLÓGICO NACIONAL DE MÉXICO</h2>
         <h3>INSTITUTO TECNOLÓGICO DE LA LAGUNA</h3>
         <p>DEPARTAMENTO DE SERVICIOS ESCOLARES • HISTORIAL ACADÉMICO OFICIAL</p>
       </div>
     </div>
     ```
3. **Resumen del Alumno (Región Cards o Badge List):**
   - **Source:**
     ```sql
     SELECT 
         n_control,
         alumno,
         curp,
         promedio_general,
         creditos_acumulados,
         creditos_totales_cursados,
         avance_porcentaje
     FROM v_rep_kardex_alumno
     WHERE n_control = :P30_N_CONTROL
       AND ROWNUM = 1;
     ```
4. **Detalle de Asignaturas Cursadas (Interactive Report o Classic Report):**
   - **Source:**
     ```sql
     SELECT 
         ciclo AS "Ciclo Escolar",
         clave_materia AS "Clave",
         materia AS "Asignatura",
         creditos_materia AS "Créditos",
         grupo AS "Grupo",
         profesor AS "Catedrático",
         calificacion AS "Calificación",
         estatus_materia AS "Acreditación"
     FROM v_rep_kardex_alumno
     WHERE n_control = :P30_N_CONTROL
     ORDER BY fecha_ini_ciclo ASC, clave_materia ASC;
     ```
5. **Botón de Impresión en PDF:**
   - **Button Name:** `BTN_IMPRIMIR_KARDEX`
   - **Label:** `Imprimir / Guardar en PDF`
   - **Icon:** `fa-print`
   - **Action:** `Defined by Dynamic Action` -> `Execute JavaScript Code`:
     ```javascript
     window.print();
     ```
   *(La hoja de estilo `static/app.css` oculta menús, botones de APEX y barras de herramientas al mandar a imprimir o guardar como PDF).*

---

### 3.2 Boleta de Evaluación Semestral por Alumno y Ciclo
Permite emitir la boleta de calificaciones de un período semestral específico:
1. Crea una región de reporte con la vista `v_rep_boleta_ciclo`.
2. **SQL Query:**
   ```sql
   SELECT 
       clave_materia AS "Clave",
       materia AS "Asignatura",
       creditos AS "Créditos",
       grupo AS "Grupo",
       profesor AS "Profesor",
       calificacion AS "Calificación Final",
       resultado AS "Resultado"
   FROM v_rep_boleta_ciclo
   WHERE n_control = :P31_N_CONTROL
     AND id_ciclo = :P31_ID_CICLO;
   ```
3. Muestra en el pie de página el `promedio_ciclo` y los `creditos_aprobados_ciclo` calculados analíticamente en la vista.

---

### 3.3 Lista de Asistencia por Grupo (Imprimible o Exportable a Excel)
1. En la página de detalle de un grupo (o un modal auxiliar):
2. **Type:** `Interactive Report`
3. **Source:**
   ```sql
   SELECT 
       numero_lista AS "#",
       n_control AS "No. Control",
       alumno_nombre_completo AS "Nombre del Estudiante",
       mail AS "Correo Institucional",
       telefono AS "Teléfono",
       ' ' AS "Firma / Asistencia"
   FROM v_rep_lista_asistencia
   WHERE id_grupo = :P25_ID_GRUPO
   ORDER BY numero_lista ASC;
   ```
4. En **Attributes** > **Download**, habilita los formatos **PDF** y **XLSX**.

---

### 3.4 Búsqueda Global en la Barra Superior (Page 0)
Para buscar alumnos rápidamente desde cualquier lugar de la aplicación sin abrir primero la tabla de Alumnos:
1. En **Page 0 (Global Page)**, agrega una región de búsqueda en la posición `After Navigation Bar` o `Menu Bar`.
2. Crea el item: `P0_BUSQUEDA_GLOBAL`.
   - **Type:** `Text Field with Autocomplete` (o Text Field normal con botón Buscar).
   - **Icon:** `fa-search`.
   - **Placeholder:** `Buscar alumno por nombre, matrícula o CURP...`.
3. Crea una Rama (Branch) o Acción Dinámica que al presionar Enter redirija a la Página 21 (`ALUMNOS`) pasando el valor a un filtro de búsqueda:
   ```sql
   SELECT n_control, alumno, curp, promedio_general, estatus
   FROM v_busqueda_global_alumnos
   WHERE texto_busqueda LIKE '%' || UPPER(TRIM(:P0_BUSQUEDA_GLOBAL)) || '%';
   ```

---

### 3.5 Semáforo de Riesgo Académico
Para que los coordinadores identifiquen a los alumnos que requieren tutoría o intervención inmediata:
1. **Regla de Clasificación Automática (definida en `v_alumnos_semaforo_riesgo`):**
   - **Rojo (Riesgo Alto):** Alumnos con promedio general menor a 70.0, estatus inactivo o con 2 o más materias reprobadas.
   - **Amarillo (Riesgo Medio):** Alumnos con promedio entre 70.0 y 79.99 (rendimiento en observación).
   - **Verde (Riesgo Bajo):** Alumnos al corriente con promedio superior o igual a 80.0.
2. **Visualización en Reportes:**
   En el Interactive Report de Alumnos (Página 21), agrega la columna `SEMAFORO_HTML` con la opción **Escape special characters** en `No` para renderizar el badge de alerta.

---

### 3.6 Auditoría y Trazabilidad Transaccional
Para cumplir con los más altos estándares de control y auditoría en sistemas de información escolar:

1. **Ejecución del Script de Auditoría:**
   - En **SQL Workshop** > **SQL Scripts**, sube y ejecuta [`db/auditoria.sql`](file:///C:/Users/isael/.gemini/antigravity/scratch/sistema-escolar-apex/db/auditoria.sql).
2. **Columnas de Autoría Automática:**
   Las tablas `alumnos`, `profesores`, `calificaciones`, `grupos`, `materias`, `aulas` y `ciclos` cuentan con:
   - `creado_por`: Usuario de APEX que creó el registro.
   - `fecha_creacion`: Fecha y hora de alta en el sistema.
   - `modificado_por`: Último usuario que modificó el registro.
   - `fecha_modificacion`: Fecha y hora de la última modificación.
3. **Bitácora de Modificaciones a Calificaciones:**
   - Cualquier inserción, cambio de nota o eliminación en la tabla `calificaciones` es interceptado automáticamente por el trigger `trg_bitacora_calificaciones`.
   - Se almacena el usuario de APEX, la dirección IP, la fecha/hora exacta, la calificación previa y la calificación nueva.
4. **Reporte de Bitácora para Supervisión:**
   Crea una página o pestaña tipo **Interactive Report** para consulta administrativa:
   ```sql
   SELECT 
       fecha_registro AS "Fecha",
       operacion_badge_html AS "Operación",
       usuario AS "Usuario Responsable",
       n_control AS "No. Control",
       alumno AS "Estudiante",
       clave_materia || ' - ' || materia AS "Asignatura",
       grupo AS "Grupo",
       calificacion_anterior AS "Calificación Anterior",
       calificacion_nueva AS "Calificación Nueva",
       ip_origen AS "IP de Conexión"
   FROM v_bitacora_calificaciones;
   ```


---

# Fase 4: Rendimiento, Optimización y Mantenimiento

En esta fase se abordan el rendimiento de la aplicación al manejar más de 600 registros de alumnos, la optimización del mapa geográfico y el diagnóstico de páginas de administración internas.

### 4.1 Paginación y Optimización de Consultas (Página 21 - Alumnos)
Dado que el padrón supera los 600 registros y seguirá creciendo:
1. **Interactive Report / Grid de Alumnos (Página 21):**
   - En **Attributes** > **Pagination**:
     - **Type:** `Row Range X to Y of Z (with pagination)`
     - **Rows Per Page:** `25` o `50` (evita cargar los 600+ registros de golpe en el DOM del navegador).
   - En **Filtros por Defecto (Default Report Settings):**
     - Guarda como reporte primario un filtro con `Activo = 'S'` para que al abrir la pantalla solo consulte a los estudiantes vigentes, reduciendo el volumen inicial de datos.

---

### 4.2 Optimización del Mapa Georreferenciado (Página 23)
1. Para el componente **Map** de APEX:
   - Limita los puntos iniciales a alumnos activos con coordenadas válidas:
     ```sql
     SELECT 
         n_control,
         nombre || ' ' || apellidos AS alumno,
         direccion,
         latitud,
         longitud
     FROM alumnos
     WHERE latitud IS NOT NULL 
       AND longitud IS NOT NULL
       AND activo = 'S';
     ```
   - Habilita la opción **Clustering** (Agrupación por proximidad) en los atributos de la capa del mapa. Esto reduce el cálculo de renderizado de 600 marcadores individuales a unos pocos clústeres regionales en La Laguna (Torreón, Gómez Palacio, Lerdo).

---

### 4.3 Diagnóstico y Propuesta sobre Páginas de Administración (10010 a 10014)
APEX genera automáticamente un conjunto de páginas técnicas para la gestión de control de acceso:

| ID Página | Nombre de la Página | Tipo | Propósito |
| :--- | :--- | :--- | :--- |
| **10000** | Administration | Normal | Panel de control administrativo interno |
| **10010** | Configure Access Control | Modal | Habilitar o deshabilitar esquemas de autorización |
| **10011** | Manage User Access | Normal | Reporte interactivo de usuarios y roles asignados |
| **10012** | Manage User Access | Modal | Formulario DML para asignar roles a un usuario |
| **10013** | Add Multiple Users - Step 1 | Modal | Asistente (paso 1) para dar de alta usuarios en lote |
| **10014** | Add Multiple Users - Step 2 | Modal | Asistente (paso 2) para confirmar roles en lote |

#### Dictamen Técnico y Recomendación:
> [!IMPORTANT]
> **NO BORRAR ESTAS PÁGINAS.**  
> Borrar las páginas 10010 a 10014 puede generar referencias rotas en los metadatos de APEX si en el futuro se desea habilitar seguridad por roles.  
> **Recomendación idónea:**
> 1. En **Shared Components** > **Lists** > **Navigation Menu**, retira o desvincula la opción `ADMINISTRATION` del menú lateral para que los maestros o usuarios comunes no la vean.
> 2. Mantén las páginas en la aplicación intactas, accesibles únicamente para el desarrollador ingresando `10000` directamente en la URL.

---

# Checklist Resumen para el Administrador

Sigue este orden exacto en Oracle APEX para dejar tu aplicación lista al 100%:

### 1. En SQL Workshop > SQL Scripts
- [ ] Ejecutar [`db/dashboard_vistas.sql`](file:///C:/Users/isael/.gemini/antigravity/scratch/sistema-escolar-apex/db/dashboard_vistas.sql) (Crea las 22 vistas analíticas de KPIs y gráficas).
- [ ] Ejecutar [`db/reportes_academicos.sql`](file:///C:/Users/isael/.gemini/antigravity/scratch/sistema-escolar-apex/db/reportes_academicos.sql) (Crea las vistas para Kardex, Boletas, Asistencia, Búsqueda y Semáforo de Riesgo).
- [ ] Ejecutar [`db/auditoria.sql`](file:///C:/Users/isael/.gemini/antigravity/scratch/sistema-escolar-apex/db/auditoria.sql) (Agrega columnas de autoría, triggers automáticos y bitácora de calificaciones).

### 2. En Shared Components > Static Application Files
- [ ] Subir [`static/dashboard.css`](file:///C:/Users/isael/.gemini/antigravity/scratch/sistema-escolar-apex/static/dashboard.css).
- [ ] Subir [`static/app.css`](file:///C:/Users/isael/.gemini/antigravity/scratch/sistema-escolar-apex/static/app.css).

### 3. En Propiedades de la Aplicación (User Interface)
- [ ] En **CSS File URLs**, incluir:
  ```text
  #APP_FILES#app.css
  ```
- [ ] En **Page 1 (Hogar)** > CSS File URLs, incluir:
  ```text
  #APP_FILES#dashboard.css
  ```
- [ ] En **Theme Roller**, aplicar los colores institucionales: `#0f172a` (Header), `#1b365d` (Primario), `#b8860b` (Secundario/Oro), `#2f7d5b` (Éxito).

### 4. En App Builder (Páginas Clave)
- [ ] **Página 1 (Dashboard):** Reemplazar el código de prueba por las regiones de Cards y Charts conectadas a las vistas de `db/dashboard_vistas.sql` (Ver instrucciones detalladas en la Fase 1).
- [ ] **Página 22 (Alumno):** Configurar la lista en cascada `P22_ID_ESTADO_NACIMIENTO` -> `P22_ID_MUNICIPIO` (Ver Fase 2).
- [ ] **Página 28 (Calificaciones):** Agregar la validación de rango 0 a 100.
- [ ] **Página 30 (Kardex):** Integrar el botón con `window.print()` y encabezado con logos.
