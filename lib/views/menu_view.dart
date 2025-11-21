import 'package:flutter/material.dart';
import 'widgets/app_drawer.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  final List<Map<String, dynamic>> opciones = const [
    {
      "titulo": "Dispositivos",
      "icono": Icons.devices,
      "ruta": "/devices",
      "color": Colors.blue,
    },
    {
      "titulo": "Crear Dispositivo",
      "icono": Icons.add_circle_outline,
      "ruta": "/devices/form",
      "color": Colors.green,
    },
    {
      "titulo": "Monitoreo",
      "icono": Icons.monitor_heart,
      "ruta": "/monitor",
      "color": Colors.red,
    },
    {
      "titulo": "Ecosistemas",
      "icono": Icons.cloud,
      "ruta": "/ecosistemas",
      "color": Colors.indigo,
    },
    {
      "titulo": "Suscripciones",
      "icono": Icons.notifications_active,
      "ruta": "/suscripciones",
      "color": Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ecosistema FIWARE"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: opciones.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemBuilder: (context, index) {
            final o = opciones[index];
            return Card(
              elevation: 10,
              color: o["color"],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pushNamed(context, o["ruta"]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(o["icono"], size: 50, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      o["titulo"],
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
