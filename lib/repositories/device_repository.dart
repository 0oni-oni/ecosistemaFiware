import '../models/device_model.dart';

abstract class DeviceRepository {
  Future<List<DeviceModel>> getDevices();
  Future<void> registerDevice(DeviceModel device);
  Future<void> updateMetadata(DeviceModel device);
  Future<void> deleteDevice(String deviceId);
}
