// lib/repositories/base_repository.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/settings/api_config.dart';

/// Repositorio base que elimina duplicación de código
abstract class BaseRepository extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Setter para isLoading con notificación
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Setter para error con notificación
  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Limpiar estado de error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Ejecutar petición GET
  Future<T?> executeGet<T>({
    required String token,
    required String endpoint,
    required T Function(dynamic) parser,
    String errorMessage = 'Error al cargar datos',
  }) async {
    isLoading = true;
    error = null;

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        isLoading = false;
        return parser(data);
      } else {
        error = '$errorMessage: ${response.statusCode}';
        isLoading = false;
        return null;
      }
    } catch (e) {
      error = 'Error de conexión: $e';
      isLoading = false;
      return null;
    }
  }

  /// Ejecutar petición POST
  Future<bool> executePost({
    required String token,
    required String endpoint,
    required Map<String, dynamic> body,
    String errorMessage = 'Error al crear',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: ApiConfig.getHeaders(token: token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      error = '$errorMessage: $e';
      notifyListeners();
      return false;
    }
  }

  /// Ejecutar petición PUT
  Future<bool> executePut({
    required String token,
    required String endpoint,
    required Map<String, dynamic> body,
    String errorMessage = 'Error al actualizar',
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: ApiConfig.getHeaders(token: token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      return response.statusCode == 200;
    } catch (e) {
      error = '$errorMessage: $e';
      notifyListeners();
      return false;
    }
  }

  /// Ejecutar petición DELETE
  Future<bool> executeDelete({
    required String token,
    required String endpoint,
    String errorMessage = 'Error al eliminar',
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      return response.statusCode == 200;
    } catch (e) {
      error = '$errorMessage: $e';
      notifyListeners();
      return false;
    }
  }
}
