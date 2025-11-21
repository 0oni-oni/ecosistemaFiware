import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/device_model.dart';
import '../../repositories/fiware_device_repository.dart';

class DeviceListView extends StatefulWidget {
  const DeviceListView({super.key});

  @override
  State<DeviceListView> createState() => _DeviceListViewState();
}

class _DeviceListViewState extends State<DeviceListView> {
  final repo = FiwareDeviceRepository();

  List<DeviceModel> devices = [];
  bool loading = true;

  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();

    refreshTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _load(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await repo.getDevices();
    if (!mounted) return;

    setState(() {
      devices = data;
      loading = false;
    });
  }

  String formatToEcuador(DateTime? dt) {
    if (dt == null) return "—";
    final ecu = dt.toUtc().subtract(const Duration(hours: 5));
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(ecu);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(title: const Text("Dispositivos FIWARE")),
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
                  childAspectRatio: isWide ? 1.4 : 2.5,
                ),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final d = devices[index];

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // FUTURO: navegar a detalle
                        // Navigator.push(... DeviceDetailView(device: d));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.ubicacion,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            if (d.exactLocation.isNotEmpty)
                              Text(
                                d.exactLocation,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text("Entidad: ${d.entityId}"),
                            Text("Tipo: ${d.entityType}"),
                            const SizedBox(height: 8),
                            if (d.lastValue != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.sensors,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${d.lastValue}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 4),
                            Text(
                              "Actualizado: ${formatToEcuador(d.lastUpdate)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Icon(
                                Icons.device_hub,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/devices/new');
        },
        icon: const Icon(Icons.add),
        label: const Text("Nuevo dispositivo"),
      ),
    );
  }
}
