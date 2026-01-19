/**
 * Ejemplo de uso del cliente FIWARE
 * Este archivo muestra cómo usar el cliente de forma programática
 */

require('dotenv').config();
const FiwareClient = require('./fiwareClient');

async function ejemplo() {
  // Crear cliente FIWARE
  const client = new FiwareClient(
    process.env.ORION_URL || 'http://localhost:1026',
    process.env.FIWARE_SERVICE || 'openiot',
    process.env.FIWARE_SERVICEPATH || '/'
  );

  try {
    // Ejemplo 1: Crear entidad de una habitación
    console.log('Ejemplo 1: Crear entidad de habitación');
    const habitacion = {
      id: 'Room001',
      type: 'Room',
      temperature: {
        type: 'Number',
        value: 22.5,
        metadata: {
          unit: { type: 'Text', value: 'Celsius' }
        }
      },
      pressure: {
        type: 'Number',
        value: 1013,
        metadata: {
          unit: { type: 'Text', value: 'hPa' }
        }
      },
      humidity: {
        type: 'Number',
        value: 45
      }
    };
    
    await client.createEntity(habitacion);
    console.log('✓ Habitación creada\n');

    // Ejemplo 2: Consultar la entidad
    console.log('Ejemplo 2: Consultar entidad');
    const room = await client.getEntity('Room001');
    console.log('Temperatura:', room.temperature.value, '°C');
    console.log('Presión:', room.pressure.value, 'hPa');
    console.log('Humedad:', room.humidity.value, '%\n');

    // Ejemplo 3: Actualizar temperatura
    console.log('Ejemplo 3: Actualizar temperatura');
    await client.updateAttribute('Room001', 'temperature', 24.0);
    const updated = await client.getEntity('Room001');
    console.log('Nueva temperatura:', updated.temperature.value, '°C\n');

    // Ejemplo 4: Listar todas las habitaciones
    console.log('Ejemplo 4: Listar habitaciones');
    const rooms = await client.listEntities('Room');
    console.log(`Total de habitaciones: ${rooms.length}\n`);

    // Ejemplo 5: Limpiar - Eliminar entidad
    console.log('Ejemplo 5: Eliminar entidad');
    await client.deleteEntity('Room001');
    console.log('✓ Habitación eliminada');

  } catch (error) {
    console.error('Error:', error.message);
  }
}

// Descomentar para ejecutar el ejemplo
// ejemplo();

module.exports = ejemplo;
