import 'package:flutter/material.dart';

class HistorialAcceso {
  final String id;
  final DateTime fecha;
  final String tarjetaId;
  final String personaNombre;
  final String dispositivoId;
  final bool autorizado;

  HistorialAcceso({
    required this.id,
    required this.fecha,
    required this.tarjetaId,
    required this.personaNombre,
    required this.dispositivoId,
    required this.autorizado,
  });

  factory HistorialAcceso.fromJson(Map<String, dynamic> json) {
    return HistorialAcceso(
      // ✅ CORREGIDO: id puede ser String o int desde CrateDB
      id: json['id']?.toString() ?? '',
      // ✅ CORREGIDO: Manejo robusto de fecha (string o DateTime)
      fecha: json['fecha'] is String
          ? DateTime.parse(json['fecha'])
          : DateTime.now(),
      tarjetaId: json['tarjeta_id']?.toString() ?? 'N/A',
      personaNombre: json['persona_nombre']?.toString() ?? 'Desconocido',
      dispositivoId: json['dispositivo_id']?.toString() ?? 'N/A',
      // ✅ CORREGIDO: Manejo de bool (puede venir como 0/1 desde CrateDB)
      autorizado: json['autorizado'] == true || json['autorizado'] == 1,
    );
  }

  Color get statusColor =>
      autorizado ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

  IconData get statusIcon => autorizado ? Icons.check_circle : Icons.cancel;

  // ✅ NUEVO: Para facilitar debugging
  @override
  String toString() {
    return 'HistorialAcceso{id: $id, fecha: $fecha, persona: $personaNombre, autorizado: $autorizado}';
  }
}
