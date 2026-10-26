-- ============================================================================
-- LABORATORIO #3: SISTEMA DE INVENTARIO ADUANERO
-- ASIGNATURA: Bases de Datos
-- INTEGRANTE: Krishna Moya Cervantes
-- GESTOR UTILIZADO: PostgreSQL 16 (Compatible con Neon / Supabase / Local)
-- FECHA: Octubre 2026
-- DESCRIPCIÓN: Script integral de creación de esquema en 3FN, llaves primarias,
--              llaves foráneas, restricciones avanzadas, datos de prueba (16+ por tabla),
--              consultas analíticas del negocio y configuración de usuario de solo lectura.
-- ============================================================================

DROP TABLE IF EXISTS movimiento_inventario CASCADE;
DROP TABLE IF EXISTS inventario CASCADE;
DROP TABLE IF EXISTS inspeccion CASCADE;
DROP TABLE IF EXISTS funcionario CASCADE;
DROP TABLE IF EXISTS contenedor CASCADE;
DROP TABLE IF EXISTS detalle_declaracion CASCADE;
DROP TABLE IF EXISTS declaracion_aduanera CASCADE;
DROP TABLE IF EXISTS producto CASCADE;
DROP TABLE IF EXISTS categoria_arancelaria CASCADE;
DROP TABLE IF EXISTS bodega CASCADE;
DROP TABLE IF EXISTS agente_aduanal CASCADE;
DROP TABLE IF EXISTS importador_exportador CASCADE;
DROP TABLE IF EXISTS pais CASCADE;
CREATE TABLE pais (
    id_pais SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE,
    codigo_iso CHAR(2) NOT NULL UNIQUE,
    codigo_iso3 CHAR(3) NOT NULL UNIQUE,
    continente VARCHAR(30) NOT NULL CHECK (continente IN ('América', 'Europa', 'Asia', 'África', 'Oceanía')),
    activo BOOLEAN DEFAULT TRUE NOT NULL
);
CREATE TABLE importador_exportador (
    id_operador SERIAL PRIMARY KEY,
    nombre_razon_social VARCHAR(150) NOT NULL,
    nit_ruc VARCHAR(25) NOT NULL UNIQUE,
    tipo_operador VARCHAR(25) NOT NULL CHECK (tipo_operador IN ('Importador', 'Exportador', 'Mixto')),
    direccion VARCHAR(200) NOT NULL,
    telefono VARCHAR(30) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    calificacion_riesgo VARCHAR(15) DEFAULT 'Bajo' NOT NULL CHECK (calificacion_riesgo IN ('Bajo', 'Medio', 'Alto', 'Crítico')),
    fecha_registro DATE DEFAULT CURRENT_DATE NOT NULL
);
CREATE TABLE agente_aduanal (
    id_agente SERIAL PRIMARY KEY,
    nombre_completo VARCHAR(120) NOT NULL,
    numero_licencia VARCHAR(30) NOT NULL UNIQUE,
    telefono VARCHAR(30) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    agencia_aduanal VARCHAR(150) NOT NULL,
    estado_licencia VARCHAR(20) DEFAULT 'Activa' NOT NULL CHECK (estado_licencia IN ('Activa', 'Suspendida', 'En Revocación')),
    fecha_acreditacion DATE NOT NULL
);
CREATE TABLE categoria_arancelaria (
    id_categoria SERIAL PRIMARY KEY,
    codigo_partida VARCHAR(12) NOT NULL UNIQUE,
    capitulo VARCHAR(4) NOT NULL,
    descripcion_oficial VARCHAR(255) NOT NULL,
    porcentaje_arancel DECIMAL(5,2) NOT NULL CHECK (porcentaje_arancel >= 0.00 AND porcentaje_arancel <= 100.00),
    requiere_permiso_especial BOOLEAN DEFAULT FALSE NOT NULL
);
CREATE TABLE producto (
    id_producto SERIAL PRIMARY KEY,
    codigo_sku VARCHAR(30) NOT NULL UNIQUE,
    descripcion VARCHAR(200) NOT NULL,
    unidad_medida VARCHAR(20) NOT NULL CHECK (unidad_medida IN ('Unidad', 'Kilogramo', 'Litro', 'Metro', 'Caja', 'Barril')),
    valor_unitario_fob_ref DECIMAL(12,2) NOT NULL CHECK (valor_unitario_fob_ref > 0),
    id_categoria INT NOT NULL,
    CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria) 
        REFERENCES categoria_arancelaria(id_categoria) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE TABLE bodega (
    id_bodega SERIAL PRIMARY KEY,
    codigo_bodega VARCHAR(15) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    tipo_deposito VARCHAR(40) NOT NULL CHECK (tipo_deposito IN ('Depósito Temporal', 'Almacén Fiscal', 'Refrigerado', 'Mercancías Peligrosas', 'Bienes Incautados')),
    ubicacion_terminal VARCHAR(120) NOT NULL,
    capacidad_max_pallets INT NOT NULL CHECK (capacidad_max_pallets > 0),
    temperatura_controlada BOOLEAN DEFAULT FALSE NOT NULL,
    responsable_bodega VARCHAR(100) NOT NULL
);
CREATE TABLE declaracion_aduanera (
    id_declaracion SERIAL PRIMARY KEY,
    numero_dua VARCHAR(30) NOT NULL UNIQUE,
    fecha_registro DATE NOT NULL,
    regimen VARCHAR(30) NOT NULL CHECK (regimen IN ('Importacion Definitiva', 'Exportacion Definitiva', 'Transito Aduanero', 'Deposito Aduanero')),
    canal_aforo VARCHAR(15) NOT NULL CHECK (canal_aforo IN ('Verde', 'Amarillo', 'Rojo')),
    estado VARCHAR(20) DEFAULT 'Retenida' NOT NULL CHECK (estado IN ('Registrada', 'En Inspección', 'Retenida', 'Liberada', 'Decomisada')),
    id_operador INT NOT NULL,
    id_agente INT NOT NULL,
    id_pais_origen INT NOT NULL,
    total_fob_usd DECIMAL(14,2) DEFAULT 0.00 NOT NULL CHECK (total_fob_usd >= 0.00),
    total_arancel_usd DECIMAL(14,2) DEFAULT 0.00 NOT NULL CHECK (total_arancel_usd >= 0.00),
    CONSTRAINT fk_declaracion_operador FOREIGN KEY (id_operador)
        REFERENCES importador_exportador(id_operador) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_declaracion_agente FOREIGN KEY (id_agente)
        REFERENCES agente_aduanal(id_agente) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_declaracion_pais_origen FOREIGN KEY (id_pais_origen)
        REFERENCES pais(id_pais) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE TABLE detalle_declaracion (
    id_detalle SERIAL PRIMARY KEY,
    id_declaracion INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad NUMERIC(12,2) NOT NULL CHECK (cantidad > 0),
    valor_unitario_usd DECIMAL(12,2) NOT NULL CHECK (valor_unitario_usd > 0),
    valor_total_fob DECIMAL(14,2) NOT NULL CHECK (valor_total_fob > 0),
    flete_seguro_usd DECIMAL(12,2) DEFAULT 0.00 NOT NULL CHECK (flete_seguro_usd >= 0),
    arancel_aplicado_usd DECIMAL(12,2) NOT NULL CHECK (arancel_aplicado_usd >= 0),
    CONSTRAINT fk_detalle_declaracion FOREIGN KEY (id_declaracion)
        REFERENCES declaracion_aduanera(id_declaracion) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_declaracion_producto UNIQUE (id_declaracion, id_producto)
);
CREATE TABLE contenedor (
    id_contenedor SERIAL PRIMARY KEY,
    numero_contenedor VARCHAR(15) NOT NULL UNIQUE,
    tipo VARCHAR(25) NOT NULL CHECK (tipo IN ('Dry 20ft', 'Dry 40ft', 'High Cube 40ft', 'Reefer 40ft', 'Open Top 20ft', 'Flat Rack 40ft')),
    peso_tara_kg DECIMAL(8,2) NOT NULL CHECK (peso_tara_kg > 0),
    peso_bruto_kg DECIMAL(9,2) NOT NULL CHECK (peso_bruto_kg >= peso_tara_kg),
    numero_sello_seguridad VARCHAR(30) NOT NULL UNIQUE,
    id_declaracion INT NOT NULL,
    CONSTRAINT fk_contenedor_declaracion FOREIGN KEY (id_declaracion)
        REFERENCES declaracion_aduanera(id_declaracion) ON UPDATE CASCADE ON DELETE CASCADE
);
CREATE TABLE funcionario (
    id_funcionario SERIAL PRIMARY KEY,
    codigo_empleado VARCHAR(20) NOT NULL UNIQUE,
    nombre_completo VARCHAR(120) NOT NULL,
    cargo VARCHAR(60) NOT NULL,
    departamento VARCHAR(60) NOT NULL CHECK (departamento IN ('Fiscalización', 'Operaciones Portuarias', 'Aforo e Inspección', 'Almacenes y Custodia', 'Asesoría Jurídica')),
    correo_institucional VARCHAR(100) NOT NULL UNIQUE,
    id_supervisor INT NULL,
    CONSTRAINT fk_funcionario_supervisor FOREIGN KEY (id_supervisor)
        REFERENCES funcionario(id_funcionario) ON UPDATE CASCADE ON DELETE SET NULL
);
CREATE TABLE inspeccion (
    id_inspeccion SERIAL PRIMARY KEY,
    numero_acta VARCHAR(30) NOT NULL UNIQUE,
    fecha_inspeccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo_inspeccion VARCHAR(20) NOT NULL CHECK (tipo_inspeccion IN ('Documental', 'Física no intrusiva', 'Física intrusiva')),
    resultado VARCHAR(25) NOT NULL CHECK (resultado IN ('Conforme', 'Con observaciones', 'Infracción grave', 'Decomiso preventivo')),
    observaciones TEXT NOT NULL,
    id_declaracion INT NOT NULL,
    id_funcionario INT NOT NULL,
    CONSTRAINT fk_inspeccion_declaracion FOREIGN KEY (id_declaracion)
        REFERENCES declaracion_aduanera(id_declaracion) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_inspeccion_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES funcionario(id_funcionario) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE TABLE inventario (
    id_inventario SERIAL PRIMARY KEY,
    id_bodega INT NOT NULL,
    id_producto INT NOT NULL,
    id_declaracion INT NOT NULL,
    cantidad_actual NUMERIC(12,2) NOT NULL CHECK (cantidad_actual >= 0),
    fecha_ingreso_bodega TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ubicacion_pasillo_rack VARCHAR(30) NOT NULL,
    estado_stock VARCHAR(20) DEFAULT 'Retenido' NOT NULL CHECK (estado_stock IN ('Retenido', 'Bajo Inspección', 'Liberado', 'Averiados', 'Decomisado')),
    CONSTRAINT fk_inventario_bodega FOREIGN KEY (id_bodega)
        REFERENCES bodega(id_bodega) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_inventario_producto FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_inventario_declaracion FOREIGN KEY (id_declaracion)
        REFERENCES declaracion_aduanera(id_declaracion) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_inventario_ubicacion UNIQUE (id_bodega, id_producto, id_declaracion, ubicacion_pasillo_rack)
);
CREATE TABLE movimiento_inventario (
    id_movimiento SERIAL PRIMARY KEY,
    id_inventario INT NOT NULL,
    tipo_movimiento VARCHAR(25) NOT NULL CHECK (tipo_movimiento IN ('Ingreso Inicial', 'Traslado Interno', 'Salida por Levante', 'Retiro por Decomiso')),
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    cantidad NUMERIC(12,2) NOT NULL CHECK (cantidad > 0),
    id_bodega_origen INT NULL,
    id_bodega_destino INT NULL,
    motivo VARCHAR(200) NOT NULL,
    autorizado_por INT NOT NULL,
    CONSTRAINT fk_movimiento_inventario FOREIGN KEY (id_inventario)
        REFERENCES inventario(id_inventario) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_movimiento_origen FOREIGN KEY (id_bodega_origen)
        REFERENCES bodega(id_bodega) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_movimiento_destino FOREIGN KEY (id_bodega_destino)
        REFERENCES bodega(id_bodega) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_movimiento_autorizador FOREIGN KEY (autorizado_por)
        REFERENCES funcionario(id_funcionario) ON UPDATE CASCADE ON DELETE RESTRICT
);
INSERT INTO pais (nombre, codigo_iso, codigo_iso3, continente) VALUES
('China', 'CN', 'CHN', 'Asia'),
('Estados Unidos', 'US', 'USA', 'América'),
('Alemania', 'DE', 'DEU', 'Europa'),
('Japón', 'JP', 'JPN', 'Asia'),
('México', 'MX', 'MEX', 'América'),
('Brasil', 'BR', 'BRA', 'América'),
('Corea del Sur', 'KR', 'KOR', 'Asia'),
('Vietnam', 'VN', 'VNM', 'Asia'),
('Países Bajos', 'NL', 'NLD', 'Europa'),
('Colombia', 'CO', 'COL', 'América'),
('España', 'ES', 'ESP', 'Europa'),
('Italia', 'IT', 'ITA', 'Europa'),
('Taiwán', 'TW', 'TWN', 'Asia'),
('Canadá', 'CA', 'CAN', 'América'),
('India', 'IN', 'IND', 'Asia'),
('Chile', 'CL', 'CHL', 'América');
INSERT INTO importador_exportador (nombre_razon_social, nit_ruc, tipo_operador, direccion, telefono, correo, calificacion_riesgo, fecha_registro) VALUES
('TechGlobal Logistics S.A.', 'J0310001890123', 'Importador', 'Parque Industrial Norte, Nave 4', '+505 2270-1122', 'contacto@techglobal.com', 'Bajo', '2024-01-15'),
('AgroExport del Pacífico S.A.', 'J0310001890456', 'Exportador', 'Carretera a Masaya Km 14.5', '+505 2278-4455', 'comercial@agroexport.com', 'Bajo', '2024-02-10'),
('Distribuidora FarmaVital Corp', 'J0310001890789', 'Importador', 'Zona Franca Las Mercedes, Módulo 8', '+505 2263-8899', 'logistica@farmavital.com', 'Bajo', '2024-03-01'),
('Automotriz Central S.A.', 'J0310001890321', 'Importador', 'Pista Juan Pablo II, Edificio Auto', '+505 2250-9900', 'aduanas@automotrizcentral.com', 'Medio', '2024-03-22'),
('ElectroMega Retailers S.A.', 'J0310001890654', 'Importador', 'Centro Comercial El Roble, Of. 201', '+505 2290-7711', 'compras@electromega.com', 'Medio', '2024-04-05'),
('Textiles Internacionales S.A.', 'J0310001890987', 'Mixto', 'Zona Industrial Tipitapa, Galpón 3', '+505 2295-3344', 'aduanas@textilesintl.com', 'Bajo', '2024-04-18'),
('Químicos Industriales del Trópico', 'J0310001891112', 'Importador', 'Carretera Norte Km 6', '+505 2244-5566', 'seguridad@quimicostropico.com', 'Alto', '2024-05-12'),
('Comercializadora Oriental Cía Ltda', 'J0310001891314', 'Importador', 'Mercado Oriental, Bodega 15', '+505 2228-9988', 'import@comercialoriental.com', 'Alto', '2024-06-01'),
('Soluciones Médicas Especializadas', 'J0310001891516', 'Importador', 'Reparto San Juan, Calle Principal #45', '+505 2277-3322', 'gerencia@solumedicas.com', 'Bajo', '2024-06-20'),
('Alimentos Marinos y Congelados S.A.', 'J0310001891718', 'Mixto', 'Puerto Corinto, Muelle Pesquero', '+505 2342-2200', 'operaciones@alimarinos.com', 'Bajo', '2024-07-08'),
('Ferretería y Aceros Pesados S.A.', 'J0310001891920', 'Importador', 'Carretera Vieja a León Km 9', '+505 2265-1177', 'logistica@acerospesados.com', 'Bajo', '2024-08-01'),
('Vinos y Licores de Importación Ltd', 'J0310001892122', 'Importador', 'Residencial Los Robles, Villa 12', '+505 2270-4499', 'importaciones@vinoslicores.com', 'Medio', '2024-08-15'),
('Renovable Energy Systems Corp', 'J0310001892324', 'Importador', 'Plaza España, Torre B, Piso 5', '+505 2266-4433', 'proyectos@renovablesys.com', 'Bajo', '2024-09-02'),
('Consorcio Minero de Occidente', 'J0310001892526', 'Mixto', 'Mina San Albino, Sector Mina', '+505 2732-2211', 'suministros@consorciominero.com', 'Medio', '2024-09-18'),
('Supermercados El Ahorro S.A.', 'J0310001892728', 'Importador', 'Pista de la Resistencia, Managua', '+505 2280-5566', 'importaciones@elahorro.com', 'Bajo', '2024-10-01'),
('Importaciones Express Ramírez', 'J0310001892930', 'Importador', 'Barrio Monseñor Lezcano #310', '+505 2266-7788', 'contacto@importramirez.com', 'Crítico', '2024-10-10');
INSERT INTO agente_aduanal (nombre_completo, numero_licencia, telefono, correo, agencia_aduanal, estado_licencia, fecha_acreditacion) VALUES
('Lic. Carlos Alberto Mendoza Vega', 'LIC-ADU-2015-001', '+505 8881-2233', 'carlos.mendoza@aduanasmendoza.com', 'Agencia Aduanera Mendoza & Asociados', 'Activa', '2015-03-10'),
('Licda. María Elena Brenes Soto', 'LIC-ADU-2016-042', '+505 8882-3344', 'mbrenes@brenescustoms.com', 'Brenes Customs Broker Services', 'Activa', '2016-07-22'),
('Lic. Roberto José Silva Narváez', 'LIC-ADU-2017-088', '+505 8883-4455', 'rsilva@silvalogistics.com', 'Silva Aduanas y Logística Integral', 'Activa', '2017-01-18'),
('Licda. Claudia Patricia Gómez Paz', 'LIC-ADU-2018-105', '+505 8884-5566', 'claudia.gomez@corintoagentes.com', 'Agentes Aduaneros Puerto Corinto', 'Activa', '2018-05-30'),
('Lic. Fernando Javier Toruño Mora', 'LIC-ADU-2018-112', '+505 8885-6677', 'ftoruno@torunocustoms.com', 'Toruño & Compañía Despachantes', 'Activa', '2018-11-12'),
('Licda. Sofía Alejandra Morales Ruiz', 'LIC-ADU-2019-145', '+505 8886-7788', 'smorales@globaladuanas.com', 'Global Aduanas de Centroamérica', 'Activa', '2019-02-14'),
('Lic. Guillermo Antonio Castillo Cruz', 'LIC-ADU-2019-178', '+505 8887-8899', 'gcastillo@castilloasoc.com', 'Castillo & Asociados Comercio Exterior', 'Activa', '2019-08-25'),
('Licda. Vanessa Carolina Rivas Ortiz', 'LIC-ADU-2020-204', '+505 8888-9900', 'vrivas@transaduanas.com', 'TransAduanas del Pacífico', 'Activa', '2020-04-10'),
('Lic. Mauricio Ernesto Delgado Ríos', 'LIC-ADU-2021-230', '+505 8889-1122', 'mdelgado@delgadobrokers.com', 'Delgado Aduaneros y Carga', 'Activa', '2021-06-15'),
('Licda. Elena Marcela Vargas Solís', 'LIC-ADU-2021-255', '+505 8890-2233', 'evargas@vargaslogistica.com', 'Vargas Logística y Despacho Aduanal', 'Activa', '2021-09-08'),
('Lic. Héctor Manuel Calero Guido', 'LIC-ADU-2022-280', '+505 8891-3344', 'hcalero@caleroaduanas.com', 'Calero Despachos Rápidos', 'Activa', '2022-01-20'),
('Licda. Gabriela María Duarte Fonseca', 'LIC-ADU-2022-310', '+505 8892-4455', 'gduarte@duartecustoms.com', 'Duarte Asesores Aduaneros', 'Activa', '2022-08-11'),
('Lic. Jorge Luis Solórzano Parrales', 'LIC-ADU-2023-345', '+505 8893-5566', 'jsolorzano@solorzanobrokers.com', 'Solórzano & Consultores Aduaneros', 'Activa', '2023-03-05'),
('Licda. Brenda Lucía Mairena López', 'LIC-ADU-2023-370', '+505 8894-6677', 'bmairena@mairenaaduanas.com', 'Mairena Servicios Aduaneros Integrados', 'Activa', '2023-10-18'),
('Lic. Álvaro Daniel Estrada Sevilla', 'LIC-ADU-2024-402', '+505 8895-7788', 'aestrada@estradacustoms.com', 'Estrada Despachos y Logística', 'Suspendida', '2024-02-01');
INSERT INTO categoria_arancelaria (codigo_partida, capitulo, descripcion_oficial, porcentaje_arancel, requiere_permiso_especial) VALUES
('8471.30.00', '84', 'Máquinas automáticas para tratamiento o procesamiento de datos, portátiles (Laptops y tablets)', 0.00, FALSE),
('8517.13.00', '85', 'Teléfonos inteligentes (Smartphones) y terminales móviles', 0.00, FALSE),
('8528.72.00', '85', 'Aparatos receptores de televisión en colores con pantalla plana (Smart TVs)', 15.00, FALSE),
('8703.23.00', '87', 'Automóviles de turismo con motor de émbolo alternativo de cilindrada superior a 1500cc pero <= 3000cc', 20.00, TRUE),
('3004.90.99', '30', 'Medicamentos constituidos por productos mezclados o sin mezclar para uso terapéutico en dosis', 5.00, TRUE),
('2204.21.00', '22', 'Vino de uvas frescas en recipientes con capacidad inferior o igual a 2 litros', 30.00, TRUE),
('8418.10.00', '84', 'Combinadores de refrigerador y congelador con puertas exteriores separadas', 15.00, FALSE),
('6109.10.00', '61', 'T-shirts y camisetas interiores de punto de algodón para hombres y mujeres', 10.00, FALSE),
('6403.99.00', '64', 'Calzado con suela de caucho, plástico o cuero regenerado y parte superior de cuero natural', 15.00, FALSE),
('8541.43.00', '85', 'Células fotovoltaicas ensambladas en módulos o paneles solares', 0.00, FALSE),
('1006.30.00', '10', 'Arroz semiblanqueado o blanqueado, incluso pulido o glaseado', 45.00, TRUE),
('2933.39.00', '29', 'Compuestos heterocíclicos con heteroátomo de nitrógeno exclusivo (Precursores químicos)', 10.00, TRUE),
('7214.20.00', '72', 'Barras de hierro o acero sin alear con muescas, cordones o huecos (Varillas corrugadas)', 5.00, FALSE),
('0201.30.00', '02', 'Carne de animales de la especie bovina, deshuesada, fresca o refrigerada', 25.00, TRUE),
('9018.90.90', '90', 'Instrumentos y aparatos de medicina, cirugía, odontología o veterinaria', 0.00, TRUE),
('8504.40.90', '85', 'Convertidores estáticos e inversores de corriente para energía solar y telecomunicaciones', 0.00, FALSE);
INSERT INTO producto (codigo_sku, descripcion, unidad_medida, valor_unitario_fob_ref, id_categoria) VALUES
('PROD-LAP-001', 'Laptop Lenovo ThinkPad T14 Gen 4 Intel Core i7 16GB 512GB SSD', 'Unidad', 850.00, 1),
('PROD-PHN-002', 'Smartphone Samsung Galaxy S24 Ultra 256GB Titanium Gray', 'Unidad', 920.00, 2),
('PROD-TV-003', 'Smart TV LG OLED 65 pulgadas 4K UHD ThinQ AI', 'Unidad', 1200.00, 3),
('PROD-AUTO-004', 'Automóvil Toyota Hilux Doble Cabina 4x4 2.8L Diésel 2026', 'Unidad', 28500.00, 4),
('PROD-MED-005', 'Amoxicilina + Ácido Clavulánico 875/125mg Caja x 20 tabletas', 'Caja', 14.50, 5),
('PROD-VIN-006', 'Vino Tinto Reserva Cabernet Sauvignon 750ml Valle de Colchagua', 'Caja', 96.00, 6),
('PROD-REF-007', 'Refrigeradora Whirlpool No Frost 400 Litros Acero Inoxidable', 'Unidad', 450.00, 7),
('PROD-TEX-008', 'Camisetas de punto 100% algodón jersey peinado paquete x 50 uds', 'Caja', 125.00, 8),
('PROD-CAL-009', 'Zapatos de seguridad industrial punta de acero cuero hidrofugado', 'Unidad', 42.00, 9),
('PROD-SOL-010', 'Panel Solar Monocristalino Tier 1 de 550W de alta eficiencia', 'Unidad', 115.00, 10),
('PROD-ARR-011', 'Arroz Grano Largo Selecto Fortificado Saco de 50 kg', 'Caja', 38.00, 11),
('PROD-QUI-012', 'Solvente Técnico Industrial Grado Reactivo Tambor 200 Litros', 'Barril', 480.00, 12),
('PROD-VAR-013', 'Varilla de acero corrugado grado 60 de 1/2 pulgada x 6 metros quintal', 'Unidad', 48.50, 13),
('PROD-CAR-014', 'Corte Premium Lomo Fino de Res Congelado al Vacío Caja 20 kg', 'Caja', 240.00, 14),
('PROD-MED-015', 'Monitor de signos vitales multiparámetro hospitalario 12 pulgadas', 'Unidad', 2150.00, 15),
('PROD-INV-016', 'Inversor Solar Híbrido Trifásico 10kW con conexión a red y batería', 'Unidad', 1450.00, 16);
INSERT INTO bodega (codigo_bodega, nombre, tipo_deposito, ubicacion_terminal, capacidad_max_pallets, temperatura_controlada, responsable_bodega) VALUES
('BOD-01', 'Bodega Central Puerto Corinto A1', 'Depósito Temporal', 'Terminal Portuaria Corinto, Muelle 1', 1200, FALSE, 'Ing. Mario Silva'),
('BOD-02', 'Bodega de Retención Fiscal y Custodia 2', 'Bienes Incautados', 'Terminal Portuaria Corinto, Sector B2', 450, FALSE, 'Cap. Ernesto Barquero'),
('BOD-03', 'Depósito Frigorífico Cadena de Frío', 'Refrigerado', 'Terminal Portuaria Corinto, Área Fría', 300, TRUE, 'Licda. Katherine Valle'),
('BOD-04', 'Bodega Electrónica y Bienes de Alto Valor', 'Almacén Fiscal', 'Aeropuerto Int. Augusto C. Sandino', 600, TRUE, 'Lic. Julio César Roa'),
('BOD-05', 'Almacén Fiscal Central Aeroportuario', 'Depósito Temporal', 'Aeropuerto Int. Augusto C. Sandino, Nave 3', 850, FALSE, 'Ing. Patricia Orozco'),
('BOD-06', 'Bodega Sustancias Químicas y Peligrosas', 'Mercancías Peligrosas', 'Carretera Norte Km 9.5 Managua', 250, FALSE, 'Ing. Química Helena Solís'),
('BOD-07', 'Depósito Fiscal Terrestre Peñas Blancas', 'Depósito Temporal', 'Puesto Fronterizo Peñas Blancas (Sur)', 700, FALSE, 'Lic. Denis Morales'),
('BOD-08', 'Depósito Fiscal Terrestre El Guasaule', 'Depósito Temporal', 'Puesto Fronterizo El Guasaule (Norte)', 650, FALSE, 'Lic. Ronald Blandón'),
('BOD-09', 'Almacén de Graneles y Carga Pesada', 'Almacén Fiscal', 'Puerto Corinto, Zona Extraportuaria', 2000, FALSE, 'Ing. Leonardo Cuadra'),
('BOD-10', 'Depósito Fiscal Farmacéutico y Hospitalario', 'Refrigerado', 'Zona Franca Las Mercedes, Módulo F-2', 400, TRUE, 'Dra. Miriam Fonseca'),
('BOD-11', 'Bodega de Resguardo San Bartolo', 'Almacén Fiscal', 'Carretera Vieja a Tipitapa Km 18', 1100, FALSE, 'Lic. Ramón Galeano'),
('BOD-12', 'Bodega de Decomisos y Custodia Judicial', 'Bienes Incautados', 'Complejo Aduanero Central Managua', 350, FALSE, 'Abog. Lester Centeno'),
('BOD-13', 'Depósito Automotriz Patio 1', 'Depósito Temporal', 'Puerto Corinto, Explanada Vehicular Norte', 800, FALSE, 'Sr. Gonzalo Pineda'),
('BOD-14', 'Depósito de Carga Consolidada LCL', 'Depósito Temporal', 'Centro Logístico Nejapa', 900, FALSE, 'Licda. Brenda Somarriba'),
('BOD-15', 'Almacén Fiscal Especializado Energía Solar', 'Almacén Fiscal', 'Parque Industrial Las Colinas', 550, FALSE, 'Ing. David Arana');
INSERT INTO declaracion_aduanera (numero_dua, fecha_registro, regimen, canal_aforo, estado, id_operador, id_agente, id_pais_origen, total_fob_usd, total_arancel_usd) VALUES
('DUA-2026-00101', '2026-10-02', 'Importacion Definitiva', 'Rojo', 'Retenida', 1, 1, 1, 85000.00, 0.00),
('DUA-2026-00102', '2026-10-04', 'Importacion Definitiva', 'Rojo', 'Retenida', 5, 2, 1, 92000.00, 0.00),
('DUA-2026-00103', '2026-10-05', 'Importacion Definitiva', 'Amarillo', 'Liberada', 4, 3, 4, 285000.00, 57000.00),
('DUA-2026-00104', '2026-10-08', 'Importacion Definitiva', 'Rojo', 'En Inspección', 7, 4, 3, 48000.00, 4800.00),
('DUA-2026-00105', '2026-10-10', 'Importacion Definitiva', 'Verde', 'Liberada', 3, 5, 5, 36250.00, 1812.50),
('DUA-2026-00106', '2026-10-12', 'Importacion Definitiva', 'Rojo', 'Retenida', 8, 6, 1, 60000.00, 9000.00),
('DUA-2026-00107', '2026-10-14', 'Deposito Aduanero', 'Amarillo', 'Retenida', 12, 7, 16, 28800.00, 8640.00),
('DUA-2026-00108', '2026-10-15', 'Importacion Definitiva', 'Verde', 'Liberada', 13, 8, 1, 115000.00, 0.00),
('DUA-2026-00109', '2026-10-16', 'Transito Aduanero', 'Verde', 'Liberada', 2, 9, 10, 45000.00, 0.00),
('DUA-2026-00110', '2026-10-18', 'Importacion Definitiva', 'Rojo', 'Retenida', 16, 10, 1, 25000.00, 3750.00),
('DUA-2026-00111', '2026-10-19', 'Importacion Definitiva', 'Amarillo', 'Registrada', 11, 11, 6, 97000.00, 4850.00),
('DUA-2026-00112', '2026-10-20', 'Importacion Definitiva', 'Rojo', 'Decomisada', 8, 12, 1, 35000.00, 5250.00),
('DUA-2026-00113', '2026-10-21', 'Importacion Definitiva', 'Verde', 'Liberada', 9, 13, 2, 64500.00, 0.00),
('DUA-2026-00114', '2026-10-22', 'Exportacion Definitiva', 'Verde', 'Liberada', 10, 14, 10, 72000.00, 0.00),
('DUA-2026-00115', '2026-09-25', 'Importacion Definitiva', 'Amarillo', 'Liberada', 15, 1, 2, 76000.00, 34200.00),
('DUA-2026-00116', '2026-09-28', 'Importacion Definitiva', 'Rojo', 'Retenida', 5, 2, 7, 72500.00, 0.00);
INSERT INTO detalle_declaracion (id_declaracion, id_producto, cantidad, valor_unitario_usd, valor_total_fob, flete_seguro_usd, arancel_aplicado_usd) VALUES
(1, 1, 100.00, 850.00, 85000.00, 3200.00, 0.00),
(2, 2, 100.00, 920.00, 92000.00, 2800.00, 0.00),
(3, 4, 10.00, 28500.00, 285000.00, 8500.00, 57000.00),
(4, 12, 100.00, 480.00, 48000.00, 4100.00, 4800.00),
(5, 5, 2500.00, 14.50, 36250.00, 1500.00, 1812.50),
(6, 3, 50.00, 1200.00, 60000.00, 3100.00, 9000.00),
(7, 6, 300.00, 96.00, 28800.00, 2200.00, 8640.00),
(8, 10, 1000.00, 115.00, 115000.00, 5600.00, 0.00),
(9, 8, 360.00, 125.00, 45000.00, 2000.00, 4500.00),
(10, 9, 595.00, 42.00, 24990.00, 1800.00, 3748.50),
(11, 13, 2000.00, 48.50, 97000.00, 6200.00, 4850.00),
(12, 8, 280.00, 125.00, 35000.00, 1900.00, 3500.00),
(13, 15, 30.00, 2150.00, 64500.00, 2500.00, 0.00),
(14, 14, 300.00, 240.00, 72000.00, 4500.00, 0.00),
(15, 11, 2000.00, 38.00, 76000.00, 5200.00, 34200.00),
(16, 16, 50.00, 1450.00, 72500.00, 3300.00, 0.00),
(1, 2, 20.00, 920.00, 18400.00, 800.00, 0.00),
(8, 16, 10.00, 1450.00, 14500.00, 900.00, 0.00);
INSERT INTO contenedor (numero_contenedor, tipo, peso_tara_kg, peso_bruto_kg, numero_sello_seguridad, id_declaracion) VALUES
('MSKU2948102', 'Dry 40ft', 3800.00, 18450.00, 'SEAL-MAERSK-9011', 1),
('MSKU8831094', 'Dry 40ft', 3850.00, 19200.00, 'SEAL-MAERSK-9012', 2),
('CMAU4819203', 'Flat Rack 40ft', 5200.00, 27800.00, 'SEAL-CMA-4421', 3),
('HLCU7718291', 'Dry 20ft', 2300.00, 16800.00, 'SEAL-HAPAG-3312', 4),
('MSKU1192840', 'Reefer 40ft', 4400.00, 12600.00, 'SEAL-MAERSK-FR-11', 5),
('CMAU9920112', 'High Cube 40ft', 3950.00, 15400.00, 'SEAL-CMA-8819', 6),
('SUDU3391024', 'Reefer 40ft', 4450.00, 18900.00, 'SEAL-HAMBURGSUD-5', 7),
('COSU6619283', 'High Cube 40ft', 3900.00, 24100.00, 'SEAL-COSCO-1102', 8),
('EGLV1182736', 'Dry 40ft', 3820.00, 14300.00, 'SEAL-EVERGREEN-44', 9),
('COSU8819201', 'Dry 20ft', 2280.00, 11400.00, 'SEAL-COSCO-7721', 10),
('MSKU4491028', 'Open Top 20ft', 2450.00, 26900.00, 'SEAL-MAERSK-OT-9', 11),
('COSU3329182', 'Dry 20ft', 2250.00, 9800.00, 'SEAL-COSCO-9901', 12),
('HLCU1192847', 'Dry 40ft', 3800.00, 11200.00, 'SEAL-HAPAG-6621', 13),
('MSKU5581920', 'Reefer 40ft', 4420.00, 22400.00, 'SEAL-MAERSK-FR-88', 14),
('CMAU2291039', 'Dry 40ft', 3850.00, 28400.00, 'SEAL-CMA-9922', 15),
('COSU4491029', 'High Cube 40ft', 3920.00, 17800.00, 'SEAL-COSCO-3341', 16);
INSERT INTO funcionario (codigo_empleado, nombre_completo, cargo, departamento, correo_institucional, id_supervisor) VALUES
('EMP-001', 'Lic. Rodrigo Montenegro Salazar', 'Director General de Aduanas', 'Fiscalización', 'rodrigo.montenegro@aduana.gob.ni', NULL),
('EMP-002', 'Ing. Gabriel Alejandro Morales Pao', 'Jefe de Operaciones Portuarias', 'Operaciones Portuarias', 'gabriel.morales@aduana.gob.ni', 1),
('EMP-003', 'Licda. Martha Lorena Jarquín Ruiz', 'Supervisora General de Aforo', 'Aforo e Inspección', 'martha.jarquin@aduana.gob.ni', 1),
('EMP-004', 'Ing. Silvio José Gutiérrez Calero', 'Coordinador de Almacenes y Depósitos', 'Almacenes y Custodia', 'silvio.gutierrez@aduana.gob.ni', 1),
('EMP-005', 'Abog. Tatiana Milagros Rizo Vivas', 'Jefa de Asesoría Jurídica y Decomisos', 'Asesoría Jurídica', 'tatiana.rizo@aduana.gob.ni', 1);
INSERT INTO funcionario (codigo_empleado, nombre_completo, cargo, departamento, correo_institucional, id_supervisor) VALUES
('EMP-006', 'Lic. Marvin Antonio Guido Pérez', 'Inspector de Aforo Físico Senior', 'Aforo e Inspección', 'marvin.guido@aduana.gob.ni', 3),
('EMP-007', 'Licda. Karla Vanessa Lovo Espinoza', 'Inspectora de Aforo Documental', 'Aforo e Inspección', 'karla.lovo@aduana.gob.ni', 3),
('EMP-008', 'Ing. Douglas Enrique Reyes Solano', 'Inspector Químico y Mercancías Peligrosas', 'Fiscalización', 'douglas.reyes@aduana.gob.ni', 1),
('EMP-009', 'Lic. Óscar Iván Centeno Urbina', 'Oficial de Resguardo y Custodia', 'Almacenes y Custodia', 'oscar.centeno@aduana.gob.ni', 4),
('EMP-010', 'Licda. Cynthia Iveth Téllez Mayorga', 'Inspectora de Aforo Físico Puerto', 'Aforo e Inspección', 'cynthia.tellez@aduana.gob.ni', 3),
('EMP-011', 'Ing. Noel Francisco Balmaceda Vega', 'Técnico de Control de Inventarios', 'Almacenes y Custodia', 'noel.balmaceda@aduana.gob.ni', 4),
('EMP-012', 'Licda. Yolanda Beatriz Aguirre Palma', 'Auditora de Valoración Aduanera', 'Fiscalización', 'yolanda.aguirre@aduana.gob.ni', 1),
('EMP-013', 'Lic. Edwin Alberto Carranza Prado', 'Oficial de Custodia Bodega 2', 'Almacenes y Custodia', 'edwin.carranza@aduana.gob.ni', 4),
('EMP-014', 'Licda. Lucía Amanda Peralta Cruz', 'Inspectora de Mercancías Tecnológicas', 'Aforo e Inspección', 'lucia.peralta@aduana.gob.ni', 3),
('EMP-015', 'Abog. Mauricio José Tinoco Marenco', 'Oficial de Actas de Retención', 'Asesoría Jurídica', 'mauricio.tinoco@aduana.gob.ni', 5),
('EMP-016', 'Ing. Javier Alfonso Mendoza Gómez', 'Inspector de Tránsito Fronterizo', 'Operaciones Portuarias', 'javier.mendoza@aduana.gob.ni', 2);
INSERT INTO inspeccion (numero_acta, fecha_inspeccion, tipo_inspeccion, resultado, observaciones, id_declaracion, id_funcionario) VALUES
('ACTA-2026-0089', '2026-10-03 10:30:00', 'Física intrusiva', 'Con observaciones', 'Discrepancia en números de serie y firmware. Mercancía trasladada a Bodega 2 en retención preventiva.', 1, 6),
('ACTA-2026-0090', '2026-10-05 14:15:00', 'Física no intrusiva', 'Con observaciones', 'Inspección por escáner de rayos X arrojó densidades atípicas en 10 pallets. Requiere aforo documental y técnico en Bodega 2.', 2, 10),
('ACTA-2026-0091', '2026-10-06 09:00:00', 'Física intrusiva', 'Conforme', 'Inspección de vehículos automotores. VIN, números de chasis y motor coinciden íntegramente con DUA y manifiesto.', 3, 6),
('ACTA-2026-0092', '2026-10-09 11:45:00', 'Física intrusiva', 'Conforme', 'Muestreo químico de solventes. Documentación técnica de sustancias peligrosas completa y en regla.', 4, 8),
('ACTA-2026-0093', '2026-10-10 16:20:00', 'Documental', 'Conforme', 'Permisos sanitarios de MINSA vigentes para lote farmacéutico de amoxicilina.', 5, 7),
('ACTA-2026-0094', '2026-10-13 13:10:00', 'Física no intrusiva', 'Con observaciones', 'Factura comercial no detalla modelos exactos de televisores OLED. Retenida en Bodega 2 pendiente de aforo de valor.', 6, 14),
('ACTA-2026-0095', '2026-10-15 08:30:00', 'Documental', 'Conforme', 'Certificado de origen de vinos chilenos con inconsistencia menor corregida mediante adenda.', 7, 7),
('ACTA-2026-0096', '2026-10-16 15:40:00', 'Documental', 'Conforme', 'Paneles solares gozan de exención tributaria ley de energías renovables. Levante autorizado.', 8, 12),
('ACTA-2026-0097', '2026-10-17 11:00:00', 'Documental', 'Conforme', 'Declaración de tránsito internacional con precinto electrónico satelital activo.', 9, 7),
('ACTA-2026-0098', '2026-10-19 14:50:00', 'Física intrusiva', 'Con observaciones', 'Calzado deportivo con etiquetas de marca no declarada ante registro de propiedad intelectual. Mercancía retenida en Bodega 2.', 10, 6),
('ACTA-2026-0099', '2026-10-20 10:00:00', 'Física no intrusiva', 'Conforme', 'Escaneo de bobinas de varillas de acero. Coincidencia de peso con margen de tolerancia del 0.8%.', 11, 10),
('ACTA-2026-0100', '2026-10-21 16:30:00', 'Física intrusiva', 'Decomiso preventivo', 'Contrabando detectado: mercancía textil con marcas falsificadas. Se ordena remisión a custodia judicial.', 12, 6),
('ACTA-2026-0101', '2026-10-22 09:20:00', 'Física intrusiva', 'Conforme', 'Equipos médicos hospitalarios certificados por la FDA. Cumplen normativa técnica nacional.', 13, 8),
('ACTA-2026-0102', '2026-10-22 17:00:00', 'Física intrusiva', 'Conforme', 'Inspección de cadena de frío y certificado fitosanitario de exportación en muelle de carga.', 14, 10),
('ACTA-2026-0103', '2026-09-26 14:00:00', 'Documental', 'Conforme', 'Aranceles arrocero cancelados en ventanilla bancaria autorizada.', 15, 7),
('ACTA-2026-0104', '2026-09-29 11:30:00', 'Física no intrusiva', 'Con observaciones', 'Falta certificado de homologación para inversores de 10kW. Retenido en Bodega 2 hasta presentar prueba técnica.', 16, 14);
INSERT INTO inventario (id_bodega, id_producto, id_declaracion, cantidad_actual, fecha_ingreso_bodega, ubicacion_pasillo_rack, estado_stock) VALUES
(2, 1, 1, 100.00, '2026-10-03 12:00:00', 'Rack-B2-01-A', 'Retenido'),
(2, 2, 2, 100.00, '2026-10-05 16:00:00', 'Rack-B2-01-B', 'Retenido'),
(13, 4, 3, 10.00, '2026-10-05 11:00:00', 'Patio-Norte-Fila-3', 'Liberado'),
(6, 12, 4, 100.00, '2026-10-08 14:00:00', 'Galpon-Q-Sector-1', 'Bajo Inspección'),
(10, 5, 5, 2500.00, '2026-10-10 17:30:00', 'Camara-Med-02', 'Liberado'),
(2, 3, 6, 50.00, '2026-10-13 15:00:00', 'Rack-B2-02-C', 'Retenido'),
(3, 6, 7, 300.00, '2026-10-14 12:00:00', 'Camara-Fria-01', 'Retenido'),
(15, 10, 8, 1000.00, '2026-10-15 10:00:00', 'Nave-Solar-Est-4', 'Liberado'),
(1, 8, 9, 360.00, '2026-10-16 18:00:00', 'Rack-B1-04-D', 'Liberado'),
(2, 9, 10, 595.00, '2026-10-18 16:30:00', 'Rack-B2-03-A', 'Retenido'),
(9, 13, 11, 2000.00, '2026-10-19 13:00:00', 'Patio-Aceros-G2', 'Retenido'),
(12, 8, 12, 280.00, '2026-10-21 17:30:00', 'Jaula-Judicial-1', 'Decomisado'),
(4, 15, 13, 30.00, '2026-10-22 11:00:00', 'Rack-Seg-01-A', 'Liberado'),
(3, 14, 14, 300.00, '2026-10-22 18:30:00', 'Camara-Fria-03', 'Liberado'),
(1, 11, 15, 2000.00, '2026-09-25 15:00:00', 'Silo-Seco-02', 'Liberado'),
(2, 16, 16, 50.00, '2026-09-28 14:00:00', 'Rack-B2-04-A', 'Retenido');
INSERT INTO movimiento_inventario (id_inventario, tipo_movimiento, fecha_movimiento, cantidad, id_bodega_origen, id_bodega_destino, motivo, autorizado_por) VALUES
(1, 'Ingreso Inicial', '2026-10-03 12:30:00', 100.00, NULL, 2, 'Recepción desde contenedor por orden de retención preventiva', 4),
(2, 'Ingreso Inicial', '2026-10-05 16:30:00', 100.00, NULL, 2, 'Ingreso por discrepancia de aforo no intrusivo', 4),
(3, 'Salida por Levante', '2026-10-06 10:00:00', 10.00, 13, NULL, 'Retiro de vehículos por pago total y autorización de levante DUA-103', 2),
(4, 'Ingreso Inicial', '2026-10-08 14:30:00', 100.00, NULL, 6, 'Ingreso a bodega de químicos en espera de dictamen', 4),
(5, 'Salida por Levante', '2026-10-11 08:30:00', 2500.00, 10, NULL, 'Despacho con canal verde y autorización sanitaria', 3),
(6, 'Ingreso Inicial', '2026-10-13 15:30:00', 50.00, NULL, 2, 'Ingreso por falta de descripción detallada en factura', 4),
(7, 'Ingreso Inicial', '2026-10-14 12:45:00', 300.00, NULL, 3, 'Ingreso en custodia a depósito fiscal climatizado', 4),
(8, 'Salida por Levante', '2026-10-16 09:00:00', 1000.00, 15, NULL, 'Levante otorgado según ley incentivo solar', 3),
(9, 'Salida por Levante', '2026-10-17 14:00:00', 360.00, 1, NULL, 'Salida de mercancía en tránsito hacia frontera norte', 2),
(10, 'Ingreso Inicial', '2026-10-18 17:00:00', 595.00, NULL, 2, 'Custodia cautelar por presunta violación de marcas', 4),
(11, 'Ingreso Inicial', '2026-10-19 14:00:00', 2000.00, NULL, 9, 'Descarga de planchones y varillas de acero', 2),
(12, 'Retiro por Decomiso', '2026-10-21 18:00:00', 280.00, 1, 12, 'Traslado a custodia judicial por resolución aduanera de decomiso', 5),
(13, 'Salida por Levante', '2026-10-22 15:00:00', 30.00, 4, NULL, 'Entrega a distribuidor hospitalario', 3),
(14, 'Salida por Levante', '2026-10-23 06:00:00', 300.00, 3, NULL, 'Embarque en buque frigorífico con destino exterior', 2),
(15, 'Salida por Levante', '2026-09-28 10:00:00', 2000.00, 1, NULL, 'Retiro autorizado de granel arrocero', 3),
(16, 'Traslado Interno', '2026-10-01 09:30:00', 50.00, 1, 2, 'Traslado de patio general a Bodega 2 por falta de homologación', 4);
SELECT
    d.regimen,
    COUNT(d.id_declaracion) AS total_declaraciones,
    SUM(d.total_fob_usd) AS valor_fob_acumulado_usd,
    SUM(d.total_arancel_usd) AS aranceles_liquidados_usd,
    ROUND(AVG(d.total_fob_usd), 2) AS promedio_fob_por_declaracion
FROM declaracion_aduanera d
WHERE d.fecha_registro BETWEEN '2026-10-01' AND '2026-10-31'
GROUP BY d.regimen
ORDER BY valor_fob_acumulado_usd DESC;
SELECT 
    b.codigo_bodega,
    b.nombre AS nombre_bodega,
    p.nombre AS pais_origen,
    prod.codigo_sku,
    prod.descripcion AS descripcion_mercancia,
    inv.cantidad_actual,
    prod.unidad_medida,
    inv.estado_stock,
    d.numero_dua
FROM inventario inv
INNER JOIN bodega b ON inv.id_bodega = b.id_bodega
INNER JOIN producto prod ON inv.id_producto = prod.id_producto
INNER JOIN declaracion_aduanera d ON inv.id_declaracion = d.id_declaracion
INNER JOIN pais p ON d.id_pais_origen = p.id_pais
WHERE inv.estado_stock = 'Retenido'
ORDER BY b.codigo_bodega ASC, inv.cantidad_actual DESC;
SELECT 
    p.nombre AS pais_origen,
    p.codigo_iso,
    COUNT(c.id_contenedor) AS total_contenedores,
    SUM(c.peso_bruto_kg) AS peso_bruto_total_kg,
    ROUND(AVG(c.peso_bruto_kg), 2) AS peso_promedio_kg
FROM contenedor c
INNER JOIN declaracion_aduanera d ON c.id_declaracion = d.id_declaracion
INNER JOIN pais p ON d.id_pais_origen = p.id_pais
GROUP BY p.nombre, p.codigo_iso
HAVING COUNT(c.id_contenedor) > 0
ORDER BY total_contenedores DESC, peso_bruto_total_kg DESC;
SELECT 
    op.nombre_razon_social,
    op.nit_ruc,
    op.calificacion_riesgo,
    COUNT(d.id_declaracion) AS cantidad_declaraciones,
    SUM(d.total_fob_usd) AS total_fob_declarado_usd,
    SUM(d.total_arancel_usd) AS arancel_total_pagado_usd
FROM importador_exportador op
INNER JOIN declaracion_aduanera d ON op.id_operador = d.id_operador
GROUP BY op.id_operador, op.nombre_razon_social, op.nit_ruc, op.calificacion_riesgo
ORDER BY total_fob_declarado_usd DESC
LIMIT 5;
SELECT 
    i.numero_acta,
    i.fecha_inspeccion,
    i.tipo_inspeccion,
    i.resultado,
    d.numero_dua,
    f.nombre_completo AS inspector_responsable,
    f.cargo AS cargo_inspector,
    COALESCE(sup.nombre_completo, 'Dirección Superior') AS supervisor_a_cargo,
    i.observaciones
FROM inspeccion i
INNER JOIN declaracion_aduanera d ON i.id_declaracion = d.id_declaracion
INNER JOIN funcionario f ON i.id_funcionario = f.id_funcionario
LEFT JOIN funcionario sup ON f.id_supervisor = sup.id_funcionario
WHERE i.resultado IN ('Con observaciones', 'Decomiso preventivo')
ORDER BY i.fecha_inspeccion DESC;
SELECT 
    prod.codigo_sku,
    prod.descripcion AS producto,
    cat.descripcion_oficial AS categoria,
    COUNT(DISTINCT inv.id_bodega) AS bodegas_presente,
    SUM(inv.cantidad_actual) AS stock_total,
    prod.unidad_medida,
    STRING_AGG(DISTINCT b.codigo_bodega, ', ') AS bodegas_ubicacion
FROM inventario inv
INNER JOIN producto prod ON inv.id_producto = prod.id_producto
INNER JOIN categoria_arancelaria cat ON prod.id_categoria = cat.id_categoria
INNER JOIN bodega b ON inv.id_bodega = b.id_bodega
GROUP BY prod.id_producto, prod.codigo_sku, prod.descripcion, cat.descripcion_oficial, prod.unidad_medida
ORDER BY stock_total DESC;
SELECT 
    cat.capitulo AS capitulo_sa,
    cat.codigo_partida,
    cat.descripcion_oficial AS descripcion_partida,
    COUNT(det.id_detalle) AS cantidad_operaciones,
    SUM(det.valor_total_fob) AS base_imponible_fob_usd,
    SUM(det.arancel_aplicado_usd) AS arancel_total_recaudado_usd
FROM detalle_declaracion det
INNER JOIN producto prod ON det.id_producto = prod.id_producto
INNER JOIN categoria_arancelaria cat ON prod.id_categoria = cat.id_categoria
GROUP BY cat.capitulo, cat.codigo_partida, cat.descripcion_oficial
HAVING SUM(det.arancel_aplicado_usd) > 0
ORDER BY arancel_total_recaudado_usd DESC;
SELECT 
    m.id_movimiento,
    m.fecha_movimiento,
    m.tipo_movimiento,
    prod.descripcion AS producto_movido,
    m.cantidad,
    COALESCE(bo.codigo_bodega, 'Externo / Entrada') AS bodega_origen,
    COALESCE(bd.codigo_bodega, 'Levante / Despacho') AS bodega_destino,
    f.nombre_completo AS funcionario_autorizador,
    m.motivo
FROM movimiento_inventario m
INNER JOIN inventario inv ON m.id_inventario = inv.id_inventario
INNER JOIN producto prod ON inv.id_producto = prod.id_producto
LEFT JOIN bodega bo ON m.id_bodega_origen = bo.id_bodega
LEFT JOIN bodega bd ON m.id_bodega_destino = bd.id_bodega
INNER JOIN funcionario f ON m.autorizado_por = f.id_funcionario
ORDER BY m.fecha_movimiento DESC;
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'n8n_readonly') THEN
        CREATE ROLE n8n_readonly WITH LOGIN PASSWORD 'AduanaSegura2026!';
    END IF;
END
$$;
GRANT CONNECT ON DATABASE aduana_lab3 TO n8n_readonly;
GRANT USAGE ON SCHEMA public TO n8n_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO n8n_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO n8n_readonly;
