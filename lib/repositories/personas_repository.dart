// lib/repositories/personas_repository.dart
import '/models/persona.dart';
import '/repositories/base_repository.dart';

class PersonasRepository extends BaseRepository {
  List<Persona> _personas = [];

  List<Persona> get personas => _personas;

  /// Obtener todas las personas (refactorizado con base)
  Future<bool> fetchPersonas(String token) async {
    final result = await executeGet<List<Persona>>(
      token: token,
      endpoint: '/accesos/personas',
      parser: (data) {
        return (data as List).map((json) => Persona.fromJson(json)).toList();
      },
      errorMessage: 'Error al cargar personas',
    );

    if (result != null) {
      _personas = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Crear nueva persona (refactorizado)
  Future<bool> crearPersona(
    String token, {
    required String nombre,
    required String cedula,
    required String rol,
  }) async {
    final success = await executePost(
      token: token,
      endpoint: '/accesos/personas',
      body: {'nombre': nombre, 'cedula': cedula, 'rol': rol},
      errorMessage: 'Error al crear persona',
    );

    if (success) {
      await fetchPersonas(token);
    }
    return success;
  }

  /// Actualizar persona (refactorizado)
  Future<bool> actualizarPersona(
    String token, {
    required int personaId,
    required String nombre,
    required String cedula,
    required String rol,
  }) async {
    final success = await executePut(
      token: token,
      endpoint: '/accesos/personas/$personaId',
      body: {'nombre': nombre, 'cedula': cedula, 'rol': rol},
      errorMessage: 'Error al actualizar persona',
    );

    if (success) {
      await fetchPersonas(token);
    }
    return success;
  }

  /// Eliminar persona (refactorizado)
  Future<bool> eliminarPersona(String token, int personaId) async {
    final success = await executeDelete(
      token: token,
      endpoint: '/accesos/personas/$personaId',
      errorMessage: 'Error al eliminar persona',
    );

    if (success) {
      await fetchPersonas(token);
    }
    return success;
  }

  /// Obtener persona por ID
  Persona? getPersonaPorId(int id) {
    try {
      return _personas.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtener personas por rol
  List<Persona> getPersonasPorRol(String rol) {
    return _personas.where((p) => p.rol == rol).toList();
  }
}
