import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final opciones = [
      {"titulo": "Inicio", "icono": Icons.home, "ruta": "/"},
      {"titulo": "Dispositivos", "icono": Icons.sensors, "ruta": "/devices"},
    ];

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Row(
              children: [
                const Icon(Icons.hub, color: Colors.white, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Ecosistema FIWARE",
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: opciones.length,
              itemBuilder: (context, index) {
                final op = opciones[index];
                return ListTile(
                  leading: Icon(op["icono"] as IconData),
                  title: Text(op["titulo"] as String),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, op["ruta"] as String);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
