// lib/views/analytics/analytics_accesos_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '/repositories/auth_repository.dart';
import '/repositories/analytics_repository.dart';
import '/models/dispositivo.dart';
import '/repositories/dispositivos_repository.dart';

class AnalyticsAccesosView extends StatefulWidget {
  const AnalyticsAccesosView({Key? key}) : super(key: key);

  @override
  State<AnalyticsAccesosView> createState() => _AnalyticsAccesosViewState();
}

class _AnalyticsAccesosViewState extends State<AnalyticsAccesosView> {
  DateTime? _fechaSeleccionada;
  Dispositivo? _dispositivoSeleccionado;
  Map<String, dynamic>? _datosAccesos;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final token = context.read<AuthRepository>().token;
    if (token != null) {
      await context.read<DispositivosRepository>().fetchDispositivos(token);
    }
  }

  Future<void> _abrirCalendario() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        helpText: 'Seleccionar fecha',
        cancelText: 'Cancelar',
        confirmText: 'Aceptar',
      );

      if (picked != null && mounted) {
        setState(() {
          _fechaSeleccionada = picked;
          _cargando = true;
        });
        await _cargarDatosAccesos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cargarDatosAccesos() async {
    if (_fechaSeleccionada == null) {
      setState(() => _cargando = false);
      return;
    }

    final token = context.read<AuthRepository>().token;
    if (token == null) {
      setState(() => _cargando = false);
      return;
    }

    try {
      final analyticsRepo = context.read<AnalyticsRepository>();
      final fechaFormato = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!);

      // Llamar al nuevo endpoint de accesos (lo crearemos después)
      final datos = await analyticsRepo.fetchAccesosPorHora(
        token,
        'mtsmartlab',
        'etaccessevent',
        fechaFormato,
        dispositivoId: _dispositivoSeleccionado?.refDevice,
      );

      if (!mounted) return;

      setState(() {
        _datosAccesos = datos;
        _cargando = false;
      });

      if (datos != null && mounted) {
        final totalAccesos = datos['total_accesos'] ?? 0;
        final exitosos = datos['exitosos'] ?? 0;
        final rechazados = datos['rechazados'] ?? 0;

        String mensaje =
            '✅ $totalAccesos accesos ($exitosos exitosos, $rechazados rechazados)';
        if (_dispositivoSeleccionado != null) {
          mensaje += '\n📡 Dispositivo: ${_dispositivoSeleccionado!.deviceId}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<Dispositivo> _obtenerDispositivosAcceso(List<Dispositivo> todos) {
    return todos
        .where(
          (d) =>
              d.refDevice.toLowerCase().contains('acceso') ||
              d.refDevice.toLowerCase().contains('access') ||
              (d.entityType?.toLowerCase().contains('access') ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics de Accesos',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Análisis de eventos de control de acceso',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                context.watch<AuthRepository>().currentUser?.username ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Configuración
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuración de Análisis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Filtro por dispositivo
                  Consumer<DispositivosRepository>(
                    builder: (context, dispositivosRepo, _) {
                      final dispositivosAcceso = _obtenerDispositivosAcceso(
                        dispositivosRepo.dispositivos,
                      );

                      return DropdownButtonFormField<Dispositivo>(
                        value: _dispositivoSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por Dispositivo (Opcional)',
                          prefixIcon: Icon(Icons.door_front_door),
                          border: OutlineInputBorder(),
                          helperText:
                              'Dejar vacío para ver todos los dispositivos',
                        ),
                        items: [
                          const DropdownMenuItem<Dispositivo>(
                            value: null,
                            child: Text(
                              'Todos los dispositivos',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                          ...dispositivosAcceso.map((dispositivo) {
                            return DropdownMenuItem(
                              value: dispositivo,
                              child: Text(dispositivo.deviceId),
                            );
                          }).toList(),
                        ],
                        onChanged: (dispositivo) {
                          setState(() {
                            _dispositivoSeleccionado = dispositivo;
                            _datosAccesos = null;
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Botón de fecha
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cargando ? null : _abrirCalendario,
                      icon: _cargando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.calendar_today),
                      label: Text(
                        _fechaSeleccionada == null
                            ? 'Seleccionar Fecha'
                            : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Resultados
          if (_datosAccesos != null) ...[
            const SizedBox(height: 16),

            // Estadísticas principales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del Día',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          '${_datosAccesos!['total_accesos'] ?? 0}',
                          'Total',
                          'Eventos',
                          Colors.blue,
                        ),
                        _buildStatCard(
                          '${_datosAccesos!['exitosos'] ?? 0}',
                          'Exitosos',
                          '${(_datosAccesos!['tasa_exito'] ?? 0).toStringAsFixed(1)}%',
                          Colors.green,
                        ),
                        _buildStatCard(
                          '${_datosAccesos!['rechazados'] ?? 0}',
                          'Rechazados',
                          '${(_datosAccesos!['tasa_rechazo'] ?? 0).toStringAsFixed(1)}%',
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Gráfica de accesos por hora
            if (_datosAccesos!['datos'] != null &&
                (_datosAccesos!['datos'] as List).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACCESOS - ${DateFormat('dd MMM yyyy').format(_fechaSeleccionada!)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_dispositivoSeleccionado != null)
                        Text(
                          'Dispositivo: ${_dispositivoSeleccionado!.deviceId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 250,
                        child: _buildAccesosChart(_datosAccesos!['datos']),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Exitosos',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: Colors.red.withOpacity(0.7),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Rechazados',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Lista de personas que ingresaron
            if (_datosAccesos!['personas'] != null &&
                (_datosAccesos!['personas'] as List).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personas que Ingresaron',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (_datosAccesos!['personas'] as List).length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final persona = _datosAccesos!['personas'][index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Text(
                                persona['nombre'][0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(persona['nombre']),
                            subtitle: Text('${persona['accesos']} accesos'),
                            trailing: Text(
                              persona['ultima_hora'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],

          // Mensaje cuando no hay datos
          if (_datosAccesos != null &&
              (_datosAccesos!['datos'] == null ||
                  (_datosAccesos!['datos'] as List).isEmpty))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay accesos para la fecha seleccionada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dispositivoSeleccionado != null
                          ? 'Dispositivo: ${_dispositivoSeleccionado!.deviceId}\n'
                                'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}'
                          : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _buildTablaOrdenableAccesos(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    String subtitle,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          label == 'Total'
              ? Icons.people
              : label == 'Exitosos'
              ? Icons.check_circle
              : Icons.cancel,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAccesosChart(List<dynamic> datos) {
    if (datos.isEmpty) return const SizedBox();

    List<BarChartGroupData> barGroups = [];
    Map<int, dynamic> datosPorHora = {};

    for (var dato in datos) {
      datosPorHora[dato['hora']] = dato;
    }

    double maxY = 0;
    for (int hora = 0; hora < 24; hora++) {
      int exitosos = 0;
      int rechazados = 0;

      if (datosPorHora.containsKey(hora)) {
        exitosos = datosPorHora[hora]['exitosos'] ?? 0;
        rechazados = datosPorHora[hora]['rechazados'] ?? 0;
        double total = (exitosos + rechazados).toDouble();
        if (total > maxY) maxY = total;
      }

      barGroups.add(
        BarChartGroupData(
          x: hora,
          barRods: [
            BarChartRodData(
              toY: exitosos.toDouble() + rechazados.toDouble(),
              rodStackItems: [
                BarChartRodStackItem(0, exitosos.toDouble(), Colors.green),
                BarChartRodStackItem(
                  exitosos.toDouble(),
                  exitosos.toDouble() + rechazados.toDouble(),
                  Colors.red.withOpacity(0.7),
                ),
              ],
              width: 14,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY * 1.15,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                int hora = value.toInt();
                if (hora % 3 != 0) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${hora.toString().padLeft(2, '0')}h',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.grey.withOpacity(0.3)),
            bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
        ),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey.withOpacity(0.95),
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              int hora = group.x;
              if (!datosPorHora.containsKey(hora)) {
                return BarTooltipItem(
                  '${hora.toString().padLeft(2, '0')}:00\nSin accesos',
                  const TextStyle(color: Colors.white70, fontSize: 11),
                );
              }
              final dato = datosPorHora[hora];
              return BarTooltipItem(
                '${hora.toString().padLeft(2, '0')}:00\n'
                '✓ ${dato['exitosos']} exitosos\n'
                '✗ ${dato['rechazados']} rechazados',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ✅ Tabla ordenable de accesos por hora
  Widget _buildTablaOrdenableAccesos() {
    if (_datosAccesos == null) return const SizedBox.shrink();

    final List<dynamic>? datos = _datosAccesos!['datos'];
    if (datos == null || datos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detalle por Hora',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${datos.length} horas con accesos',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildDataTableAccesos(datos),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTableAccesos(List<dynamic> datos) {
    int sortColumnIndex = 0;
    bool sortAscending = true;

    return StatefulBuilder(
      builder: (context, setState) {
        List<Map<String, dynamic>> datosProcesados = datos.map((dato) {
          int exitosos = dato['exitosos'] ?? 0;
          int rechazados = dato['rechazados'] ?? 0;
          return {
            'hora': dato['hora'] ?? 0,
            'exitosos': exitosos,
            'rechazados': rechazados,
            'total': exitosos + rechazados,
          };
        }).toList();

        datosProcesados.sort((a, b) {
          int result = 0;
          switch (sortColumnIndex) {
            case 0:
              result = a['hora'].compareTo(b['hora']);
              break;
            case 1:
              result = a['exitosos'].compareTo(b['exitosos']);
              break;
            case 2:
              result = a['rechazados'].compareTo(b['rechazados']);
              break;
            case 3:
              result = a['total'].compareTo(b['total']);
              break;
          }
          return sortAscending ? result : -result;
        });

        return DataTable(
          sortColumnIndex: sortColumnIndex,
          sortAscending: sortAscending,
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          ),
          columns: [
            DataColumn(
              label: const Text(
                'Hora',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (columnIndex, ascending) {
                setState(() {
                  sortColumnIndex = columnIndex;
                  sortAscending = ascending;
                });
              },
            ),
            DataColumn(
              label: const Text(
                'Exitosos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              onSort: (columnIndex, ascending) {
                setState(() {
                  sortColumnIndex = columnIndex;
                  sortAscending = ascending;
                });
              },
            ),
            DataColumn(
              label: const Text(
                'Rechazados',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              onSort: (columnIndex, ascending) {
                setState(() {
                  sortColumnIndex = columnIndex;
                  sortAscending = ascending;
                });
              },
            ),
            DataColumn(
              label: const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              onSort: (columnIndex, ascending) {
                setState(() {
                  sortColumnIndex = columnIndex;
                  sortAscending = ascending;
                });
              },
            ),
          ],
          rows: datosProcesados.map((dato) {
            return DataRow(
              cells: [
                DataCell(Text('${dato['hora'].toString().padLeft(2, '0')}:00')),
                DataCell(
                  Text(
                    dato['exitosos'].toString(),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    dato['rechazados'].toString(),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    dato['total'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}  // ← Este es el cierre de la clase

