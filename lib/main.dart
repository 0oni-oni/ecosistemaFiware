import 'package:ecosistema/views/ecosystems/ecosystem_list_view.dart';
import 'package:flutter/material.dart';

import 'views/menu_view.dart';
import 'views/devices/device_list_view.dart';
import 'views/devices/device_form_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const MenuView(),

        // Dispositivos
        '/devices': (context) => const DeviceListView(),
        '/devices/form': (context) => const DeviceFormView(),
        '/ecosistemas': (context) => const EcosystemListView(),

        // Estas se agregarán más adelante
        // '/ecosistemas': (_) => EcosystemListView(),
        // '/monitor': (_) => MonitorDashboardView(),
        // '/suscripciones': (_) => SubscriptionListView(),
      },
    );
  }
}
