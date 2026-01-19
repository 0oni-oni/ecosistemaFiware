// lib/models/dispositivo.dart

class Dispositivo {
  final String deviceId;
  final String? entityName;
  final String? entityType;
  final String protocolo;
  final DateTime? fechaRegistro;

  // ✅ NUEVOS CAMPOS (Fase 1)
  final String? tipoDetectado; // "acceso", "sensor", etc.
  final bool requiereValidacion; // true para A:, B:, C:
  final DispositivoNotas? notas; // Metadata opcional
  final String refDevice;

  Dispositivo({
    required this.deviceId,
    this.entityName,
    this.entityType,
    required this.protocolo,
    this.fechaRegistro,
    this.tipoDetectado,
    this.requiereValidacion = false,
    this.notas,
    required this.refDevice,
  });

  factory Dispositivo.fromJson(Map<String, dynamic> json) {
    return Dispositivo(
      deviceId: json['device_id'] as String,
      refDevice:
          json['refDevice'] ?? json['ref_device'] ?? json['device_id'] ?? '',
      entityName: json['entity_name'] as String?,
      entityType: json['entity_type'] as String?,
      protocolo:
          json['protocol'] as String? ?? json['transport'] as String? ?? 'MQTT',
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'])
          : null,

      // ✅ Nuevos campos
      tipoDetectado: json['tipo_detectado'] as String?,
      requiereValidacion: json['requiere_validacion'] as bool? ?? false,
      notas: json['notas'] != null
          ? DispositivoNotas.fromJson(json['notas'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'refDevice': refDevice,
      if (entityName != null) 'entity_name': entityName,
      if (entityType != null) 'entity_type': entityType,
      'protocol': protocolo,
      if (fechaRegistro != null)
        'fecha_registro': fechaRegistro!.toIso8601String(),
      if (tipoDetectado != null) 'tipo_detectado': tipoDetectado,
      'requiere_validacion': requiereValidacion,
      if (notas != null) 'notas': notas!.toJson(),
    };
  }

  // ✅ HELPERS
  bool get esControlAcceso =>
      tipoDetectado == 'acceso' ||
      tipoDetectado == 'accesoB' ||
      tipoDetectado == 'accesoC' ||
      requiereValidacion;

  String get tipoLegible {
    switch (tipoDetectado) {
      case 'acceso':
        return 'Control de Acceso';
      case 'accesoB':
        return 'Control de Acceso B';
      case 'accesoC':
        return 'Control de Acceso C';
      case 'sensor':
        return 'Sensor IoT';
      default:
        return tipoDetectado ?? 'Dispositivo';
    }
  }

  String get codigoTipo {
    if (deviceId.contains(':')) {
      return deviceId.split(':')[0];
    }
    return 'N/A';
  }
}

// ✅ NUEVA CLASE: Notas de Dispositivo
class DispositivoNotas {
  final String? ubicacion;
  final String? responsable;
  final String? notas;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DispositivoNotas({
    this.ubicacion,
    this.responsable,
    this.notas,
    this.createdAt,
    this.updatedAt,
  });

  factory DispositivoNotas.fromJson(Map<String, dynamic> json) {
    return DispositivoNotas(
      ubicacion: json['ubicacion'] as String?,
      responsable: json['responsable'] as String?,
      notas: json['notas'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (ubicacion != null) 'ubicacion': ubicacion,
      if (responsable != null) 'responsable': responsable,
      if (notas != null) 'notas': notas,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

// ✅ NUEVO: Tipos de dispositivos disponibles
class TipoDispositivo {
  final String codigo;
  final String nombre;
  final bool requiereValidacion;
  final String descripcion;

  TipoDispositivo({
    required this.codigo,
    required this.nombre,
    required this.requiereValidacion,
    required this.descripcion,
  });

  factory TipoDispositivo.fromJson(String codigo, Map<String, dynamic> json) {
    return TipoDispositivo(
      codigo: codigo,
      nombre: json['nombre'] as String,
      requiereValidacion: json['requiere_validacion'] as bool? ?? false,
      descripcion: json['descripcion'] as String? ?? '',
    );
  }
}
