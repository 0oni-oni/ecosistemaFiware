import 'package:flutter/material.dart';
import '../../settings/app_settings.dart';

class EcosystemListView extends StatelessWidget {
  const EcosystemListView({super.key});

  @override
  Widget build(BuildContext context) {
    final ecosistemas = AppSettings.ecosystems;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ecosistemas FIWARE"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: ecosistemas.length,
        itemBuilder: (context, index) {
          final eco = ecosistemas[index];

          return Card(
            margin: const EdgeInsets.all(12),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(eco.nombre),
              subtitle: Text(eco.orionBaseUrl),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                AppSettings.current = eco;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Ecosistema activado: ${eco.nombre}"),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
