// lib/repositories/crate_repository.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/settings/api_config.dart';
import '/models/tabla_crate.dart';

class CrateRepository extends ChangeNotifier {
  List<TablaCrate> _tablas = [];
  List<Map<String, dynamic>> _datos = [];
  List<String> _columnas = [];
  EstadisticasTabla? _estadisticas;
  bool _isLoading = false;
  String? _error;

  List<TablaCrate> get tablas => _tablas;
  List<Map<String, dynamic>> get datos => _datos;
  List<String> get columnas => _columnas;
  EstadisticasTabla? get estadisticas => _estadisticas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> fetchTablas(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.crateTablas}'),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tablas = data.map((json) => TablaCrate.fromJson(json)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Error al cargar tablas: ${response.statusCode}';
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

  Future<bool> fetchDatosTabla(
    String token,
    String schema,
    String nombre, {
    int limit = 100,
    int offset = 0,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.crateDatos}/$schema/$nombre/datos?limit=$limit&offset=$offset',
            ),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _columnas = List<String>.from(data['columnas'] ?? []);
        _datos = List<Map<String, dynamic>>.from(data['datos'] ?? []);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Error al cargar datos: ${response.statusCode}';
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

  Future<bool> fetchEstadisticas(
    String token,
    String schema,
    String nombre,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.crateEstadisticas}/$schema/$nombre/estadisticas',
            ),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _estadisticas = EstadisticasTabla.fromJson(data);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return false;
    }
  }
}
