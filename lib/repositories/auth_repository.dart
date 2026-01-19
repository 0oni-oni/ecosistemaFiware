// lib/repositories/auth_repository.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/settings/api_config.dart';
import '/models/usuario.dart';

class AuthRepository extends ChangeNotifier {
  String? _token;
  Usuario? _currentUser;
  bool _isLoading = false;

  String? get token => _token;
  Usuario? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  AuthRepository() {
    _loadToken();
    _setupAppLifecycleListener();
  }

  void _setupAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(
      _AppLifecycleObserver(
        onDetached: () async {
          await logout();
          print('🔒 App cerrada - Sesión limpiada');
        },
      ),
    );
  }

  Future<void> _loadToken() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    if (_token != null) {
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        _currentUser = Usuario.fromJson(jsonDecode(userJson));
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('🧹 Cache limpiado');

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'username': username, 'password': password},
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];

        // Guardar token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);

        // Obtener información del usuario
        await _fetchCurrentUser();

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ Error en login: $e');
      return false;
    }
  }

  // ✅ CAMBIO CRÍTICO: Usar endpoint /me en lugar de /usuarios
  Future<void> _fetchCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/accesos/me'), // ✅ CAMBIO AQUÍ
        headers: ApiConfig.getHeaders(token: _token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = jsonDecode(
          response.body,
        ); // ✅ Map en lugar de List
        _currentUser = Usuario.fromJson(userData); // ✅ Objeto directo

        // Guardar usuario
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'current_user',
          jsonEncode(_currentUser!.toJson()),
        );

        print(
          '✅ Usuario obtenido: ${_currentUser!.username} (${_currentUser!.role})',
        );
      }
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
    }
  }

  Future<void> logout() async {
    print('🔓 Cerrando sesión...');
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');

    notifyListeners();
    print('✅ Sesión cerrada');
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onDetached;

  _AppLifecycleObserver({required this.onDetached});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      onDetached();
    }
  }
}
