// lib/repositories/historial_repository.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/settings/api_config.dart';
import '/models/historial_acceso.dart';

class HistorialRepository extends ChangeNotifier {
  // ========================================
  // PROPIEDADES ORIGINALES (NO BORRAR)
  // ========================================
  List<HistorialAcceso> _historial = [];
  bool _isLoading = false;
  String? _error;

  List<HistorialAcceso> get historial => _historial;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========================================
  // ✅ NUEVA PROPIEDAD PARA ACCESOS VIEW
  // ========================================
  List<Map<String, dynamic>> _historialAccesos = [];

  List<Map<String, dynamic>> get historialAccesos => _historialAccesos;

  // ========================================
  // MÉTODOS ORIGINALES (NO BORRAR)
  // ========================================

  /// Método original: fetchHistorial
  Future<bool> fetchHistorial(String token, {int limit = 100}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.historialEndpoint}?limit=$limit',
            ),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _historial = data
            .map((json) => HistorialAcceso.fromJson(json))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Error al cargar historial: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<HistorialAcceso> getHistorialPorDispositivo(String dispositivoId) {
    return _historial.where((h) => h.dispositivoId == dispositivoId).toList();
  }

  List<HistorialAcceso> getHistorialAutorizado() {
    return _historial.where((h) => h.autorizado).toList();
  }

  List<HistorialAcceso> getHistorialNoAutorizado() {
    return _historial.where((h) => !h.autorizado).toList();
  }

  List<HistorialAcceso> getHistorialHoy() {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    return _historial.where((h) {
      final fecha = DateTime(h.fecha.year, h.fecha.month, h.fecha.day);
      return fecha.isAtSameMomentAs(hoy);
    }).toList();
  }

  // ========================================
  // ✅ NUEVO MÉTODO PARA ACCESOS VIEW
  // ========================================

  /// Obtiene el historial de accesos como Map (para la nueva vista)
  Future<void> fetchHistorialAccesos(String token, {int limit = 100}) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/accesos/historial',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await http
          .get(uri, headers: ApiConfig.getHeaders(token: token))
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _historialAccesos = data.cast<Map<String, dynamic>>();
        notifyListeners();
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error en fetchHistorialAccesos: $e');
      rethrow;
    }
  }

  /// Limpia el historial local
  void clearHistorial() {
    _historial = [];
    _historialAccesos = [];
    notifyListeners();
  }
}
