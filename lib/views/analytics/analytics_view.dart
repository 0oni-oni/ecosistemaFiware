// lib/views/analytics/analytics_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '/repositories/auth_repository.dart';
import '/repositories/crate_repository.dart';
import '/repositories/analytics_repository.dart';
import '/repositories/dispositivos_repository.dart';
import '/models/tabla_crate.dart';
import '/models/dispositivo.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum TipoTabla { sensores, accesos, desconocido }

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({Key? key}) : super(key: key);

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  TablaCrate? _tablaSeleccionada;
  String? _columnaSeleccionada;
  Dispositivo? _dispositivoSeleccionado;
  DateTime? _fechaSeleccionada;
  Map<String, dynamic>? _datosAnalisis;
  bool _cargando = false;
  TipoTabla _tipoTabla = TipoTabla.desconocido;

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
      await Future.wait([
        context.read<CrateRepository>().fetchTablas(token),
        context.read<DispositivosRepository>().fetchDispositivos(token),
      ]);
    }
  }

  TipoTabla _detectarTipoTabla(String nombreTabla) {
    final nombre = nombreTabla.toLowerCase();
    if (nombre.contains('access') || nombre.contains('event')) {
      return TipoTabla.accesos;
    }
    if (nombre.contains('sensor') || nombre.contains('station')) {
      return TipoTabla.sensores;
    }
    return TipoTabla.desconocido;
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
        await _cargarDatosAnalisis();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cargarDatosAnalisis() async {
    if (_fechaSeleccionada == null || _tablaSeleccionada == null) {
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

      Map<String, dynamic>? datos;

      if (_tipoTabla == TipoTabla.sensores && _columnaSeleccionada != null) {
        datos = await analyticsRepo.fetchDatosPorHoraConDispositivo(
          token,
          _tablaSeleccionada!.schema,
          _tablaSeleccionada!.nombre,
          _columnaSeleccionada!,
          fechaFormato,
          dispositivoId: _dispositivoSeleccionado?.refDevice,
        );
      } else if (_tipoTabla == TipoTabla.accesos) {
        datos = await analyticsRepo.fetchAccesosPorHora(
          token,
          _tablaSeleccionada!.schema,
          _tablaSeleccionada!.nombre,
          fechaFormato,
          dispositivoId: _dispositivoSeleccionado?.refDevice,
        );
      }

      if (!mounted) return;

      setState(() {
        _datosAnalisis = datos;
        _cargando = false;
      });

      if (datos != null && mounted) {
        _mostrarMensajeExito(datos);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _mostrarMensajeExito(Map<String, dynamic> datos) {
    String mensaje = '';

    if (_tipoTabla == TipoTabla.sensores) {
      final totalRegistros = datos['total_registros'] ?? 0;
      final datosList = datos['datos'];
      final horasConDatos = (datosList is List) ? datosList.length : 0;
      mensaje = '✅ $horasConDatos horas con datos ($totalRegistros registros)';
    } else if (_tipoTabla == TipoTabla.accesos) {
      final totalAccesos = datos['total_accesos'] ?? 0;
      final exitosos = datos['exitosos'] ?? 0;
      final rechazados = datos['rechazados'] ?? 0;
      mensaje = '✅ $totalAccesos accesos ($exitosos ✓, $rechazados ✗)';
    }

    if (_dispositivoSeleccionado != null) {
      mensaje += '\n📡 ${_dispositivoSeleccionado!.deviceId}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  List<String> _detectarColumnasNumericas(List<String> columnas) {
    return columnas.where((col) {
      final colLower = col.toLowerCase();
      return colLower.contains('temp') ||
          colLower.contains('hum') ||
          colLower.contains('wind') ||
          colLower.contains('uv') ||
          colLower.contains('pressure') ||
          colLower.contains('altitude') ||
          colLower == 'temperatura' ||
          colLower == 'temperature' ||
          colLower == 'humidity' ||
          colLower == 'windspeed' ||
          colLower == 'uvindex';
    }).toList();
  }

  String _getUnidad(String columna) {
    final col = columna.toLowerCase();
    if (col.contains('temp')) return '°C';
    if (col.contains('hum')) return '%';
    if (col.contains('wind')) return 'km/h';
    if (col.contains('uv')) return '';
    if (col.contains('pressure')) return 'hPa';
    if (col.contains('altitude')) return 'm';
    return '';
  }

  double _calcularPromedio(List<dynamic> datos) {
    if (datos.isEmpty) return 0;
    double suma = 0;
    int count = 0;
    for (var dato in datos) {
      if (dato != null && dato is Map && dato['valor'] != null) {
        suma += dato['valor'].toDouble();
        count++;
      }
    }
    return count > 0 ? suma / count : 0;
  }

  Future<void> _exportarPDF() async {
    if (_datosAnalisis == null || !_tieneDatos()) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generando PDF...'),
            ],
          ),
        ),
      );

      final pdf = pw.Document();

      if (_tipoTabla == TipoTabla.sensores) {
        await _generarPDFSensores(pdf);
      } else if (_tipoTabla == TipoTabla.accesos) {
        await _generarPDFAccesos(pdf);
      }

      final directory = await getTemporaryDirectory();
      final fecha = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final nombreArchivo = 'reporte_smartlab_$fecha.pdf';
      final path = '${directory.path}/$nombreArchivo';

      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      if (mounted) Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Reporte SmartLab FIWARE',
        text:
            'Análisis generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF generado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al generar PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _generarPDFSensores(pw.Document pdf) async {
    final datos = _datosAnalisis!['datos'] as List;
    final promedio = _calcularPromedio(datos);
    final maximo = _datosAnalisis!['max'];
    final minimo = _datosAnalisis!['min'];
    final totalRegistros = _datosAnalisis!['total_registros'] ?? 0;
    final unidad = _getUnidad(_columnaSeleccionada!);

    // Preparar datos para la gráfica
    Map<int, dynamic> datosPorHora = {};
    double maxValor = 0;
    for (var dato in datos) {
      datosPorHora[dato['hora']] = dato;
      if (dato['valor'] > maxValor) maxValor = dato['valor'].toDouble();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'REPORTE DE SENSORES',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'SmartLab FIWARE - Análisis de Datos',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Info del análisis
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPDFInfoRow(
                      'Fecha:',
                      DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!),
                    ),
                    _buildPDFInfoRow(
                      'Variable:',
                      _columnaSeleccionada!.toUpperCase(),
                    ),
                    _buildPDFInfoRow(
                      'Dispositivo:',
                      _dispositivoSeleccionado?.deviceId ?? 'Todos',
                    ),
                    _buildPDFInfoRow(
                      'Generado:',
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // RESUMEN DEL DÍA
              pw.Text(
                'RESUMEN DEL DÍA',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPDFStatCard(
                    'MÁXIMO',
                    '${maximo['valor']?.toStringAsFixed(1)} $unidad',
                    '${maximo['hora']}:00',
                  ),
                  _buildPDFStatCard(
                    'PROMEDIO',
                    '${promedio.toStringAsFixed(1)} $unidad',
                    '24 horas',
                  ),
                  _buildPDFStatCard(
                    'MÍNIMO',
                    '${minimo['valor']?.toStringAsFixed(1)} $unidad',
                    '${minimo['hora']}:00',
                  ),
                  _buildPDFStatCard(
                    'REGISTROS',
                    totalRegistros.toString(),
                    'Total',
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // GRÁFICA DE BARRAS
              pw.Text(
                '${_columnaSeleccionada!.toUpperCase()} - ${DateFormat('dd MMM yyyy').format(_fechaSeleccionada!)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (_dispositivoSeleccionado != null)
                pw.Text(
                  'Dispositivo: ${_dispositivoSeleccionado!.deviceId}',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              pw.SizedBox(height: 12),

              // Contenedor de la gráfica CON EJE Y
              pw.Container(
                height: 250,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Row(
                    children: [
                      // EJE Y (Escala de valores)
                      pw.Container(
                        width: 45,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              maxValor.toStringAsFixed(1),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Text(
                              (maxValor * 0.75).toStringAsFixed(1),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Text(
                              (maxValor * 0.5).toStringAsFixed(1),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Text(
                              (maxValor * 0.25).toStringAsFixed(1),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Text(
                              '0.0',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 8),

                      // GRÁFICA DE BARRAS
                      pw.Expanded(
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: List.generate(24, (hora) {
                            final valor = datosPorHora.containsKey(hora)
                                ? datosPorHora[hora]['valor'].toDouble()
                                : 0.0;
                            final altura = maxValor > 0
                                ? (valor / maxValor) * 200
                                : 0.0;
                            final tieneValor = datosPorHora.containsKey(hora);

                            return pw.Expanded(
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  // Barra
                                  pw.Container(
                                    height: altura > 0 ? altura : 1,
                                    decoration: pw.BoxDecoration(
                                      color: tieneValor
                                          ? PdfColors.blue
                                          : PdfColors.grey300,
                                      borderRadius:
                                          const pw.BorderRadius.vertical(
                                            top: pw.Radius.circular(2),
                                          ),
                                    ),
                                  ),
                                  pw.SizedBox(height: 4),
                                  // Etiqueta de hora (cada 3 horas)
                                  if (hora % 3 == 0)
                                    pw.Text(
                                      '${hora.toString().padLeft(2, '0')}h',
                                      style: const pw.TextStyle(
                                        fontSize: 7,
                                        color: PdfColors.grey600,
                                      ),
                                    )
                                  else
                                    pw.SizedBox(height: 9),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generarPDFAccesos(pw.Document pdf) async {
    final totalAccesos = _datosAnalisis!['total_accesos'] ?? 0;
    final exitosos = _datosAnalisis!['exitosos'] ?? 0;
    final rechazados = _datosAnalisis!['rechazados'] ?? 0;
    final tasaExito = _datosAnalisis!['tasa_exito'] ?? 0;
    final datos = _datosAnalisis!['datos'] as List;

    // Preparar datos para la gráfica
    Map<int, dynamic> datosPorHora = {};
    double maxTotal = 0;
    for (var dato in datos) {
      datosPorHora[dato['hora']] = dato;
      final total = (dato['exitosos'] + dato['rechazados']).toDouble();
      if (total > maxTotal) maxTotal = total;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'REPORTE DE CONTROL DE ACCESOS',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'SmartLab FIWARE - Análisis de Seguridad',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Info del análisis
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPDFInfoRow(
                      'Fecha:',
                      DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!),
                    ),
                    _buildPDFInfoRow(
                      'Dispositivo:',
                      _dispositivoSeleccionado?.deviceId ?? 'Todos',
                    ),
                    _buildPDFInfoRow(
                      'Generado:',
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // RESUMEN DEL DÍA
              pw.Text(
                'RESUMEN DEL DÍA',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPDFStatCard(
                    'TOTAL',
                    totalAccesos.toString(),
                    'Eventos',
                  ),
                  _buildPDFStatCard(
                    'EXITOSOS',
                    exitosos.toString(),
                    '${tasaExito.toStringAsFixed(1)}%',
                  ),
                  _buildPDFStatCard(
                    'RECHAZADOS',
                    rechazados.toString(),
                    '${(100 - tasaExito).toStringAsFixed(1)}%',
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // GRÁFICA DE BARRAS
              pw.Text(
                'ACCESOS - ${DateFormat('dd MMM yyyy').format(_fechaSeleccionada!)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (_dispositivoSeleccionado != null)
                pw.Text(
                  'Dispositivo: ${_dispositivoSeleccionado!.deviceId}',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              pw.SizedBox(height: 12),

              // Contenedor de la gráfica CON EJE Y
              pw.Container(
                height: 250,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Row(
                    children: [
                      // EJE Y (Escala de valores)
                      pw.Container(
                        width: 35,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              maxTotal.toInt().toString(),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Text(
                              (maxTotal * 0.75).toInt().toString(),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Text(
                              (maxTotal * 0.5).toInt().toString(),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Text(
                              (maxTotal * 0.25).toInt().toString(),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Text(
                              '0',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 8),

                      // GRÁFICA DE BARRAS
                      pw.Expanded(
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: List.generate(24, (hora) {
                            final exitososHora = datosPorHora.containsKey(hora)
                                ? datosPorHora[hora]['exitosos'].toDouble()
                                : 0.0;
                            final rechazadosHora =
                                datosPorHora.containsKey(hora)
                                ? datosPorHora[hora]['rechazados'].toDouble()
                                : 0.0;
                            final total = exitososHora + rechazadosHora;

                            final alturaTotal = maxTotal > 0
                                ? (total / maxTotal) * 200
                                : 0.0;
                            final alturaExitosos = maxTotal > 0
                                ? (exitososHora / maxTotal) * 200
                                : 0.0;

                            return pw.Expanded(
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  // Barra apilada
                                  if (total > 0)
                                    pw.Container(
                                      height: alturaTotal,
                                      child: pw.Column(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.end,
                                        children: [
                                          // Rechazados (arriba)
                                          if (rechazadosHora > 0)
                                            pw.Container(
                                              height:
                                                  alturaTotal - alturaExitosos,
                                              decoration: const pw.BoxDecoration(
                                                color: PdfColors.red300,
                                                borderRadius:
                                                    pw.BorderRadius.vertical(
                                                      top: pw.Radius.circular(
                                                        2,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          // Exitosos (abajo)
                                          if (exitososHora > 0)
                                            pw.Container(
                                              height: alturaExitosos,
                                              decoration:
                                                  const pw.BoxDecoration(
                                                    color: PdfColors.green,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    )
                                  else
                                    pw.Container(
                                      height: 1,
                                      color: PdfColors.grey300,
                                    ),
                                  pw.SizedBox(height: 4),
                                  // Etiqueta de hora (cada 3 horas)
                                  if (hora % 3 == 0)
                                    pw.Text(
                                      '${hora.toString().padLeft(2, '0')}h',
                                      style: const pw.TextStyle(
                                        fontSize: 7,
                                        color: PdfColors.grey600,
                                      ),
                                    )
                                  else
                                    pw.SizedBox(height: 9),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // Leyenda
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(width: 12, height: 12, color: PdfColors.green),
                  pw.SizedBox(width: 6),
                  pw.Text('Exitosos', style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(width: 16),
                  pw.Container(width: 12, height: 12, color: PdfColors.red300),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    'Rechazados',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildPDFInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  pw.Widget _buildPDFStatCard(String label, String value, String subtitle) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  List<Dispositivo> _obtenerDispositivosRelevantes(List<Dispositivo> todos) {
    if (_tablaSeleccionada == null) return [];
    final nombreTabla = _tablaSeleccionada!.nombre.toLowerCase();

    if (nombreTabla.contains('access')) {
      return todos
          .where(
            (d) =>
                d.refDevice.toLowerCase().contains('acceso') ||
                d.refDevice.toLowerCase().contains('access') ||
                (d.entityType?.toLowerCase().contains('access') ?? false),
          )
          .toList();
    }
    if (nombreTabla.contains('sensor')) {
      return todos
          .where(
            (d) =>
                (d.entityType?.toLowerCase().contains('sensor') ?? false) ||
                d.refDevice.toLowerCase().contains('sensor'),
          )
          .toList();
    }
    if (nombreTabla.contains('station')) {
      return todos
          .where(
            (d) =>
                (d.entityType?.toLowerCase().contains('station') ?? false) ||
                d.refDevice.toLowerCase().contains('station'),
          )
          .toList();
    }
    return todos;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildConfiguracion(),

          if (_datosAnalisis != null) ...[
            const SizedBox(height: 16),
            if (_tipoTabla == TipoTabla.sensores)
              _buildResultadosSensores()
            else if (_tipoTabla == TipoTabla.accesos)
              _buildResultadosAccesos(),
          ],

          if (_datosAnalisis != null && !_tieneDatos()) _buildSinDatos(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics Avanzado',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _tipoTabla == TipoTabla.sensores
                    ? 'Análisis horario de sensores'
                    : _tipoTabla == TipoTabla.accesos
                    ? 'Análisis de control de accesos'
                    : 'Análisis horario con filtro por dispositivo',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        if (_tieneDatos())
          IconButton(
            onPressed: _exportarPDF,
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
            tooltip: 'Descargar PDF',
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
    );
  }

  // ============ FIN PARTE 1 ============
  // ============ INICIO PARTE 2 ============

  Widget _buildConfiguracion() {
    return Card(
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

            // Selector de Tabla
            Consumer<CrateRepository>(
              builder: (context, crateRepo, _) {
                return DropdownButtonFormField<TablaCrate>(
                  value: _tablaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Tabla',
                    prefixIcon: Icon(Icons.table_chart),
                    border: OutlineInputBorder(),
                  ),
                  items: crateRepo.tablas.map((tabla) {
                    return DropdownMenuItem(
                      value: tabla,
                      child: Text(tabla.nombre),
                    );
                  }).toList(),
                  onChanged: (tabla) {
                    setState(() {
                      _tablaSeleccionada = tabla;
                      _columnaSeleccionada = null;
                      _dispositivoSeleccionado = null;
                      _datosAnalisis = null;
                      _tipoTabla = tabla != null
                          ? _detectarTipoTabla(tabla.nombre)
                          : TipoTabla.desconocido;
                    });
                  },
                );
              },
            ),

            // Selector de Columna (solo para sensores)
            if (_tipoTabla == TipoTabla.sensores &&
                _tablaSeleccionada != null) ...[
              const SizedBox(height: 16),
              _ColumnaSelectorWidget(
                tablaSeleccionada: _tablaSeleccionada!,
                columnaSeleccionada: _columnaSeleccionada,
                onColumnaChanged: (columna) {
                  setState(() {
                    _columnaSeleccionada = columna;
                    _datosAnalisis = null;
                  });
                },
                detectarColumnasNumericas: _detectarColumnasNumericas,
              ),
            ],

            // Filtro por Dispositivo
            if (_tablaSeleccionada != null) ...[
              const SizedBox(height: 16),
              Consumer<DispositivosRepository>(
                builder: (context, dispositivosRepo, _) {
                  final dispositivosRelevantes = _obtenerDispositivosRelevantes(
                    dispositivosRepo.dispositivos,
                  );

                  return DropdownButtonFormField<Dispositivo>(
                    value: _dispositivoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Dispositivo (Opcional)',
                      prefixIcon: Icon(Icons.router),
                      border: OutlineInputBorder(),
                      helperText: 'Dejar vacío para ver todos',
                    ),
                    items: [
                      const DropdownMenuItem<Dispositivo>(
                        value: null,
                        child: Text(
                          'Todos los dispositivos',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      ...dispositivosRelevantes.map((dispositivo) {
                        return DropdownMenuItem(
                          value: dispositivo,
                          child: Text(dispositivo.deviceId),
                        );
                      }).toList(),
                    ],
                    onChanged: (dispositivo) {
                      setState(() {
                        _dispositivoSeleccionado = dispositivo;
                        _datosAnalisis = null;
                      });
                    },
                  );
                },
              ),
            ],

            // Botón de Análisis
            if (_tablaSeleccionada != null &&
                (_tipoTabla == TipoTabla.accesos ||
                    (_tipoTabla == TipoTabla.sensores &&
                        _columnaSeleccionada != null))) ...[
              const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }

  bool _tieneDatos() {
    if (_datosAnalisis == null) return false;

    if (_tipoTabla == TipoTabla.sensores) {
      final datos = _datosAnalisis!['datos'];
      return datos != null && datos is List && datos.isNotEmpty;
    } else if (_tipoTabla == TipoTabla.accesos) {
      return (_datosAnalisis!['total_accesos'] ?? 0) > 0;
    }

    return false;
  }

  Widget _buildResultadosSensores() {
    final datos = _datosAnalisis!['datos'] as List;
    if (datos.isEmpty) return const SizedBox();

    return Column(
      children: [
        // Resumen del Día (con 4 cuadros: Máximo, Promedio, Mínimo, Registros)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen del Día',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      '${_datosAnalisis!['max']['valor']?.toStringAsFixed(1) ?? 'N/A'} ${_getUnidad(_columnaSeleccionada!)}',
                      'Máximo',
                      '${_datosAnalisis!['max']['hora']?.toString().padLeft(2, '0') ?? '--'}:00',
                      Colors.red,
                    ),
                    _buildStatCard(
                      '${_calcularPromedio(datos).toStringAsFixed(1)} ${_getUnidad(_columnaSeleccionada!)}',
                      'Promedio',
                      '24 horas',
                      Colors.blue,
                    ),
                    _buildStatCard(
                      '${_datosAnalisis!['min']['valor']?.toStringAsFixed(1) ?? 'N/A'} ${_getUnidad(_columnaSeleccionada!)}',
                      'Mínimo',
                      '${_datosAnalisis!['min']['hora']?.toString().padLeft(2, '0') ?? '--'}:00',
                      Colors.green,
                    ),
                    _buildStatCard(
                      '${_datosAnalisis!['total_registros'] ?? 0}',
                      'Registros',
                      'Total',
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Gráfica
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_columnaSeleccionada?.toUpperCase()} - ${DateFormat('dd MMM yyyy').format(_fechaSeleccionada!)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_dispositivoSeleccionado != null)
                  Text(
                    'Dispositivo: ${_dispositivoSeleccionado!.deviceId}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: _buildBarChartSensores(
                    datos,
                    _getUnidad(_columnaSeleccionada!),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultadosAccesos() {
    return Column(
      children: [
        // Estadísticas principales
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen del Día',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      '${_datosAnalisis!['total_accesos'] ?? 0}',
                      'Total',
                      'Eventos',
                      Colors.blue,
                    ),
                    _buildStatCard(
                      '${_datosAnalisis!['exitosos'] ?? 0}',
                      'Exitosos',
                      '${(_datosAnalisis!['tasa_exito'] ?? 0).toStringAsFixed(1)}%',
                      Colors.green,
                    ),
                    _buildStatCard(
                      '${_datosAnalisis!['rechazados'] ?? 0}',
                      'Rechazados',
                      '${(_datosAnalisis!['tasa_rechazo'] ?? 0).toStringAsFixed(1)}%',
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Gráfica de accesos
        if (_datosAnalisis!['datos'] != null &&
            (_datosAnalisis!['datos'] as List).isNotEmpty)
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
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: _buildBarChartAccesos(_datosAnalisis!['datos']),
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

        // Lista de personas
        if (_datosAnalisis!['personas'] != null &&
            (_datosAnalisis!['personas'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personas que Ingresaron',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (_datosAnalisis!['personas'] as List).length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final persona = _datosAnalisis!['personas'][index];
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
      ],
    );
  }

  Widget _buildSinDatos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay datos para la fecha seleccionada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _dispositivoSeleccionado != null
                  ? 'Dispositivo: ${_dispositivoSeleccionado!.deviceId}\nFecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}'
                  : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
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
          label == 'Máximo'
              ? Icons.arrow_upward
              : label == 'Mínimo'
              ? Icons.arrow_downward
              : label == 'Total'
              ? Icons.people
              : label == 'Exitosos'
              ? Icons.check_circle
              : label == 'Rechazados'
              ? Icons.cancel
              : label == 'Registros'
              ? Icons.data_usage
              : Icons.analytics,
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

  Widget _buildBarChartSensores(List<dynamic> datos, String unidad) {
    List<BarChartGroupData> barGroups = [];
    double maxY = 0;
    Map<int, dynamic> datosPorHora = {};

    for (var dato in datos) {
      datosPorHora[dato['hora']] = dato;
    }

    for (int hora = 0; hora < 24; hora++) {
      double valor = 0;
      Color color = Colors.grey.withOpacity(0.3);
      if (datosPorHora.containsKey(hora)) {
        valor = datosPorHora[hora]['valor'].toDouble();
        color = Colors.blue;
        if (valor > maxY) maxY = valor;
      }
      barGroups.add(
        BarChartGroupData(
          x: hora,
          barRods: [
            BarChartRodData(
              toY: valor == 0 ? 0.01 : valor,
              color: color,
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
                    value.toStringAsFixed(1),
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
                  '${hora.toString().padLeft(2, '0')}:00\nSin datos',
                  const TextStyle(color: Colors.white70, fontSize: 11),
                );
              }
              final dato = datosPorHora[hora];
              return BarTooltipItem(
                '${hora.toString().padLeft(2, '0')}:00\n${rod.toY.toStringAsFixed(2)} $unidad\n${dato['count']} mediciones',
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

  Widget _buildBarChartAccesos(List<dynamic> datos) {
    List<BarChartGroupData> barGroups = [];
    Map<int, dynamic> datosPorHora = {};
    double maxY = 0;

    for (var dato in datos) {
      datosPorHora[dato['hora']] = dato;
    }

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
}

// Widget separado para el selector de columnas
class _ColumnaSelectorWidget extends StatefulWidget {
  final TablaCrate tablaSeleccionada;
  final String? columnaSeleccionada;
  final Function(String?) onColumnaChanged;
  final List<String> Function(List<String>) detectarColumnasNumericas;

  const _ColumnaSelectorWidget({
    required this.tablaSeleccionada,
    required this.columnaSeleccionada,
    required this.onColumnaChanged,
    required this.detectarColumnasNumericas,
  });

  @override
  State<_ColumnaSelectorWidget> createState() => _ColumnaSelectorWidgetState();
}

class _ColumnaSelectorWidgetState extends State<_ColumnaSelectorWidget> {
  List<String>? _columnasNumericas;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarColumnas();
  }

  @override
  void didUpdateWidget(_ColumnaSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tablaSeleccionada.nombre != widget.tablaSeleccionada.nombre) {
      _cargarColumnas();
    }
  }

  Future<void> _cargarColumnas() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    final token = context.read<AuthRepository>().token;
    if (token == null) {
      setState(() {
        _columnasNumericas = [];
        _cargando = false;
      });
      return;
    }

    try {
      final crateRepo = context.read<CrateRepository>();
      await crateRepo.fetchDatosTabla(
        token,
        widget.tablaSeleccionada.schema,
        widget.tablaSeleccionada.nombre,
        limit: 1,
      );

      if (mounted) {
        setState(() {
          _columnasNumericas = widget.detectarColumnasNumericas(
            crateRepo.columnas,
          );
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _columnasNumericas = [];
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_columnasNumericas == null || _columnasNumericas!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No se encontraron columnas numéricas',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: widget.columnaSeleccionada,
      decoration: const InputDecoration(
        labelText: 'Variable a Analizar',
        prefixIcon: Icon(Icons.show_chart),
        border: OutlineInputBorder(),
      ),
      items: _columnasNumericas!.map((col) {
        return DropdownMenuItem(value: col, child: Text(col));
      }).toList(),
      onChanged: widget.onColumnaChanged,
    );
  }
}
