# Prototipo de App Conectada a FIWARE

Este es un prototipo de aplicación Node.js que demuestra cómo conectarse e interactuar con FIWARE Orion Context Broker usando la API NGSIv2.

## 📋 Descripción

Esta aplicación prototipo demuestra las operaciones básicas de FIWARE:
- ✅ Verificación de conexión con Orion Context Broker
- ✅ Creación de entidades (ejemplo: sensor de temperatura)
- ✅ Consulta de entidades
- ✅ Actualización de atributos
- ✅ Listado de entidades por tipo
- ✅ Eliminación de entidades

## 🚀 Requisitos Previos

- Node.js (versión 14 o superior)
- FIWARE Orion Context Broker ejecutándose (puerto 1026 por defecto)

### Iniciar Orion Context Broker con Docker

Si no tienes Orion ejecutándose, puedes iniciarlo con Docker:

```bash
# Con MongoDB en la misma máquina
docker run -d --name mongodb mongo:4.4
docker run -d --name orion -p 1026:1026 --link mongodb:mongodb fiware/orion:latest -dbhost mongodb

# O con Docker Compose (recomendado - usa el archivo docker-compose.yml incluido)
docker-compose up -d
```

## 📦 Instalación

1. Clonar el repositorio:
```bash
git clone https://github.com/0oni-oni/ecosistemaFiware.git
cd ecosistemaFiware
```

2. Instalar dependencias:
```bash
npm install
```

3. Configurar variables de entorno (opcional):
```bash
cp .env.example .env
# Editar .env con tu configuración si es necesario
```

## ⚙️ Configuración

Puedes configurar la aplicación editando el archivo `.env`:

```env
ORION_URL=http://localhost:1026
FIWARE_SERVICE=openiot
FIWARE_SERVICEPATH=/
```

**Variables disponibles:**
- `ORION_URL`: URL del Orion Context Broker (default: http://localhost:1026)
- `FIWARE_SERVICE`: Nombre del servicio FIWARE (default: openiot)
- `FIWARE_SERVICEPATH`: Ruta del servicio FIWARE (default: /)

## 🎯 Uso

### Ejecutar la aplicación demo:

```bash
npm start
```

La aplicación realizará las siguientes acciones:
1. Verificar conexión con Orion
2. Crear una entidad de ejemplo (sensor de temperatura)
3. Consultar la entidad creada
4. Actualizar el valor de temperatura
5. Verificar la actualización
6. Listar todas las entidades del tipo TemperatureSensor

### Limpiar entidades de prueba:

```bash
node cleanup.js
```

## 📚 Estructura del Proyecto

```
ecosistemaFiware/
├── app.js              # Aplicación principal con demo
├── fiwareClient.js     # Cliente para interactuar con Orion
├── cleanup.js          # Script para limpiar entidades de prueba
├── ejemplo.js          # Ejemplo de uso programático
├── docker-compose.yml  # Configuración Docker para Orion y MongoDB
├── package.json        # Dependencias del proyecto
├── .env.example        # Ejemplo de configuración
├── .gitignore          # Archivos ignorados por git
└── README.md           # Este archivo
```

## 🔧 API del Cliente FIWARE

La clase `FiwareClient` proporciona los siguientes métodos:

### `checkConnection()`
Verifica la conexión con Orion y obtiene información de versión.

### `createEntity(entity)`
Crea una nueva entidad en Orion.

### `getEntity(entityId)`
Obtiene una entidad por su ID.

### `listEntities(type)`
Lista todas las entidades, opcionalmente filtradas por tipo.

### `updateAttribute(entityId, attributeName, value)`
Actualiza el valor de un atributo específico.

### `deleteEntity(entityId)`
Elimina una entidad por su ID.

## 📖 Ejemplo de Uso del Cliente

```javascript
const FiwareClient = require('./fiwareClient');

const client = new FiwareClient('http://localhost:1026', 'openiot', '/');

// Crear una entidad
const entity = {
  id: 'Room001',
  type: 'Room',
  temperature: {
    type: 'Number',
    value: 22.5
  }
};

await client.createEntity(entity);

// Consultar la entidad
const room = await client.getEntity('Room001');
console.log(room);

// Actualizar temperatura
await client.updateAttribute('Room001', 'temperature', 24.0);
```

## 🌐 Recursos de FIWARE

- [Documentación de FIWARE](https://fiware.org/)
- [Orion Context Broker](https://fiware-orion.readthedocs.io/)
- [NGSIv2 API](https://fiware.github.io/specifications/ngsiv2/stable/)
- [FIWARE Tutorials](https://fiware-tutorials.readthedocs.io/)

## 📄 Licencia

MIT