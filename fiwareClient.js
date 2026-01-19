const axios = require('axios');

/**
 * Cliente para interactuar con FIWARE Orion Context Broker
 */
class FiwareClient {
  constructor(orionUrl, fiwareService = 'openiot', fiwareServicePath = '/') {
    this.orionUrl = orionUrl;
    this.headers = {
      'Content-Type': 'application/json',
      'fiware-service': fiwareService,
      'fiware-servicepath': fiwareServicePath
    };
  }

  /**
   * Crear una nueva entidad en Orion
   */
  async createEntity(entity) {
    try {
      const response = await axios.post(
        `${this.orionUrl}/v2/entities`,
        entity,
        { headers: this.headers }
      );
      return { success: true, status: response.status };
    } catch (error) {
      if (error.response?.status === 422) {
        return { success: false, error: 'Entity already exists' };
      }
      throw error;
    }
  }

  /**
   * Obtener una entidad por ID
   */
  async getEntity(entityId) {
    try {
      const response = await axios.get(
        `${this.orionUrl}/v2/entities/${entityId}`,
        { headers: this.headers }
      );
      return response.data;
    } catch (error) {
      if (error.response?.status === 404) {
        return null;
      }
      throw error;
    }
  }

  /**
   * Listar todas las entidades
   */
  async listEntities(type = null) {
    try {
      const params = type ? { type } : {};
      const response = await axios.get(
        `${this.orionUrl}/v2/entities`,
        { 
          headers: this.headers,
          params
        }
      );
      return response.data;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Actualizar un atributo de una entidad
   */
  async updateAttribute(entityId, attributeName, value) {
    try {
      // Determinar el Content-Type basado en el tipo de valor
      const contentType = (typeof value === 'object' && value !== null) ? 'application/json' : 'text/plain';
      
      const response = await axios.put(
        `${this.orionUrl}/v2/entities/${entityId}/attrs/${attributeName}/value`,
        value,
        { 
          headers: {
            ...this.headers,
            'Content-Type': contentType
          }
        }
      );
      return { success: true, status: response.status };
    } catch (error) {
      if (error.response?.status === 404) {
        return { success: false, error: 'Entity or attribute not found' };
      }
      throw error;
    }
  }

  /**
   * Eliminar una entidad
   */
  async deleteEntity(entityId) {
    try {
      const response = await axios.delete(
        `${this.orionUrl}/v2/entities/${entityId}`,
        { headers: this.headers }
      );
      return { success: true, status: response.status };
    } catch (error) {
      if (error.response?.status === 404) {
        return { success: false, error: 'Entity not found' };
      }
      throw error;
    }
  }

  /**
   * Verificar conexión con Orion
   */
  async checkConnection() {
    try {
      const response = await axios.get(`${this.orionUrl}/version`);
      return { 
        connected: true, 
        version: response.data 
      };
    } catch (error) {
      return { 
        connected: false, 
        error: error.message 
      };
    }
  }
}

module.exports = FiwareClient;
