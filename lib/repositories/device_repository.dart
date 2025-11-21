import '../models/device_model.dart';

abstract class DeviceRepository {
  /// Registrar un dispositivo en el ecosistema actual
  Future<void> registerDevice(DeviceModel device);

  /// FUTURO: obtener dispositivos
  Future<List<DeviceModel>> getDevices();

  /// FUTURO: eliminar dispositivo
  Future<void> deleteDevice(String deviceId);
}
