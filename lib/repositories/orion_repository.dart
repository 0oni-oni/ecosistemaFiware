import 'package:dio/dio.dart';
import '../settings/app_settings.dart';

class OrionRepository {
  final Dio _dio = Dio();

  OrionRepository() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  Map<String, String> _headers() {
    final eco = AppSettings.current;
    return {
      'Fiware-Service': eco.fiwareService,
      'Fiware-ServicePath': eco.fiwareServicePath,
    };
  }

  Future<Map<String, dynamic>?> getEntity(String entityId) async {
    final eco = AppSettings.current;
    final url = '${eco.orionBaseUrl}/v2/entities/$entityId';

    try {
      final response = await _dio.get(
        url,
        options: Options(headers: _headers()),
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print(" Error consultando Orion: $e");
      return null;
    }
  }

  /// Obtiene el valor de un atributo
  Future<dynamic> getAttributeValue(String entityId, String attribute) async {
    final entity = await getEntity(entityId);
    if (entity == null) return null;

    if (entity[attribute] == null) return null;

    return entity[attribute]["value"];
  }
}
