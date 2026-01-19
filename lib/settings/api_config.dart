// lib/settings/api_config.dart
class ApiConfig {
  // ⚠️ CAMBIAR ESTA IP POR LA DE TU SERVIDOR AWS
  static const String baseUrl = 'https://ecosistemafiware.com';

  // ========================================
  // ENDPOINTS BÁSICOS
  // ========================================
  static const String loginEndpoint = '/accesos/login';
  static const String personasEndpoint = '/accesos/personas';
  static const String tarjetasEndpoint = '/accesos/tarjetas';
  static const String dispositivosEndpoint = '/dispositivos';
  static const String historialEndpoint = '/accesos/historial';
  static const String validarEndpoint = '/accesos/validar';
  static const String usuariosEndpoint = '/accesos/usuarios';

  // ========================================
  // DISPOSITIVOS
  // ========================================
  static const String dispositivosTipos = '/dispositivos/tipos';
  static String dispositivoNotas(String deviceId) =>
      '/dispositivos/$deviceId/notas';

  // ========================================
  // FIWARE
  // ========================================
  static const String entidadesEndpoint = '/entidades';
  static const String historicoFiware = '/historico';

  // ========================================
  // CRATEDB EXPLORER
  // ========================================
  static const String crateTablas = '/crate/tablas';
  static const String crateColumnas = '/crate/tabla';
  static const String crateDatos = '/crate/tabla';
  static const String crateEstadisticas = '/crate/tabla';

  // ========================================
  // ✅ NUEVO: DATOS POR HORA
  // ========================================
  static String crateDatosHora(String schema, String nombre) =>
      '/crate/tabla/$schema/$nombre/datos-hora';

  // ========================================
  // TIMEOUTS
  // ========================================
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // ========================================
  // HEADERS
  // ========================================
  static Map<String, String> getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ========================================
  // HELPER: Construir URL con query params
  // ========================================
  static String buildUrlWithParams(
    String endpoint,
    Map<String, String?> params,
  ) {
    final uri = Uri.parse('$baseUrl$endpoint');
    final filteredParams = Map<String, String>.fromEntries(
      params.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!)),
    );
    return uri.replace(queryParameters: filteredParams).toString();
  }
}
