require('dotenv').config();
const FiwareClient = require('./fiwareClient');

/**
 * Aplicación prototipo conectada a FIWARE
 */
async function main() {
  console.log('=== Prototipo de App conectada a FIWARE ===\n');

  // Configuración desde variables de entorno
  const orionUrl = process.env.ORION_URL || 'http://localhost:1026';
  const fiwareService = process.env.FIWARE_SERVICE || 'openiot';
  const fiwareServicePath = process.env.FIWARE_SERVICEPATH || '/';

  console.log(`Conectando a Orion Context Broker en: ${orionUrl}`);
  console.log(`FIWARE-Service: ${fiwareService}`);
  console.log(`FIWARE-ServicePath: ${fiwareServicePath}\n`);

  // Crear cliente FIWARE
  const client = new FiwareClient(orionUrl, fiwareService, fiwareServicePath);

  try {
    // 1. Verificar conexión
    console.log('1. Verificando conexión con Orion...');
    const connection = await client.checkConnection();
    if (!connection.connected) {
      console.error(`❌ No se pudo conectar a Orion: ${connection.error}`);
      console.log('\nAsegúrate de que Orion Context Broker esté ejecutándose.');
      console.log('Puedes iniciarlo con Docker:');
      console.log('docker run -d -p 1026:1026 fiware/orion:latest -dbhost host.docker.internal');
      return;
    }
    console.log('✓ Conexión exitosa');
    console.log(`  Versión de Orion: ${JSON.stringify(connection.version)}\n`);

    // 2. Crear una entidad de ejemplo (sensor de temperatura)
    console.log('2. Creando entidad de ejemplo (Sensor de Temperatura)...');
    const sensorEntity = {
      id: 'TempSensor001',
      type: 'TemperatureSensor',
      temperature: {
        type: 'Number',
        value: 23.5,
        metadata: {
          unit: {
            type: 'Text',
            value: 'Celsius'
          }
        }
      },
      location: {
        type: 'geo:json',
        value: {
          type: 'Point',
          coordinates: [-3.7038, 40.4168] // Madrid
        }
      },
      status: {
        type: 'Text',
        value: 'active'
      }
    };

    const createResult = await client.createEntity(sensorEntity);
    if (createResult.success) {
      console.log('✓ Entidad creada exitosamente\n');
    } else if (createResult.error === 'Entity already exists') {
      console.log('⚠ La entidad ya existe, continuando...\n');
    }

    // 3. Consultar la entidad
    console.log('3. Consultando la entidad creada...');
    const entity = await client.getEntity('TempSensor001');
    if (entity) {
      console.log('✓ Entidad recuperada:');
      console.log(JSON.stringify(entity, null, 2));
      console.log();
    }

    // 4. Actualizar un atributo
    console.log('4. Actualizando temperatura del sensor...');
    const updateResult = await client.updateAttribute('TempSensor001', 'temperature', 25.8);
    if (updateResult.success) {
      console.log('✓ Temperatura actualizada a 25.8°C\n');
    }

    // 5. Consultar entidad actualizada
    console.log('5. Verificando actualización...');
    const updatedEntity = await client.getEntity('TempSensor001');
    if (updatedEntity) {
      console.log(`✓ Nueva temperatura: ${updatedEntity.temperature.value}°C\n`);
    }

    // 6. Listar todas las entidades
    console.log('6. Listando todas las entidades de tipo TemperatureSensor...');
    const entities = await client.listEntities('TemperatureSensor');
    console.log(`✓ Se encontraron ${entities.length} entidades:`);
    entities.forEach(e => {
      console.log(`  - ${e.id}: ${e.temperature.value}°C`);
    });
    console.log();

    console.log('=== Demo completada exitosamente ===');
    console.log('\nNOTA: La entidad TempSensor001 permanece en Orion.');
    console.log('Para eliminarla, ejecuta: node cleanup.js');

  } catch (error) {
    console.error('❌ Error durante la ejecución:');
    console.error(error.message);
    if (error.response) {
      console.error('Detalles:', error.response.data);
    }
  }
}

// Ejecutar la aplicación
main();
