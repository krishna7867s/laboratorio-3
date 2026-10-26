

# Laboratorio #3: Sistema de Inventario Aduanero
## Base de Datos Relacional y Agente de Inteligencia Artificial con n8n

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![n8n](https://img.shields.io/badge/n8n-LangChain%20Agent-EA4B71?logo=n8n&logoColor=white)](https://n8n.io/)
[![GitHub](https://img.shields.io/badge/GitHub-Repo-181717?logo=github&logoColor=white)](https://github.com/krishna7867s/laboratorio-3)

---

### Resumen del Proyecto y Caso de Negocio
Este repositorio contiene la solución completa e integral del **Laboratorio #3 de Bases de Datos**. El proyecto reemplaza el manejo disperso e ineficiente de hojas de cálculo en la aduana nacional por un sistema de información relacional robusto, normalizado en **Tercera Forma Normal (3FN)** con 13 entidades interconectadas, poblado con datos coherentes y fiscalizado mediante un **Agente Autónomo de Inteligencia Artificial en n8n** bajo el principio de menor privilegio (solo lectura).

---

## 📁 Entregables Oficiales para Google Classroom

| # | Entregable | Archivo en Repositorio | Formato | Descripción |
|---|---|---|---|---|
| **1** | **Documento de Investigación** (incluye apartado "Uso de IA") | [`Apellido_Nombre_Investigacion_Lab3.pdf`](./Apellido_Nombre_Investigacion_Lab3.pdf) | PDF (6 páginas) | Cubre exhaustivamente las secciones A, B, C, D, uso de IA y bibliografía académica. |
| **2** | **Diagrama Entidad-Relación** | [`Apellido_Nombre_DER_Lab3.png`](./Apellido_Nombre_DER_Lab3.png) / [`Apellido_Nombre_DER_Lab3.pdf`](./Apellido_Nombre_DER_Lab3.pdf) | PNG / PDF | 13 entidades con PK, FK, relación N:M resuelta, relación recursiva y cardinalidades. |
| **3** | **Script SQL Completo** | [`Apellido_Nombre_Aduana_Lab3.sql`](./Apellido_Nombre_Aduana_Lab3.sql) | `.sql` | Tablas DDL, restricciones (CHECK, UNIQUE), 16+ registros por tabla, 8 consultas analíticas y rol `n8n_readonly`. |
| **4** | **Flujo n8n Exportado** | [`Apellido_Nombre_Agente_Lab3.json`](./Apellido_Nombre_Agente_Lab3.json) | `.json` | Workflow oficial con Chat Trigger, ReAct AI Agent, Memoria de contexto y Postgres Tool con System Prompt defensivo. |
| **5** | **Evidencia del Agente** | [`Apellido_Nombre_Evidencia_Lab3.pdf`](./Apellido_Nombre_Evidencia_Lab3.pdf) / [`Apellido_Nombre_Evidencia_Lab3.png`](./Apellido_Nombre_Evidencia_Lab3.png) | PDF / PNG | 8 pruebas documentadas con razonamiento, sentencia SQL y respuesta en lenguaje natural. |
| **⭐** | **Puntos Extra (+5 pts)** | [`dashboard_aduana.html`](./dashboard_aduana.html) | HTML5 / JS | Dashboard interactivo con indicadores de inventario y chat web en vivo con el Agente de IA. |

---

## 🛠️ Arquitectura y Modelo de Datos (13 Entidades)

1. `pais`: Catálogo internacional según estándar ISO 3166-1.
2. `importador_exportador`: Registro de operadores aduaneros con calificación de riesgo fiscal.
3. `agente_aduanal`: Despachantes autorizados por el ministerio con licencias vigentes.
4. `categoria_arancelaria`: Partidas arancelarias según el Sistema Armonizado (SA) de la OMA.
5. `producto`: Catálogo de mercancías con SKU, unidad física y valor FOB de referencia.
6. `declaracion_aduanera`: DUA oficial con régimen (importación, exportación, tránsito, depósito) y canal de aforo.
7. `detalle_declaracion`: **Tabla intermedia N:M** entre DUA y Producto, con valor FOB, seguros y aranceles calculados.
8. `contenedor`: Unidades intermodales según norma ISO 6346 (MSKU, CMAU, COSU) asociadas al DUA (1:N).
9. `bodega`: Depósitos fiscales, almacenes refrigerados y bodegas de custodia/retención.
10. `inventario`: Stock fiscal en bodega por lote/DUA, ubicación en rack y estado (Retenido, Liberado, Decomisado).
11. `movimiento_inventario`: Kardex de trazabilidad de ingresos, traslados internos y salidas por levante.
12. `funcionario`: Personal aduanero con **relación jerárquica recursiva** (`id_supervisor` &rarr; `id_funcionario`).
13. `inspeccion`: Actas de fiscalización documental y aforo físico con observaciones técnicas.

---

## 🚀 Guía de Despliegue y Ejecución

### 1. Ejecutar el Script SQL en PostgreSQL
```bash
# Conectarse a PostgreSQL y crear la base de datos
psql -U postgres -c "CREATE DATABASE aduana_lab3;"

# Ejecutar el script completo
psql -U postgres -d aduana_lab3 -f Apellido_Nombre_Aduana_Lab3.sql
```

### 2. Configurar el Usuario de Solo Lectura en PostgreSQL
El script crea automáticamente el rol para el agente de IA:
```sql
CREATE ROLE n8n_readonly WITH LOGIN PASSWORD 'AduanaSegura2026!';
GRANT CONNECT ON DATABASE aduana_lab3 TO n8n_readonly;
GRANT USAGE ON SCHEMA public TO n8n_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO n8n_readonly;
```

### 3. Importar el Flujo en n8n
1. Abra su instancia de **n8n** (en nube o local vía `npx n8n` / Docker).
2. Cree un nuevo flujo y en el menú contextual superior elija **Import from File...**
3. Seleccione el archivo [`Apellido_Nombre_Agente_Lab3.json`](./Apellido_Nombre_Agente_Lab3.json).
4. Configure sus credenciales para el modelo (OpenAI o Gemini) y la conexión de PostgreSQL con el usuario `n8n_readonly`.
5. ¡Haga clic en **Chat** para comenzar a interactuar en lenguaje natural con su inventario!

### 4. Abrir el Dashboard Interactivo (Puntos Extra)
Simplemente haga doble clic en [`dashboard_aduana.html`](./dashboard_aduana.html) para abrir en cualquier navegador web la interfaz completa con métricas e interacciones del agente.
