import 'package:flutter/material.dart';

import 'views/menu_view.dart';
import 'views/devices/device_list_view.dart';
import 'views/devices/device_form_view.dart';

void main() {
  runApp(const EcosistemaApp());
}

class EcosistemaApp extends StatelessWidget {
  const EcosistemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ecosistema FIWARE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const MenuView(),
        '/devices': (_) => const DeviceListView(),
        '/devices/new': (_) => const DeviceFormView(),
      },
    );
  }
}
