class EcosystemConfig {
  final String id; // "smartlab", "campus_norte", etc.
  final String nombre; // Nombre legible
  final String orionBaseUrl; // http://ip:1026
  final String iotAgentBaseUrl; // http://ip:4041 ó 7896 etc.
  final String fiwareService; // smartlab
  final String fiwareServicePath; // /
  final String apiKey; // 1234 u otra
  final List<String> protocolos; // ["HTTP", "MQTT", "COAP"]

  EcosystemConfig({
    required this.id,
    required this.nombre,
    required this.orionBaseUrl,
    required this.iotAgentBaseUrl,
    required this.fiwareService,
    required this.fiwareServicePath,
    required this.apiKey,
    required this.protocolos,
  });

  // consultar datos
  factory EcosystemConfig.parseMap(Map<String, dynamic> json) {
    return EcosystemConfig(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      orionBaseUrl: json['orion_base_url'] as String,
      iotAgentBaseUrl: json['iot_agent_base_url'] as String,
      fiwareService: json['fiware_service'] as String,
      fiwareServicePath: json['fiware_service_path'] as String,
      apiKey: json['api_key'] as String,
      protocolos: List<String>.from(json['protocolos'] as List<dynamic>),
    );
  }

  // enviar datos
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'orion_base_url': orionBaseUrl,
      'iot_agent_base_url': iotAgentBaseUrl,
      'fiware_service': fiwareService,
      'fiware_service_path': fiwareServicePath,
      'api_key': apiKey,
      'protocolos': protocolos,
    };
  }

  // útil para cambiar solo una parte
  EcosystemConfig copyWith({
    String? id,
    String? nombre,
    String? orionBaseUrl,
    String? iotAgentBaseUrl,
    String? fiwareService,
    String? fiwareServicePath,
    String? apiKey,
    List<String>? protocolos,
  }) {
    return EcosystemConfig(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      orionBaseUrl: orionBaseUrl ?? this.orionBaseUrl,
      iotAgentBaseUrl: iotAgentBaseUrl ?? this.iotAgentBaseUrl,
      fiwareService: fiwareService ?? this.fiwareService,
      fiwareServicePath: fiwareServicePath ?? this.fiwareServicePath,
      apiKey: apiKey ?? this.apiKey,
      protocolos: protocolos ?? this.protocolos,
    );
  }
}
