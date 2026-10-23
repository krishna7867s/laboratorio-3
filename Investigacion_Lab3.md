# LABORATORIO #3: SISTEMA DE INVENTARIO ADUANERO
## Base de Datos Relacional y Agente de Inteligencia Artificial con n8n

* **Asignatura:** Bases de Datos
* **Estudiante:** Krishna Moya Cervantes
* **Fecha:** Octubre 2026
* **Modalidad:** Individual
* **Entrega:** Google Classroom
* **Repositorio de Código:** https://github.com/krishna7867s/laboratorio-3

---

# PARTE I: INVESTIGACIÓN TEÓRICA Y CONCEPTUAL

## A. BASES DE DATOS Y SQL

### 1. ¿Qué es una base de datos? ¿Qué es un Sistema Gestor de Bases de Datos (SGBD)?

Una **base de datos** es un conjunto organizado, estructurado y persistente de datos que pertenecen a un mismo contexto y que se almacenan de forma digital para su posterior recuperación, análisis y actualización. En el caso de una aduana, la base de datos almacena el registro histórico de los cargamentos que ingresan al país, las empresas importadoras, los aranceles cancelados y el inventario en bodegas.

Por su parte, un **Sistema Gestor de Bases de Datos (SGBD o DBMS por sus siglas en inglés)** es el software intermediario que permite a los usuarios, administradores y aplicaciones definir, crear, consultar y mantener controlada dicha base de datos. El SGBD se encarga de la seguridad, el control de concurrencia (cuando varios inspectores consultan a la vez) y de garantizar las propiedades **ACID**:
* **Atomicidad:** Una transacción se completa totalmente o se revierte por completo (ejemplo: si se autoriza el levante de una mercancía, se debe descontar del inventario y registrar la salida; si algo falla, no se aplica ningún cambio a medias).
* **Consistencia:** Toda operación respeta las reglas e integridad de la base de datos (por ejemplo, no se puede cobrar un arancel con valor negativo).
* **Aislamiento:** Las transacciones simultáneas se ejecutan sin interferir entre sí.
* **Durabilidad:** Una vez que un registro se guarda exitosamente, los datos permanecen seguros incluso si el servidor se apaga repentinamente.

---

### 2. Diferencias entre base de datos relacional (SQL) y no relacional (NoSQL)

| Criterio | Base de Datos Relacional (SQL) | Base de Datos No Relacional (NoSQL) |
| :--- | :--- | :--- |
| **Estructura** | Tablas bidimensionales rígidas con filas y columnas prefijadas. | Colecciones de documentos (JSON), pares clave-valor, columnas anchas o grafos. |
| **Esquema** | Estricto (*Schema-on-write*). Las tablas deben definirse antes de guardar datos. | Dinámico y flexible (*Schema-on-read*). Permite que cada registro tenga campos distintos. |
| **Lenguaje** | SQL (Structured Query Language) estandarizado. | APIs específicas de cada motor o sintaxis propia (como MQL en MongoDB). |
| **Consistencia** | Prioriza la consistencia inmediata y transacciones ACID estrictas. | Prioriza la disponibilidad y la tolerancia a particiones (Teorema CAP / modelo BASE). |
| **Aplicación en Aduanas** | **Ideal para el inventario aduanero, DUA y cobro de aranceles**, donde no se toleran descuadres contables ni datos huérfanos. | Útil para telemetría de sensores IoT en contenedores refrigerados o bitácoras masivas de escaneo. |

---

### 3. Tabla, registro (fila), campo (columna) y tipos de datos más comunes

