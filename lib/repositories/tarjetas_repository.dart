// lib/repositories/tarjetas_repository.dart
import '/models/tarjeta.dart';
import '/repositories/base_repository.dart';

class TarjetasRepository extends BaseRepository {
  List<Tarjeta> _tarjetas = [];

  List<Tarjeta> get tarjetas => _tarjetas;

  /// Obtener todas las tarjetas
  Future<bool> fetchTarjetas(String token) async {
    final result = await executeGet<List<Tarjeta>>(
      token: token,
      endpoint: '/accesos/tarjetas',
      parser: (data) {
        return (data as List).map((json) => Tarjeta.fromJson(json)).toList();
      },
      errorMessage: 'Error al cargar tarjetas',
    );

    if (result != null) {
      _tarjetas = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Crear nueva tarjeta
  Future<bool> crearTarjeta(
    String token, {
    required String id,
    required String estado,
    int? personaId,
  }) async {
    final success = await executePost(
      token: token,
      endpoint: '/accesos/tarjetas',
      body: {'id': id, 'estado': estado, 'persona_id': personaId},
      errorMessage: 'Error al crear tarjeta',
    );

    if (success) {
      await fetchTarjetas(token);
    }
    return success;
  }

  /// Actualizar tarjeta existente
  Future<bool> actualizarTarjeta(
    String token, {
    required String cardId,
    required String estado,
    int? personaId,
  }) async {
    final success = await executePut(
      token: token,
      endpoint: '/accesos/tarjetas/$cardId',
      body: {'estado': estado, 'persona_id': personaId},
      errorMessage: 'Error al actualizar tarjeta',
    );

    if (success) {
      await fetchTarjetas(token);
    }
    return success;
  }

  /// Eliminar tarjeta
  Future<bool> eliminarTarjeta(String token, String cardId) async {
    final success = await executeDelete(
      token: token,
      endpoint: '/accesos/tarjetas/$cardId',
      errorMessage: 'Error al eliminar tarjeta',
    );

    if (success) {
      await fetchTarjetas(token);
    }
    return success;
  }

  /// Obtener tarjetas de una persona específica
  List<Tarjeta> getTarjetasPorPersona(int personaId) {
    return _tarjetas.where((t) => t.personaId == personaId).toList();
  }

  /// Obtener tarjetas activas
  List<Tarjeta> getTarjetasActivas() {
    return _tarjetas.where((t) => t.estado == 'activo').toList();
  }

  /// Obtener tarjeta por ID
  Tarjeta? getTarjetaPorId(String id) {
    try {
      return _tarjetas.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
