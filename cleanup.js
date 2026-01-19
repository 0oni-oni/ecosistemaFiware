require('dotenv').config();
const FiwareClient = require('./fiwareClient');

/**
 * Script para limpiar las entidades de prueba
 */
async function cleanup() {
  console.log('=== Limpieza de entidades de prueba ===\n');

  const orionUrl = process.env.ORION_URL || 'http://localhost:1026';
  const fiwareService = process.env.FIWARE_SERVICE || 'openiot';
  const fiwareServicePath = process.env.FIWARE_SERVICEPATH || '/';

  const client = new FiwareClient(orionUrl, fiwareService, fiwareServicePath);

  try {
    console.log('Eliminando entidad TempSensor001...');
    const result = await client.deleteEntity('TempSensor001');
    
    if (result.success) {
      console.log('✓ Entidad eliminada exitosamente');
    } else if (result.error === 'Entity not found') {
      console.log('⚠ La entidad no existe');
    }
  } catch (error) {
    console.error('❌ Error durante la limpieza:');
    console.error(error.message);
  }
}

cleanup();
