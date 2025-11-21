import 'package:dio/dio.dart';

import '../models/device_model.dart';
import '../settings/app_settings.dart';
import 'device_repository.dart';

class FiwareDeviceRepository implements DeviceRepository {
  final Dio _dio = Dio();

  FiwareDeviceRepository() {
    // Timeouts mejorados para FIWARE
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
  }

  /// Encabezados FIWARE
  Map<String, String> _headers() {
    final eco = AppSettings.current;
    return {
      'Content-Type': 'application/json',
      'Fiware-Service': eco.fiwareService,
      'Fiware-ServicePath': eco.fiwareServicePath,
    };
  }

  // ==========================================================
  // GET DEVICES (LISTADO)
  // ==========================================================
  @override
  Future<List<DeviceModel>> getDevices() async {
    final eco = AppSettings.current;

    final url = '${eco.iotAgentBaseUrl}/iot/devices?limit=100';

    print("📡 Consultando dispositivos desde: $url");

    try {
      final response = await _dio.get(
        url,
        options: Options(headers: _headers()),
      );

      print("📨 Respuesta de FIWARE → Status: ${response.statusCode}");

      final json = response.data;

      if (json == null || json is! Map) {
        print("⚠ Respuesta inesperada: $json");
        return [];
      }

      if (json['devices'] == null) {
        print("ℹ No hay dispositivos registrados");
        return [];
      }

      final list = json['devices'] as List<dynamic>;

      final devices = list
          .map((e) => DeviceModel.parseMap(e as Map<String, dynamic>))
          .toList();

      print("✅ Total dispositivos: ${devices.length}");
      return devices;
    } catch (e) {
      print("🔥 Error en GET /iot/devices: $e");
      throw Exception("No se pudo obtener la lista de dispositivos.");
    }
  }

  // ==========================================================
  // REGISTER DEVICE
  // ==========================================================
  @override
  Future<void> registerDevice(DeviceModel device) async {
    final eco = AppSettings.current;
    final url = '${eco.iotAgentBaseUrl}/iot/devices';

    final payload = {
      "devices": [device.toJson()],
    };

    print("📡 Registrando dispositivo en: $url");
    print("📦 Payload → $payload");

    try {
      final response = await _dio.post(
        url,
        data: payload,
        options: Options(headers: _headers()),
      );

      print("📨 Respuesta FIWARE: ${response.statusCode}");
    } catch (e) {
      print("🔥 Error al registrar dispositivo: $e");
      throw Exception("No se pudo registrar el dispositivo.");
    }
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    // FUTURO:
    // DELETE /iot/devices/{deviceId}
  }
}