* **Tabla:** Es la estructura fundamental donde se organizan los datos de una misma entidad. En nuestro sistema aduanero, tenemos tablas como `declaracion_aduanera`, `producto`, `bodega` y `contenedor`.
* **Registro (o Fila / Tupla):** Representa una instancia u ocurrencia individual dentro de la tabla. Por ejemplo, una fila específica de la tabla `contenedor` contiene los datos del contenedor `MSKU2948102` con un peso bruto de 18,450 kg.
* **Campo (o Columna / Atributo):** Es la característica elemental que define una propiedad del registro. Por ejemplo, en la tabla `pais`, los campos son `nombre`, `codigo_iso` y `continente`.
* **Tipos de datos más comunes:**
  * `INTEGER / SERIAL`: Números enteros e identificadores autoincrementales (`id_declaracion`).
  * `VARCHAR(n)`: Cadenas de texto de longitud variable (`numero_dua VARCHAR(30)`).
  * `DECIMAL(p,s) / NUMERIC`: Números con decimales exactos, indispensables en finanzas para evitar errores de redondeo de punto flotante (`valor_total_fob DECIMAL(14,2)`).
  * `DATE / TIMESTAMP`: Fechas y marcas de tiempo exactas para controlar el aforo aduanero (`fecha_inspeccion TIMESTAMP`).
  * `BOOLEAN`: Valores de verdadero o falso (`temperatura_controlada BOOLEAN`).

---

### 4. Llave primaria (PK), llave foránea (FK) y llave compuesta

* **Llave Primaria (Primary Key - PK):** Es el campo (o conjunto de campos) que identifica de manera única e irrepetible a cada fila de una tabla. No admite valores nulos (`NOT NULL`) y no se puede duplicar. Ejemplo: `id_pais` en la tabla `pais` o `id_declaracion` en `declaracion_aduanera`.
* **Llave Foránea (Foreign Key - FK):** Es un campo en una tabla que hace referencia obligatoria a la llave primaria de otra tabla. Permite conectar las entidades y garantiza la integridad referencial. Ejemplo: En la tabla `declaracion_aduanera`, el campo `id_pais_origen` es una llave foránea que apunta al `id_pais` de la tabla `pais`.
* **Llave Compuesta:** Es una llave primaria constituida por dos o más columnas combinadas. Se utiliza habitualmente en tablas intermedias o para garantizar unicidad compuesta. Ejemplo: En el inventario de una bodega, la combinación `(id_bodega, id_producto, id_declaracion, ubicacion_pasillo_rack)` asegura que no existan dos registros idénticos en el mismo estante físico.

---

### 5. Tipos de relaciones: 1:1, 1:N, N:M y Relación Recursiva

* **Uno a Uno (1:1):** Un registro de la Tabla A se relaciona con un único registro de la Tabla B. Se implementa colocando la PK de una como FK en la otra con una restricción `UNIQUE`. Ejemplo: Cada contenedor fiscalizado puede tener asignado un único precinto satelital de seguridad activo.
* **Uno a Muchos (1:N):** Un registro de la Tabla A se relaciona con muchos registros de la Tabla B, pero cada registro de B pertenece a uno solo de A. Se implementa colocando la PK de la tabla padre como FK en la tabla hija. Ejemplo: Un país exportador da origen a muchas declaraciones aduaneras (`pais` 1 &rarr; N `declaracion_aduanera`).
* **Muchos a Muchos (N:M):** Un registro de A se relaciona con varios de B, y viceversa. En bases de datos relacionales no se puede conectar directamente; **se resuelve creando una tabla intermedia (asociativa)** con las dos llaves foráneas. Ejemplo: Una declaración aduanera contiene varios productos, y un mismo producto comercial aparece en muchas declaraciones. Esto se resuelve con la tabla intermedia `detalle_declaracion`, la cual incluye campos propios como `cantidad`, `valor_unitario_usd` y `arancel_aplicado_usd`.
* **Relación Recursiva (Autorreferencial):** Una entidad se relaciona consigo misma mediante una llave foránea interna. Ejemplo: En la tabla `funcionario`, el campo `id_supervisor` apunta al `id_funcionario` de otro empleado dentro de la misma tabla, permitiendo modelar la jerarquía de mando (Inspectores &rarr; Supervisores &rarr; Director General).

---

### 6. Integridad referencial y restricciones (Constraints)

La **integridad referencial** es la regla fundamental que asegura que ninguna llave foránea apunte a un registro inexistente en la tabla padre. Las restricciones más importantes son:
* `NOT NULL`: Exige que el campo siempre tenga un valor obligatorio (ejemplo: un contenedor no puede carecer de número de identificación).
* `UNIQUE`: Impide que existan dos valores idénticos en la columna (ejemplo: el código ISO de un país o el número de DUA).
* `CHECK`: Obliga a que el dato cumpla una condición lógica (ejemplo: `CHECK (porcentaje_arancel >= 0 AND porcentaje_arancel <= 100)` o validar que el régimen pertenezca a una lista permitida).
* `DEFAULT`: Asigna un valor predeterminado si el usuario no ingresa ninguno (ejemplo: `DEFAULT 'Retenida'` para el estado inicial de una mercancía).
* **Políticas de eliminación:**
  * `ON DELETE RESTRICT`: Impide borrar un país o un producto si ya tiene declaraciones asociadas.
  * `ON DELETE CASCADE`: Si se elimina una declaración en una auditoría, se eliminan automáticamente sus líneas hijas de detalle.

