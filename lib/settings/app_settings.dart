import '../models/ecosystem_config_model.dart';

class AppSettings {
  // lista de ecosistemas soportados
  static final List<EcosystemConfig> ecosystems = [
    EcosystemConfig(
      id: 'smartlab',
      nombre: 'SmartLab UTC',
      orionBaseUrl: 'http://13.59.176.23:1026',
      iotAgentBaseUrl: 'http://13.59.176.23:4041',
      fiwareService: 'smartlab',
      fiwareServicePath: '/',
      apiKey: '1234',
      protocolos: ['HTTP', 'MQTT'],
    ),
    // aquí puedes agregar más ecosistemas en el futuro
  ];

  // ecosistema actual (puede cambiar desde una pantalla de ajustes)
  static EcosystemConfig current = ecosystems.first;
}
