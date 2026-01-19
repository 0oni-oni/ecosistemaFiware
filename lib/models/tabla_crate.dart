// lib/models/tabla_crate.dart

class TablaCrate {
  final String schema;
  final String nombre;
  final String nombreCompleto;
  final int shards;
  final String replicas;

  TablaCrate({
    required this.schema,
    required this.nombre,
    required this.nombreCompleto,
    required this.shards,
    required this.replicas,
  });

  factory TablaCrate.fromJson(Map<String, dynamic> json) {
    return TablaCrate(
      schema: json['schema'] as String,
      nombre: json['nombre'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      shards: json['shards'] as int,
      replicas: json['replicas'].toString(),
    );
  }
}

class EstadisticasTabla {
  final int totalRegistros;
  final String? primeraFecha;
  final String? ultimaFecha;
  final String tabla;

  EstadisticasTabla({
    required this.totalRegistros,
    this.primeraFecha,
    this.ultimaFecha,
    required this.tabla,
  });

  factory EstadisticasTabla.fromJson(Map<String, dynamic> json) {
    return EstadisticasTabla(
      totalRegistros: json['total_registros'] as int,
      primeraFecha: json['primera_fecha'] as String?,
      ultimaFecha: json['ultima_fecha'] as String?,
      tabla: json['tabla'] as String,
    );
  }
}
