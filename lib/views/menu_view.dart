import 'package:flutter/material.dart';

import 'devices/device_list_view.dart';
import 'widgets/app_drawer.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text("Panel Ecosistema FIWARE")),
      drawer: const AppDrawer(),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isWide ? 32 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hub, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                "SmartLab UTC - Monitoreo FIWARE",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeviceListView()),
                  );
                },
                icon: const Icon(Icons.sensors),
                label: const Text("Ver dispositivos"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
