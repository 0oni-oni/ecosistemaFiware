class DeviceModel {
  final String deviceId;
  final String entityId;
  final String entityType;
  final String protocol;
  final String transport;

  final dynamic lastValue;
  final DateTime? lastUpdate;

  final Map<String, dynamic> metadataInfo;

  DeviceModel({
    required this.deviceId,
    required this.entityId,
    required this.entityType,
    required this.protocol,
    required this.transport,
    this.lastValue,
    this.lastUpdate,
    required this.metadataInfo,
  });

  String get displayName {
    return (metadataInfo['nombre_modulo'] as String?) ?? entityId;
  }

  String get ubicacion {
    return (metadataInfo['ubicacion'] as String?) ?? 'Sin ubicación';
  }

  String get exactLocation {
    return (metadataInfo['exact_location'] as String?) ?? '';
  }

  String get modeloSensor {
    return (metadataInfo['modelo_sensor'] as String?) ?? '';
  }

  String get datoEnvio {
    return (metadataInfo['dato_envio'] as String?) ?? '';
  }

  String get nota {
    return (metadataInfo['nota'] as String?) ?? '';
  }

  /// --- PARSE DESDE ORION (keyValues) ---
  factory DeviceModel.fromOrionKeyValues(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final type = json['type']?.toString() ?? '';

    dynamic value =
        json['temperature'] ?? json['humidity'] ?? json['tag'] ?? json['value'];

    DateTime? ts;
    final ti = json['TimeInstant'];
    if (ti is String) {
      ts = DateTime.tryParse(ti);
    }

    final metadata = <String, dynamic>{};
    if (json['metadata_info'] is Map<String, dynamic>) {
      metadata.addAll(json['metadata_info']);
    }

    return DeviceModel(
      deviceId: id,
      entityId: id,
      entityType: type,
      protocol: 'PDI-IoTA-JSON',
      transport: 'MQTT',
      lastValue: value,
      lastUpdate: ts,
      metadataInfo: metadata,
    );
  }

  /// JSON para IoT Agent
  Map<String, dynamic> toIoTAgentJson() {
    return {
      "device_id": deviceId,
      "entity_name": entityId,
      "entity_type": entityType,
      "protocol": protocol,
      "transport": transport,
      "attributes": [],
      "commands": [],
    };
  }

  /// JSON para Orion (patch metadata)
  Map<String, dynamic> toMetadataInfoValue() {
    return metadataInfo;
  }

  DeviceModel copyWith({Map<String, dynamic>? metadataInfo}) {
    return DeviceModel(
      deviceId: deviceId,
      entityId: entityId,
      entityType: entityType,
      protocol: protocol,
      transport: transport,
      lastValue: lastValue,
      lastUpdate: lastUpdate,
      metadataInfo: metadataInfo ?? this.metadataInfo,
    );
  }
}
