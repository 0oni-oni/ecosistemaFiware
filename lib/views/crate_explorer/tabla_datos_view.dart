import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/repositories/auth_repository.dart';
import '/repositories/crate_repository.dart';
import '/models/tabla_crate.dart';

class TablaDatosView extends StatefulWidget {
  final TablaCrate tabla;

  const TablaDatosView({Key? key, required this.tabla}) : super(key: key);

  @override
  State<TablaDatosView> createState() => _TablaDatosViewState();
}

class _TablaDatosViewState extends State<TablaDatosView> {
  @override
  void initState() {
    super.initState();
    // Cargamos datos y estadísticas al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllData());
  }

  Future<void> _loadAllData() async {
    final token = context.read<AuthRepository>().token;
    if (token != null) {
      final repo = context.read<CrateRepository>();
      // Importante: Usamos widget.tabla.schema y widget.tabla.nombre como pide tu Repo
      await Future.wait([
        repo.fetchDatosTabla(token, widget.tabla.schema, widget.tabla.nombre),
        repo.fetchEstadisticas(token, widget.tabla.schema, widget.tabla.nombre),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tabla.nombre, style: const TextStyle(fontSize: 16)),
            Text(
              'Esquema: ${widget.tabla.schema}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
        ],
      ),
      body: Consumer<CrateRepository>(
        builder: (context, crateRepo, _) {
          if (crateRepo.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (crateRepo.error != null) {
            return _buildErrorState(crateRepo.error!);
          }

          return Column(
            children: [
              // Panel de Estadísticas (si están disponibles)
              if (crateRepo.estadisticas != null)
                _buildStatsPanel(crateRepo.estadisticas!),

              // Tabla de Datos
              Expanded(
                child: crateRepo.datos.isEmpty
                    ? const Center(child: Text('No hay registros disponibles'))
                    : _buildDataTable(crateRepo),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsPanel(EstadisticasTabla stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blueGrey.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Total Filas', stats.totalRegistros.toString()),
          if (stats.ultimaFecha != null)
            _statItem('Último Registro', stats.ultimaFecha!.split('T')[0]),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDataTable(CrateRepository repo) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            Colors.blue.withOpacity(0.05),
          ),
          columnSpacing: 20,
          // Usamos las columnas que vienen del repositorio
          columns: repo.columnas.map((col) {
            return DataColumn(
              label: Text(
                col.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
          // Generamos las filas
          rows: repo.datos.map((fila) {
            return DataRow(
              cells: repo.columnas.map((colName) {
                final cellValue = fila[colName];
                return DataCell(
                  Text(
                    cellValue?.toString() ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            TextButton(
              onPressed: _loadAllData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
