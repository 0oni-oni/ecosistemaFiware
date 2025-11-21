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
  final _deviceIdController = TextEditingController();
  final _entityNameController = TextEditingController();
  final _entityTypeController = TextEditingController(text: 'Sensor');
  final _protocolController = TextEditingController(text: 'PDI-IoTA-JSON');

  String _transport = 'MQTT'; // o 'HTTP'

  final _repo = FiwareDeviceRepository();

  bool _loading = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _entityNameController.dispose();
    _entityTypeController.dispose();
    _protocolController.dispose();
    super.dispose();
  }

  void _autoFillEntityName() {
    final id = _deviceIdController.text.trim();
    if (id.isNotEmpty) {
      _entityNameController.text = 'Sensor:$id';
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final device = DeviceModel(
      deviceId: _deviceIdController.text.trim(),
      entityName: _entityNameController.text.trim(),
      entityType: _entityTypeController.text.trim(),
      protocol: _protocolController.text.trim(),
      transport: _transport,
      // ya no pasamos attributes ni commands porque el modelo actual no los tiene
    );

    try {
      await _repo.registerDevice(device);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispositivo registrado correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar dispositivo: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar dispositivo FIWARE')),
      body: Padding(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
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
                        controller: _deviceIdController,
                        decoration: const InputDecoration(
                          labelText: 'Device ID',
                          hintText: 'Ej: temp001, rfid001',
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _autoFillEntityName(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese un ID de dispositivo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _entityNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de entidad (Orion)',
                          hintText: 'Ej: Sensor:temp001',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese el nombre de la entidad';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _entityTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de entidad',
                          hintText: 'Ej: Sensor, Thing',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese el tipo de entidad';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _protocolController,
                        decoration: const InputDecoration(
                          labelText: 'Protocolo',
                          hintText: 'Ej: PDI-IoTA-JSON',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese el protocolo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _transport,
                        decoration: const InputDecoration(
                          labelText: 'Transporte',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'MQTT', child: Text('MQTT')),
                          DropdownMenuItem(value: 'HTTP', child: Text('HTTP')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _transport = value);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _onSave,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _loading ? 'Guardando...' : 'Guardar dispositivo',
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
