// lib/views/crate_explorer/crate_explorer_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/repositories/auth_repository.dart';
import '/repositories/crate_repository.dart';
import '/models/tabla_crate.dart';
import 'tabla_datos_view.dart';

class CrateExplorerView extends StatefulWidget {
  const CrateExplorerView({Key? key}) : super(key: key);

  @override
  State<CrateExplorerView> createState() => _CrateExplorerViewState();
}

class _CrateExplorerViewState extends State<CrateExplorerView> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = context.read<AuthRepository>().token;
    if (token != null) {
      await context.read<CrateRepository>().fetchTablas(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Consumer<CrateRepository>(
        builder: (context, crateRepo, _) {
          if (crateRepo.isLoading && crateRepo.tablas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (crateRepo.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(crateRepo.error!),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (crateRepo.tablas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.table_chart, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay tablas disponibles'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Título
              Text(
                'Explorador CrateDB',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${crateRepo.tablas.length} tablas disponibles',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Lista de tablas
              ...crateRepo.tablas.map((tabla) {
                return _buildTablaCard(context, tabla);
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTablaCard(BuildContext context, TablaCrate tabla) {
    final esAccesos = tabla.nombre == 'etaccessevent';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: esAccesos
              ? Colors.blue.withOpacity(0.1)
              : Colors.green.withOpacity(0.1),
          child: Icon(
            esAccesos ? Icons.lock_clock : Icons.sensors,
            color: esAccesos ? Colors.blue : Colors.green,
          ),
        ),
        title: Text(
          tabla.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schema: ${tabla.schema}'),
            Text('Shards: ${tabla.shards} | Réplicas: ${tabla.replicas}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        isThreeLine: true,
        onTap: () => _verDatosTabla(context, tabla),
      ),
    );
  }

  void _verDatosTabla(BuildContext context, TablaCrate tabla) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TablaDatosView(tabla: tabla)),
    );
  }
}
