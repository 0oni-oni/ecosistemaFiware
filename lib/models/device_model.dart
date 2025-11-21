class DeviceModel {
  final String deviceId;
  final String entityName;
  final String entityType;
  final String protocol;
  final String transport;

  // Atributos y comandos opcionales
  final List<dynamic>? attributes;
  final List<dynamic>? commands;

  // Nuevos campos para temperatura, humedad, etc.
  final dynamic lastValue; // puede ser Number o String
  final DateTime? lastUpdate;

  DeviceModel({
    required this.deviceId,
    required this.entityName,
    required this.entityType,
    required this.protocol,
    required this.transport,
    this.attributes,
    this.commands,
    this.lastValue,
    this.lastUpdate,
  });

  // ------------------------
  // Crear objeto desde JSON
  // ------------------------
  factory DeviceModel.parseMap(Map<String, dynamic> json) {
    return DeviceModel(
      deviceId: json["device_id"] ?? "",
      entityName: json["entity_name"] ?? "",
      entityType: json["entity_type"] ?? "",
      protocol: json["protocol"] ?? "",
      transport: json["transport"] ?? "",
      attributes: json["attributes"] ?? [],
      commands: json["commands"] ?? [],

      // Datos de gemelo digital
      lastValue: json["lastValue"],
      lastUpdate: json["lastUpdate"] != null
          ? DateTime.tryParse(json["lastUpdate"])
          : null,
    );
  }

  // ------------------------
  // Convertir a JSON
  // ------------------------
  Map<String, dynamic> toJson() {
    return {
      "device_id": deviceId,
      "entity_name": entityName,
      "entity_type": entityType,
      "protocol": protocol,
      "transport": transport,
      "attributes": attributes?.toList() ?? [],
      "commands": commands?.toList() ?? [],

      // Si es null, no enviamos nada
      "lastValue": lastValue,
      "lastUpdate": lastUpdate?.toIso8601String(),
    };
  }
}
