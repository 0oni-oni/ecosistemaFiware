import 'package:flutter/material.dart';

import '../../models/device_model.dart';
import '../../repositories/fiware_device_repository.dart';

class DeviceFormView extends StatefulWidget {
  const DeviceFormView({super.key});

  @override
  State<DeviceFormView> createState() => _DeviceFormViewState();
}

class _DeviceFormViewState extends State<DeviceFormView> {
  final _formKey = GlobalKey<FormState>();

  final _deviceIdCtrl = TextEditingController();
  final _entityIdCtrl = TextEditingController();
  final _entityTypeCtrl = TextEditingController(text: 'Sensor');
  final _nombreModuloCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _exactLocationCtrl = TextEditingController();
  final _modeloSensorCtrl = TextEditingController();
  final _datoEnvioCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();

  String _protocol = 'PDI-IoTA-JSON';
  String _transport = 'MQTT';

  final _repo = FiwareDeviceRepository();
  bool _saving = false;

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _entityIdCtrl.dispose();
    _entityTypeCtrl.dispose();
    _nombreModuloCtrl.dispose();
    _ubicacionCtrl.dispose();
    _exactLocationCtrl.dispose();
    _modeloSensorCtrl.dispose();
    _datoEnvioCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  void _syncEntityId() {
    if (_entityIdCtrl.text.trim().isEmpty) {
      final id = _deviceIdCtrl.text.trim();
      if (id.isNotEmpty) {
        _entityIdCtrl.text = "Sensor:$id";
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final metadata = <String, dynamic>{
      "nombre_modulo": _nombreModuloCtrl.text.trim(),
      "ubicacion": _ubicacionCtrl.text.trim(),
      "exact_location": _exactLocationCtrl.text.trim(),
      "modelo_sensor": _modeloSensorCtrl.text.trim(),
      "dato_envio": _datoEnvioCtrl.text.trim(),
      "nota": _notaCtrl.text.trim(),
    }..removeWhere((key, value) => value == null || value.toString().isEmpty);

    final device = DeviceModel(
      deviceId: _deviceIdCtrl.text.trim(),
      entityId: _entityIdCtrl.text.trim(),
      entityType: _entityTypeCtrl.text.trim(),
      protocol: _protocol,
      transport: _transport,
      lastValue: null,
      lastUpdate: null,
      metadataInfo: metadata,
    );

    try {
      await _repo.registerDevice(device);
      // FUTURO: enviar también metadata_info a Orion si quieres registrar todo de una vez

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Dispositivo registrado")));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar dispositivo: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo dispositivo FIWARE")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _deviceIdCtrl,
                        decoration: const InputDecoration(
                          labelText: "Device ID",
                          hintText: "temp001, rfid001...",
                        ),
                        onChanged: (_) => _syncEntityId(),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Requerido" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _entityIdCtrl,
                        decoration: const InputDecoration(
                          labelText: "ID de entidad (Orion)",
                          hintText: "Sensor:temp001",
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Requerido" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _entityTypeCtrl,
                        decoration: const InputDecoration(
                          labelText: "Tipo de entidad",
                          hintText: "Sensor, Thing...",
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Requerido" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _protocol,
                        decoration: const InputDecoration(
                          labelText: "Protocolo",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PDI-IoTA-JSON',
                            child: Text('PDI-IoTA-JSON'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _protocol = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _transport,
                        decoration: const InputDecoration(
                          labelText: "Transporte",
                        ),
                        items: const [
                          DropdownMenuItem(value: 'MQTT', child: Text('MQTT')),
                          DropdownMenuItem(value: 'HTTP', child: Text('HTTP')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _transport = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        "Metadatos del dispositivo",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nombreModuloCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nombre del módulo",
                          hintText: "Sensor Entrada Principal",
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ubicacionCtrl,
                        decoration: const InputDecoration(
                          labelText: "Ubicación",
                          hintText: "Laboratorio Redes",
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _exactLocationCtrl,
                        decoration: const InputDecoration(
                          labelText: "Lugar exacto",
                          hintText: "Puerta izquierda, rack superior...",
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _modeloSensorCtrl,
                        decoration: const InputDecoration(
                          labelText: "Modelo de sensor",
                          hintText: "DHT22, MFRC522...",
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _datoEnvioCtrl,
                        decoration: const InputDecoration(
                          labelText: "Dato principal enviado",
                          hintText: "temperatura, humedad, tag...",
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notaCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "Nota",
                          hintText: "Comentarios adicionales",
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _saving ? "Guardando..." : "Registrar dispositivo",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
