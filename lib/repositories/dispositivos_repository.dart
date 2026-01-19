// lib/repositories/dispositivos_repository.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/settings/api_config.dart';
import '/models/dispositivo.dart';

class DispositivosRepository extends ChangeNotifier {
  List<Dispositivo> _dispositivos = [];
  Map<String, TipoDispositivo> _tiposDisponibles = {};
  bool _isLoading = false;
  String? _error;

  List<Dispositivo> get dispositivos => _dispositivos;
  Map<String, TipoDispositivo> get tiposDisponibles => _tiposDisponibles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========================================
  // ✅ NUEVO: Obtener tipos disponibles
  // ========================================
  Future<bool> fetchTiposDispositivos(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dispositivosTipos}'),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> tipos = data['tipos'] ?? {};

        _tiposDisponibles = tipos.map((codigo, tipoJson) {
          return MapEntry(codigo, TipoDispositivo.fromJson(codigo, tipoJson));
        });

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error obteniendo tipos: $e');
      return false;
    }
  }

  // ========================================
  // OBTENER LISTA DE DISPOSITIVOS
  // ========================================
  Future<bool> fetchDispositivos(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dispositivosEndpoint}/'),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _dispositivos = data.map((json) => Dispositivo.fromJson(json)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Error al cargar dispositivos: ${response.statusCode}';
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

  // ========================================
  // ✅ NUEVO: Obtener notas de un dispositivo
  // ========================================
  Future<DispositivoNotas?> fetchNotasDispositivo(
    String token,
    String deviceId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.dispositivoNotas(deviceId)}',
            ),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DispositivoNotas.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error obteniendo notas: $e');
      return null;
    }
  }

  // ========================================
  // ✅ NUEVO: Actualizar notas de un dispositivo
  // ========================================
  Future<bool> actualizarNotasDispositivo(
    String token,
    String deviceId, {
    String? ubicacion,
    String? responsable,
    String? notas,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (ubicacion != null) payload['ubicacion'] = ubicacion;
      if (responsable != null) payload['responsable'] = responsable;
      if (notas != null) payload['notas'] = notas;

      final response = await http
          .put(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.dispositivoNotas(deviceId)}',
            ),
            headers: ApiConfig.getHeaders(token: token),
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        // Actualizar dispositivo en la lista local
        final index = _dispositivos.indexWhere((d) => d.deviceId == deviceId);
        if (index != -1) {
          await fetchDispositivos(token); // Recargar lista completa
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error actualizando notas: $e';
      notifyListeners();
      return false;
    }
  }

  // ========================================
  // ELIMINAR DISPOSITIVO (Mejorado)
  // ========================================
  Future<Map<String, dynamic>> eliminarDispositivo(
    String token,
    String deviceId,
  ) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.dispositivosEndpoint}/$deviceId',
            ),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Remover de la lista local
        _dispositivos.removeWhere((d) => d.deviceId == deviceId);
        notifyListeners();

        return {
          'success': true,
          'detalles': result['detalles'],
          'mensaje': result['mensaje'],
        };
      }

      return {
        'success': false,
        'mensaje': 'Error ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      _error = 'Error al eliminar dispositivo: $e';
      notifyListeners();
      return {'success': false, 'mensaje': 'Error de conexión: $e'};
    }
  }

  // ========================================
  // CREAR DISPOSITIVO
  // ========================================
  Future<Map<String, dynamic>> crearDispositivo({
    required String token,
    required String deviceId,
    required String entityName,
    required String entityType,
    required String transport,
    required List<Map<String, String>> attributes,
    String? ubicacion,
    String? responsable,
    String? notas,
    bool dedicatedTable = false,
    String apiKey = 'smartlab_key',
  }) async {
    try {
      final payload = {
        'device_id': deviceId,
        'entity_name': entityName,
        'entity_type': entityType,
        'transport': transport,
        'attributes': attributes,
        'service_api_key': apiKey,
        'dedicated_table': dedicatedTable,
        // ✅ Nuevos campos opcionales
        if (ubicacion != null && ubicacion.isNotEmpty) 'ubicacion': ubicacion,
        if (responsable != null && responsable.isNotEmpty)
          'responsable': responsable,
        if (notas != null && notas.isNotEmpty) 'notas': notas,
      };

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dispositivosEndpoint}'),
            headers: ApiConfig.getHeaders(token: token),
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);

        // Recargar lista
        await fetchDispositivos(token);

        return {
          'success': true,
          'data': result,
          'mensaje': 'Dispositivo creado correctamente',
        };
      }

      return {
        'success': false,
        'mensaje': 'Error ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'mensaje': 'Error de conexión: $e'};
    }
  }

  // ========================================
  // HELPERS
  // ========================================
  Dispositivo? getDispositivoById(String deviceId) {
    try {
      return _dispositivos.firstWhere((d) => d.deviceId == deviceId);
    } catch (e) {
      return null;
    }
  }

  List<Dispositivo> getDispositivosPorTipo(String tipo) {
    return _dispositivos.where((d) => d.tipoDetectado == tipo).toList();
  }

  List<Dispositivo> getDispositivosControlAcceso() {
    return _dispositivos.where((d) => d.requiereValidacion).toList();
  }

  List<Dispositivo> getDispositivosSensor() {
    return _dispositivos.where((d) => !d.requiereValidacion).toList();
  }
}
