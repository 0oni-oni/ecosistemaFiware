import 'package:dio/dio.dart';

import '../models/device_model.dart';
import '../settings/app_settings.dart';
import 'device_repository.dart';

class FiwareDeviceRepository implements DeviceRepository {
  final Dio _dio = Dio();

  FiwareDeviceRepository() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
  }

  Map<String, String> _headers() {
    final eco = AppSettings.current;
    return {
      'Content-Type': 'application/json',
      'Fiware-Service': eco.fiwareService,
      'Fiware-ServicePath': eco.fiwareServicePath,
    };
  }

  @override
  Future<List<DeviceModel>> getDevices() async {
    final eco = AppSettings.current;
    final url = "${eco.orionBaseUrl}/v2/entities?type=Sensor&options=keyValues";

    try {
      final res = await _dio.get(url, options: Options(headers: _headers()));

      if (res.statusCode == 200 && res.data is List) {
        final list = res.data as List;
        return list
            .map(
              (e) => DeviceModel.fromOrionKeyValues(e as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print("Error getDevices: $e");
      return [];
    }
  }

  @override
  Future<void> registerDevice(DeviceModel device) async {
    final eco = AppSettings.current;
    final url = "${eco.iotAgentBaseUrl}/iot/devices";

    final payload = {
      "devices": [device.toIoTAgentJson()],
    };

    print("POST $url");
    print("Payload: $payload");

    try {
      await _dio.post(
        url,
        data: payload,
        options: Options(headers: _headers()),
      );
    } catch (e) {
      print("Error registerDevice: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateMetadata(DeviceModel device) async {
    final eco = AppSettings.current;
    final url = "${eco.orionBaseUrl}/v2/entities/${device.entityId}/attrs";

    final payload = {
      "metadata_info": {
        "type": "StructuredValue",
        "value": device.toMetadataInfoValue(),
      },
    };

    print("PATCH $url");
    print("Payload: $payload");

    try {
      await _dio.patch(
        url,
        data: payload,
        options: Options(headers: _headers()),
      );
    } catch (e) {
      print("Error updateMetadata: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    // FUTURO: DELETE en IoT Agent / Orion
    // por ahora, no implementamos borrado
  }
}
