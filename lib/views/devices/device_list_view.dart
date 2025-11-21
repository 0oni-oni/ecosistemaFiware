import 'package:flutter/material.dart';
import 'dart:async';

import 'package:ionicons/ionicons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/device_model.dart';
import '../../repositories/fiware_device_repository.dart';
import '../../repositories/orion_repository.dart';
import 'device_form_view.dart';

class DeviceListView extends StatefulWidget {
  const DeviceListView({super.key});

  @override
  State<DeviceListView> createState() => _DeviceListViewState();
}

class _DeviceListViewState extends State<DeviceListView> {
  final repo = FiwareDeviceRepository();
  final orion = OrionRepository();

  List<DeviceModel> devices = [];
  Map<String, Map<String, dynamic>> entityData = {};

  bool loading = true;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDevices();

    // 🔄 actualización cada 0.5s
    refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _refreshEntities();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() => loading = true);

    final data = await repo.getDevices();
    devices = data;

    await _refreshEntities();
    setState(() => loading = false);
  }

  Future<void> _refreshEntities() async {
    for (var d in devices) {
      final entity = await orion.getEntity(d.entityName);
      if (entity != null) {
        setState(() => entityData[d.entityName] = entity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dispositivos FIWARE"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : devices.isEmpty
          ? const Center(child: Text("No hay dispositivos registrados"))
          : Padding(
              padding: EdgeInsets.all(isWide ? 32 : 16),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.35 : 2.4,
                ),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final d = devices[index];
                  final entity = entityData[d.entityName];

                  final temp = entity?["temperature"]?["value"];
                  final instant =
                      entity?["temperature"]?["metadata"]?["TimeInstant"]?["value"];

                  DateTime? ecuTime;
                  if (instant != null) {
                    final utc = DateTime.parse(instant);
                    ecuTime = utc.subtract(const Duration(hours: 5));
                  }

                  // ONLINE / OFFLINE
                  bool isOnline = false;
                  if (ecuTime != null) {
                    final diff = DateTime.now().difference(ecuTime).inSeconds;
                    isOnline = diff < 10;
                  }

                  // COLOR E ICONO PARA TEMPERATURA
                  Color tempColor = Colors.green;
                  IconData tempIcon = Ionicons.thermometer_outline;

                  if (temp != null) {
                    if (temp < 15) {
                      tempColor = Colors.blue.shade600;
                      tempIcon = Ionicons.snow_outline;
                    } else if (temp <= 25) {
                      tempColor = Colors.green.shade700;
                      tempIcon = Ionicons.thermometer_outline;
                    } else if (temp <= 35) {
                      tempColor = Colors.orange.shade700;
                      tempIcon = Ionicons.flame_outline;
                    } else {
                      tempColor = Colors.red.shade800;
                      tempIcon = Ionicons.warning_outline;
                    }
                  }

                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d.entityName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                isOnline
                                    ? Ionicons.wifi_outline
                                    : Ionicons.cloud_offline_outline,
                                color: isOnline ? Colors.green : Colors.grey,
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text("ID: ${d.deviceId}"),
                          Text("Tipo: ${d.entityType}"),
                          Text("Protocolo: ${d.protocol}"),
                          Text("Transporte: ${d.transport}"),

                          const SizedBox(height: 15),

                          // TEMPERATURA + ICONO + ANIMACIÓN
                          Row(
                            children: [
                              Icon(tempIcon, color: tempColor, size: 26),
                              const SizedBox(width: 8),
                              Text(
                                    temp != null
                                        ? "${temp.toString()} °C"
                                        : "N/A",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: tempColor,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .scale(duration: 300.ms),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Text(
                            ecuTime != null
                                ? "Actualizado: ${ecuTime.toString().split('.').first}"
                                : "Actualizado: N/A",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),

                          const Spacer(),

                          Align(
                            alignment: Alignment.bottomRight,
                            child: Icon(
                              Ionicons.pulse_outline,
                              color: Colors.blue.shade700,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeviceFormView()),
          );
          _loadDevices();
        },
        label: const Text("Nuevo Dispositivo"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
