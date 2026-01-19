class Persona {
  final int id;
  final String nombre;
  final String cedula;
  final String rol;
  final String? tarjetaId;

  Persona({
    required this.id,
    required this.nombre,
    required this.cedula,
    required this.rol,
    this.tarjetaId,
  });

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      cedula: json['cedula'] as String,
      rol: json['rol'] as String,
      tarjetaId: json['tarjeta_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'cedula': cedula,
      'rol': rol,
      'tarjeta_id': tarjetaId,
    };
  }
}