---

### 7. DDL y DML: Sentencias fundamentales de SQL

* **DDL (Data Definition Language - Lenguaje de Definición de Datos):** Permite crear, modificar y estructurar los objetos de la base de datos:
  * `CREATE TABLE`: Define una nueva tabla con sus columnas, tipos de datos y restricciones.
  * `ALTER TABLE`: Agrega columnas, cambia tipos de datos o añade nuevas restricciones.
  * `DROP TABLE`: Elimina por completo una tabla y sus datos del esquema.
* **DML (Data Manipulation Language - Lenguaje de Manipulación de Datos):** Permite operar y consultar los registros dentro de las tablas:
  * `INSERT INTO`: Inserta nuevas filas de mercancías o declaraciones.
  * `SELECT`: Consulta, proyecta y filtra datos de una o más tablas.
  * `UPDATE`: Modifica valores existentes (ejemplo: cambiar el estado de una mercancía de `'Retenido'` a `'Liberado'`).
  * `DELETE`: Elimina registros específicos bajo una condición dada.
  * `JOIN`: Permite combinar registros de dos o más tablas en base a una columna común.
    * `INNER JOIN`: Devuelve solo las filas que tienen coincidencia exacta en ambas tablas.
    * `LEFT JOIN`: Devuelve todas las filas de la tabla izquierda y las coincidencias de la derecha (útil para ver todos los funcionarios, incluso si no tienen supervisor asignado).

---

### 8. Normalización de bases de datos: 1FN, 2FN y 3FN

La normalización es el proceso formal de diseño que busca eliminar la redundancia de datos y prevenir anomalías al insertar, actualizar o eliminar información.

* **Primera Forma Normal (1FN):**
  * Todos los atributos deben ser atómicos (indivisibles).
  * No deben existir grupos repetitivos ni listas separadas por comas dentro de una misma celda.
  * *Ejemplo aduanero:* En lugar de guardar en un solo campo `mercancias = "Laptops, Celulares, Pantallas"`, se descompone en filas individuales dentro de una tabla de detalle con su clave única.
* **Segunda Forma Normal (2FN):**
  * Debe cumplir la 1FN.
  * Todos los atributos no clave deben depender por completo de la llave primaria completa (no de una parte de una clave compuesta).
  * *Ejemplo aduanero:* En la tabla de `detalle_declaracion` (cuya clave lógica es DUA + Producto), los datos de la bodega o del importador no dependen de esa combinación de productos, por lo que deben residir en sus propias tablas independientes (`bodega` e `importador_exportador`).
* **Tercera Forma Normal (3FN):**
  * Debe cumplir la 2FN.
  * No deben existir dependencias transitivas (un campo no clave no puede depender de otro campo no clave).
  * *Ejemplo aduanero:* Si en la tabla de productos guardáramos el nombre de la categoría arancelaria y el porcentaje de arancel, estos dependerían del código de partida, no directamente del producto. Al separar `categoria_arancelaria` como tabla maestra e invocarla por `id_categoria`, alcanzamos la 3FN pura.

---

### 9. Diagrama Entidad-Relación (DER) y Notaciones Chen vs Pata de Gallo

