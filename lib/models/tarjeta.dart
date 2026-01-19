import 'package:flutter/material.dart';

class Tarjeta {
  final String id;
  final String estado;
  final int? personaId;
  final String? personaNombre;
  final DateTime? fechaEntrega;
  final DateTime? fechaBaja;

  Tarjeta({
    required this.id,
    required this.estado,
    this.personaId,
    this.personaNombre,
    this.fechaEntrega,
    this.fechaBaja,
  });

  factory Tarjeta.fromJson(Map<String, dynamic> json) {
    return Tarjeta(
      id: json['id'] as String,
      estado: json['estado'] as String,
      personaId: json['persona_id'] as int?,
      personaNombre: json['persona_nombre'] as String?,
      fechaEntrega: json['fecha_entrega'] != null
          ? DateTime.parse(json['fecha_entrega'])
          : null,
      fechaBaja: json['fecha_baja'] != null
          ? DateTime.parse(json['fecha_baja'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'estado': estado, 'persona_id': personaId};
  }

  Color get estadoColor {
    switch (estado.toLowerCase()) {
      case 'activo':
        return const Color(0xFF4CAF50);
      case 'baja':
        return const Color(0xFFFF9800);
      case 'perdida':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
