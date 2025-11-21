import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  final List<Map<String, dynamic>> opciones = const [
    {
      "titulo": "Inicio",
      "icono": Icons.dashboard,
      "ruta": "/",
      "color": Colors.blue,
    },
    {
      "titulo": "Dispositivos",
      "icono": Icons.memory,
      "ruta": "/devices",
      "color": Colors.orange,
    },
    {
      "titulo": "Registrar Dispositivo",
      "icono": Icons.add_circle,
      "ruta": "/devices/form",
      "color": Colors.green,
    },
    {
      "titulo": "Ecosistemas",
      "icono": Icons.cloud,
      "ruta": "/ecosistemas",
      "color": Colors.indigo,
    },
    {
      "titulo": "Monitoreo",
      "icono": Icons.monitor_heart,
      "ruta": "/monitor",
      "color": Colors.red,
    },
    {
      "titulo": "Suscripciones",
      "icono": Icons.notifications_active,
      "ruta": "/suscripciones",
      "color": Colors.cyan,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.black87),
            child: Row(
              children: const [
                Icon(Icons.devices_other, color: Colors.white, size: 40),
                SizedBox(width: 10),
                Text(
                  "FIWARE Ecosystem",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: opciones.length,
              itemBuilder: (context, index) {
                final o = opciones[index];
                return ListTile(
                  leading: Icon(o["icono"], color: o["color"]),
                  title: Text(o["titulo"]),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, o["ruta"]);
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
