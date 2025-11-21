import '../models/ecosystem_config_model.dart';

class AppSettings {
  static final List<EcosystemConfig> ecosystems = [
    EcosystemConfig(
      id: 'smartlab',
      nombre: 'SmartLab UTC',

      // Orion Context Broker
      orionBaseUrl: 'http://13.59.176.23:1026',

      // IoT Agent JSON
      iotAgentBaseUrl: 'http://13.59.176.23:4041',

      // QuantumLeap para históricos
      quantumLeapBaseUrl: 'http://13.59.176.23:8668',

      fiwareService: 'smartlab',
      fiwareServicePath: '/',
      apiKey: '1234',

      protocolos: ['HTTP', 'MQTT'],
    ),
  ];

  static EcosystemConfig current = ecosystems.first;
}