El **Diagrama Entidad-Relación (DER)** es la representación visual de la estructura lógica de la base de datos:
* **Notación de Chen (1976):** Representa las entidades en rectángulos, las relaciones en rombos con verbos descriptivos y los atributos en óvalos conectados con líneas. Utiliza etiquetas numéricas como `(1,1)`, `(1,N)` o `(N,M)` para la cardinalidad. Es muy pedagógica a nivel conceptual.
* **Notación Pata de Gallo (Crow's Foot):** Es la notación moderna estándar en la industria y en herramientas como draw.io, dbdiagram.io y MySQL Workbench. Muestra las entidades como rectángulos divididos en secciones (encabezado de PKs y lista de atributos con sus tipos). Las relaciones se expresan mediante líneas con símbolos en los extremos:
  * Una barra transversal indica obligatoriedad (1).
  * Un círculo indica opcionalidad (0).
  * Tres líneas divergentes con forma de pata de ave representan "muchos" (&infin;).
  * Es la notación utilizada en nuestro proyecto por su correspondencia exacta con las tablas del script SQL.

---

## B. COMPARACIÓN Y JUSTIFICACIÓN DE GESTORES DE BASES DE DATOS

### Cuadro Comparativo de Gestores

| Criterio | SQLite | MySQL (InnoDB) | PostgreSQL 16 |
| :--- | :--- | :--- | :--- |
| **Arquitectura** | Base de datos embebida en un único archivo en disco. Sin proceso servidor. | Servidor de base de datos multihilo tradicional. | Servidor multiproceso robusto, modular y altamente extensible. |
| **Instalación y Uso** | Extremadamente sencilla (cero configuración). | Media (requiere XAMPP, Docker o instalador con servicio). | Media (disponible local o en servicios cloud gratuitos como Neon y Supabase). |
| **Tipado de Datos** | Tipado afín / dinámico (permite almacenar texto en campos enteros). | Tipado estático con conversiones permisivas según el modo configurado. | **Tipado estricto y riguroso.** No permite ambigüedades numéricas. |
| **Concurrencia** | Bloqueo de archivo completo al escribir. No apto para múltiples usuarios. | Bloqueo a nivel de fila mediante InnoDB. | **MVCC (Multi-Version Concurrency Control)** avanzado sin bloqueos entre lecturas y escrituras. |
| **Conexión con n8n** | No tiene nodo nativo directo; requiere scripts locales o extensiones comunitarias. | Posee nodo nativo directo en n8n (`n8n-nodes-base.mySql`). | **Posee nodo nativo de primer nivel (`toolPostgres`) totalmente integrado con LangChain.** |

### Justificación de la Elección: ¿Por qué elegimos PostgreSQL?
Para el sistema aduanero seleccionamos **PostgreSQL 16** por las siguientes razones técnicas fundamentales:
1. **Precisión Matemática y Financiera:** En una aduana se liquidan millones de dólares en tributos arancelarios. PostgreSQL cuenta con un soporte impecable de tipos `DECIMAL(p,s)` y funciones de redondeo exacto sin pérdidas de precisión.
2. **Seguridad para el Agente de IA (Principio de Menor Privilegio):** PostgreSQL permite crear en pocas líneas un rol específico (`n8n_readonly`) con privilegios exclusivos de `GRANT SELECT`. Esto blinda la base de datos contra inyecciones SQL destructivas o alucinaciones del modelo de IA.
3. **Compatibilidad Nativa con n8n:** La herramienta de base de datos para agentes en n8n (`toolPostgres`) está optimizada para PostgreSQL, permitiendo inspeccionar esquemas, ejecutar consultas en milisegundos y conectarse de forma segura tanto en servidores locales como en servicios cloud modernos.

---

## C. n8n Y AGENTES DE INTELIGENCIA ARTIFICIAL

### 1. ¿Qué es n8n? ¿Qué es la automatización de flujos de trabajo (workflows)?
**n8n** es una plataforma de automatización de flujos de trabajo de código abierto basada en nodos interconectados. Un **workflow (flujo de trabajo)** es una secuencia lógica de pasos que se ejecuta automáticamente cuando ocurre un evento disparador (trigger). A diferencia de otras herramientas privativas en la nube, n8n puede autoalojarse localmente, garantizando la privacidad y soberanía de los datos aduaneros.

### 2. Nodo, Trigger y Credencial en n8n
* **Nodo:** Es la unidad básica de procesamiento en n8n. Cada nodo realiza una acción específica (por ejemplo: conectarse a PostgreSQL, invocar a un LLM o formatear una salida JSON).
* **Trigger (Disparador):** Es el nodo inicial que escucha eventos y pone en marcha el flujo. En nuestro caso, el `Chat Trigger` se activa cuando un funcionario escribe una pregunta en la interfaz de chat.
* **Credencial:** Es un mecanismo seguro y cifrado dentro de n8n donde se guardan las contraseñas de las bases de datos y las claves de API (como OpenAI o Google Gemini), evitando que queden expuestas en texto plano al exportar el flujo.

### 3. ¿Qué es un Agente de IA y en qué se diferencia de un chatbot normal?
Un **chatbot normal** responde mediante reglas fijas, menús de opciones o árboles de decisión rígidos (IF/ELSE). Si el usuario pregunta algo con otras palabras, el bot no comprende o da una respuesta pregrabada.
Un **Agente de Inteligencia Artificial** opera con un bucle cognitivo de razonamiento y acción (**ReAct - Reasoning + Acting**):
1. Recibe la consulta en lenguaje natural (ej. *"¿Qué mercancías de China siguen retenidas en la bodega 2?"*).
2. Razona qué información necesita y reconoce que debe consultar la base de datos.
3. Construye y ejecuta una sentencia SQL adecuada mediante su herramienta conectada.
4. Analiza los datos devueltos por la base de datos y redacta una respuesta coherente, formal y precisa para el usuario.

### 4. ¿Qué es un LLM y qué son las herramientas (tools) de un agente?
* **LLM (Large Language Model):** Es el modelo de lenguaje (como GPT-4o o Gemini) que actúa como el "cerebro" del agente, comprendiendo el lenguaje humano y generando texto estructurado. Sin embargo, el LLM por sí solo desconoce lo que hay en las bodegas hoy.
* **Herramientas (Tools):** Son funciones o conexiones externas que el agente tiene permitido invocar. Mediante *Tool Calling*, el LLM decide qué herramienta usar (en nuestro caso, la herramienta de PostgreSQL) y con qué parámetros (la consulta SQL) para obtener datos reales antes de responder.

### 5. ¿Cómo puede un agente consultar una base de datos de forma segura?
Para evitar que un agente modifique datos, borre tablas o sea víctima de una inyección de prompt maliciosa, se aplican tres capas de seguridad:
1. **Usuario de Solo Lectura en el Gestor:** Se crea un usuario en PostgreSQL (`n8n_readonly`) al que únicamente se le otorga permiso `GRANT SELECT`. Si el agente generara un `DROP` o un `DELETE`, el propio motor de base de datos rechaza la instrucción por falta de privilegios.
2. **System Prompt Restrictivo:** Se instruye al modelo explícitamente en su mensaje del sistema que su rol es de auditoría y que tiene estrictamente prohibido generar sentencias de mutación de datos.
3. **Cláusula LIMIT obligatoria:** Se le instruye limitar las consultas a un máximo de filas (ej. 50 registros) para prevenir sobrecargas de memoria en el servidor.

---

## D. EL DOMINIO ADUANERO

### 1. ¿Qué es una aduana y qué es una declaración aduanera (DUA)?
* **Aduana:** Es la entidad gubernamental encargada de vigilar, fiscalizar y autorizar la entrada y salida de mercancías, personas y medios de transporte en las fronteras, puertos y aeropuertos nacionales, garantizando la seguridad nacional y la recaudación de tributos.
* **Declaración Aduanera (DUA - Documento Único Aduanero):** Es el documento legal y tributario mediante el cual el importador o exportador declara bajo fe de juramento la naturaleza, valor, peso, origen y destino de las mercancías que somete a despacho aduanero.

### 2. Partida arancelaria (Sistema Armonizado) y Aranceles
* **Partida Arancelaria:** Es un código numérico estandarizado a nivel mundial por la Organización Mundial de Aduanas (OMA) mediante el **Sistema Armonizado (SA)**. Permite clasificar unívocamente cualquier producto en el comercio internacional. Por ejemplo:
  * `8471.30.00`: Máquinas automáticas para procesamiento de datos portátiles (Laptops).
  * `8517.13.00`: Teléfonos inteligentes (Smartphones).
  * `8703.23.00`: Automóviles de turismo diésel.
* **Arancel:** Es el impuesto que se aplica a los bienes comercializados internacionalmente. Puede ser:
  * *Ad-Valorem:* Un porcentaje sobre el valor CIF de la mercancía (ej. 15% sobre el valor del vehículo).
  * *Específico:* Un monto fijo por unidad física (ej. $2.00 por kilogramo neto de producto).

### 3. Regímenes aduaneros básicos
* **Importación Definitiva:** Ingreso de mercancías del exterior para permanecer en el país por tiempo indefinido, previo pago de aranceles e impuestos correspondientes.
* **Exportación Definitiva:** Salida legal de mercancías nacionales para su uso o consumo final en el extranjero (usualmente exenta de impuestos para fomentar la producción local).
* **Tránsito Aduanero:** Régimen en el que mercancías cruzan el territorio nacional bajo control fiscal de una frontera a otra con destino a un tercer país, sin pagar impuestos aduaneros locales (ejemplo: mercancía de Colombia hacia Honduras transitando por el país).
* **Depósito Aduanero (Almacén Fiscal):** Permite ingresar mercancías a bodegas autorizadas bajo control de la aduana sin pagar impuestos de inmediato, difiriendo el pago hasta que la mercancía sea retirada para su venta.

### 4. ¿Qué es un agente aduanal y qué papel cumple?
El **agente aduanal (o despachante de aduanas)** es un profesional auxiliar de la función pública autorizado legalmente para representar a importadores y exportadores ante la aduana. Su función es primordial: clasifica las mercancías en la partida arancelaria correcta, calcula y liquida los tributos, elabora la declaración DUA y asume responsabilidad legal solidaria por la veracidad de la información presentada.

---

## E. APARTADO: USO DE LA INTELIGENCIA ARTIFICIAL

* **Herramientas de IA utilizadas:** Antigravity IDE y el modelo Gemini 3.8 Flash como asistentes de arquitectura de software, validación relacional, generación de datos y asistencia en la configuración de n8n.
* **Ejemplos de prompts específicos redactados durante el proyecto:**
  1. *"Actúa como un arquitecto senior de bases de datos aduaneras. Diseña un modelo relacional en 3FN para un sistema de inventario de aduana con 13 tablas, resolviendo la relación N:M entre declaraciones y productos mediante una tabla intermedia con valores FOB y aranceles, y agrega una relación recursiva de supervisión en funcionarios."*
  2. *"Genera 16 registros de prueba realistas por tabla para PostgreSQL. Las partidas deben seguir el Sistema Armonizado real, los contenedores deben usar prefijos ISO 6346 válidos (MSKU, CMAU, COSU) y debe haber mercancía retenida de China en la Bodega 2 para poder evaluar la consulta del agente de IA."*
  3. *"Diseña un System Prompt defensivo para un Agente de IA en n8n conectado a una base de datos PostgreSQL, asegurando que solo formule sentencias SELECT de solo lectura y conozca el diccionario completo de tablas y columnas del inventario aduanero."*
* **Aprendizajes y reflexión crítica:**
  El uso de la IA aceleró notablemente la redacción y coherencia de los datos masivos de prueba. Sin embargo, se evidenció que la supervisión humana es indispensable para validar la lógica relacional: los modelos de IA pueden generar sentencias SQL con pequeños errores de sintaxis entre dialectos (por ejemplo, confundir `AUTO_INCREMENT` de MySQL con `SERIAL` de PostgreSQL) o enlazar llaves foráneas a identificadores que aún no han sido insertados. Usar la IA con criterio técnico nos permitió comprender a fondo el funcionamiento interno del SGBD y de las herramientas LangChain.

---

## F. FUENTES Y BIBLIOGRAFÍA CONSULTADA

1. **Silberschatz, A., Korth, H. F., & Sudarshan, S. (2020).** *Database System Concepts* (7.ª ed.). McGraw-Hill Education.
2. **Elmasri, R., & Navathe, S. B. (2017).** *Fundamentals of Database Systems* (7.ª ed.). Pearson.
3. **Organización Mundial de Aduanas (OMA / WCO). (2022).** *Nomenclatura del Sistema Armonizado de Designación y Codificación de Mercancías*. Bruselas, Bélgica.
4. **PostgreSQL Global Development Group. (2024).** *PostgreSQL 16 Documentation: SQL Commands, Privileges and Concurrency Control*. https://www.postgresql.org/docs/
5. **n8n Documentation. (2024).** *LangChain AI Agents, Tools and Database Connectors in n8n*. https://docs.n8n.io/
