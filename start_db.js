const { EmbeddedPostgres } = require('./db-server/node_modules/embedded-postgres');
const { Client } = require('./db-server/node_modules/pg');
const fs = require('fs');
const path = require('path');

async function main() {
    console.log('[DB-SERVER] Iniciando motor PostgreSQL embebido en Windows...');
    
    const dbPath = path.join(__dirname, 'data_postgres');
    if (!fs.existsSync(dbPath)) {
        fs.mkdirSync(dbPath, { recursive: true });
    }

    const pg = new EmbeddedPostgres({
        databaseDir: dbPath,
        port: 5432,
        user: 'postgres',
        password: 'AduanaPassword2026!',
        persistent: true
    });

    try {
        await pg.initialise();
        console.log('[DB-SERVER] Motor PostgreSQL inicializado.');
    } catch (err) {
        console.log('[DB-SERVER] Inicialización previa detectada o en curso:', err.message);
    }

    await pg.start();
    console.log('[DB-SERVER] PostgreSQL ACTIVO y escuchando en localhost:5432');

    // Conectarse para crear la base de datos aduana_lab3 si no existe
    const clientAdmin = new Client({
        host: 'localhost',
        port: 5432,
        user: 'postgres',
        password: 'AduanaPassword2026!',
        database: 'postgres'
    });

    await clientAdmin.connect();
    const resDb = await clientAdmin.query("SELECT 1 FROM pg_database WHERE datname = 'aduana_lab3'");
    if (resDb.rowCount === 0) {
        console.log('[DB-SERVER] Creando base de datos aduana_lab3...');
        await clientAdmin.query('CREATE DATABASE aduana_lab3');
    }
    await clientAdmin.end();

    // Conectarse a aduana_lab3 para ejecutar el script SQL
    const clientAduana = new Client({
        host: 'localhost',
        port: 5432,
        user: 'postgres',
        password: 'AduanaPassword2026!',
        database: 'aduana_lab3'
    });

    await clientAduana.connect();
    console.log('[DB-SERVER] Ejecutando script Apellido_Nombre_Aduana_Lab3.sql...');

    const sqlScriptPath = path.join(__dirname, 'Apellido_Nombre_Aduana_Lab3.sql');
    const sqlContent = fs.readFileSync(sqlScriptPath, 'utf8');

    // Filtrar comandos específicos de psql interactivo (\c o CREATE DATABASE)
    const cleanSql = sqlContent
        .replace(/CREATE DATABASE aduana_lab3[^;]*;/gi, '-- CREATE DATABASE')
        .replace(/\\c aduana_lab3;?/gi, '-- \\c aduana_lab3');

    await clientAduana.query(cleanSql);
    console.log('[DB-SERVER] ¡Script ejecutado exitosamente!');

    // Verificar cantidad de registros
    const countCheck = await clientAduana.query('SELECT COUNT(*) AS total_mercancias FROM inventario');
    console.log(`[DB-SERVER] Verificación: ${countCheck.rows[0].total_mercancias} registros en inventario.`);

    await clientAduana.end();

    console.log('\n======================================================');
    console.log('🎉 BASE DE DATOS LOCAL LISTA PARA CONECTAR EN N8N:');
    console.log('   Host:     localhost');
    console.log('   Port:     5432');
    console.log('   Database: aduana_lab3');
    console.log('   User:     n8n_readonly (o postgres)');
    console.log('   Password: AduanaSegura2026! (o AduanaPassword2026!)');
    console.log('   SSL:      Desactivado (disable/allow)');
    console.log('======================================================\n');
}

main().catch(err => {
    console.error('[DB-SERVER ERROR]:', err);
});
