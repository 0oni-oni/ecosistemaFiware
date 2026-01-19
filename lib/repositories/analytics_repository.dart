// lib/repositories/analytics_repository.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/settings/api_config.dart';

class AnalyticsRepository extends ChangeNotifier {
  Map<String, dynamic>? _estadisticasTabla;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get estadisticasTabla => _estadisticasTabla;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool _requiereAjusteHorario(String nombreTabla) {
    return nombreTabla == 'etsensor' || nombreTabla == 'etstation';
  }

  // ✅ NUEVO: Constante para timezone de Ecuador
  static const int ECUADOR_UTC_OFFSET = -5;

  // ========================================
  //  NUEVA FUNCIÓN: Convertir hora UTC a Ecuador
  // ========================================
  int _convertirHoraUTCaEcuador(int horaUtc) {
    int horaEcuador = (horaUtc + ECUADOR_UTC_OFFSET) % 24;
    if (horaEcuador < 0) horaEcuador += 24;
    return horaEcuador;
  }

  // ========================================
  //  MEJORADA: fetchDatosPorHoraConDispositivo con timezone
  // ========================================
  Future<Map<String, dynamic>?> fetchDatosPorHoraConDispositivo(
    String token,
    String schema,
    String nombre,
    String columna,
    String fecha, {
    String? dispositivoId,
  }) async {
    try {
      String urlStr =
          '${ApiConfig.baseUrl}/crate/tabla/$schema/$nombre/datos-hora?columna=$columna&fecha=$fecha';

      if (dispositivoId != null && dispositivoId.isNotEmpty) {
        urlStr += '&dispositivo=$dispositivoId';
      }

      final url = Uri.parse(urlStr);
      print('🔍 Consultando datos por hora: $url');

      final response = await http
          .get(url, headers: ApiConfig.getHeaders(token: token))
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ NUEVO: Convertir horas UTC a hora Ecuador
        if (data['datos'] != null &&
            data['datos'] is List &&
            _requiereAjusteHorario(nombre)) {
          for (var item in data['datos']) {
            if (item['hora'] != null) {
              int horaUtc = item['hora'];
              item['hora'] = _convertirHoraUTCaEcuador(horaUtc);
              item['hora_original_utc'] = horaUtc;
            }
          }
        }

        print('✅ Datos obtenidos: ${data['total_registros']} registros');
        return data;
      } else {
        print('❌ Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo datos por hora: $e');
      return null;
    }
  }

  // ========================================
  // ✅ MEJORADA: fetchAccesosPorHora con timezone
  // ========================================
  Future<Map<String, dynamic>?> fetchAccesosPorHora(
    String token,
    String schema,
    String nombre,
    String fecha, {
    String? dispositivoId,
  }) async {
    try {
      String urlStr =
          '${ApiConfig.baseUrl}/crate/tabla/$schema/$nombre/accesos-hora?fecha=$fecha';

      if (dispositivoId != null && dispositivoId.isNotEmpty) {
        urlStr += '&dispositivo=$dispositivoId';
      }

      final url = Uri.parse(urlStr);
      print('🔍 Consultando accesos por hora: $url');

      final response = await http
          .get(url, headers: ApiConfig.getHeaders(token: token))
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ NUEVO: Convertir horas UTC a hora Ecuador en datos_por_hora
        if (data['datos_por_hora'] != null &&
            data['datos_por_hora'] is Map &&
            _requiereAjusteHorario(nombre)) {
          Map<String, dynamic> datosConvertidos = {};

          (data['datos_por_hora'] as Map).forEach((horaStr, valor) {
            int horaUtc = int.parse(horaStr);
            int horaEcuador = _convertirHoraUTCaEcuador(horaUtc);
            datosConvertidos[horaEcuador.toString()] = valor;
          });

          data['datos_por_hora'] = datosConvertidos;
        }

        print('✅ Accesos obtenidos: ${data['total_accesos']} accesos');
        return data;
      } else {
        print('❌ Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo accesos por hora: $e');
      return null;
    }
  }

  // ========================================
  // FUNCIONES ANTERIORES SIN CAMBIOS
  // ========================================

  Future<bool> fetchEstadisticasTabla(
    String token,
    String schema,
    String nombre,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.crateEstadisticas}/$schema/$nombre/estadisticas',
            ),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        _estadisticasTabla = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Error al cargar estadísticas: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchDatosPorFechaTabla(
    String token,
    String schema,
    String nombre,
    String columnaValor,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.crateDatos}/$schema/$nombre/datos?limit=10000',
      );

      final response = await http
          .get(url, headers: ApiConfig.getHeaders(token: token))
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> datos = data['datos'] ?? [];

        Map<String, List<double>> datosPorDia = {};

        for (var registro in datos) {
          if (registro['time_index'] != null &&
              registro[columnaValor] != null) {
            String fecha = registro['time_index'].toString().split('T')[0];
            double valor =
                double.tryParse(registro[columnaValor].toString()) ?? 0;

            if (!datosPorDia.containsKey(fecha)) {
              datosPorDia[fecha] = [];
            }
            datosPorDia[fecha]!.add(valor);
          }
        }

        List<Map<String, dynamic>> resultado = [];
        datosPorDia.forEach((fecha, valores) {
          double promedio = valores.reduce((a, b) => a + b) / valores.length;
          resultado.add({'fecha': fecha, 'valor': promedio});
        });

        resultado.sort((a, b) => a['fecha'].compareTo(b['fecha']));

        return resultado;
      }
      return [];
    } catch (e) {
      print('Error obteniendo datos por fecha: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDatosConHoras(
    String token,
    String schema,
    String nombre,
    String columnaValor,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.crateDatos}/$schema/$nombre/datos?limit=10000',
      );

      final response = await http
          .get(url, headers: ApiConfig.getHeaders(token: token))
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> datos = data['datos'] ?? [];

        List<Map<String, dynamic>> resultado = [];

        for (var registro in datos) {
          if (registro['time_index'] != null &&
              registro[columnaValor] != null) {
            try {
              String timeIndex = registro['time_index'].toString();
              DateTime fecha = DateTime.parse(timeIndex);
              double valor =
                  double.tryParse(registro[columnaValor].toString()) ?? 0;

              resultado.add({
                'fecha': timeIndex,
                'fechaObj': fecha,
                'valor': valor,
              });
            } catch (e) {
              print('Error parseando registro: $e');
            }
          }
        }

        resultado.sort((a, b) => a['fechaObj'].compareTo(b['fechaObj']));

        print('✅ Datos obtenidos: ${resultado.length} registros');
        if (resultado.isNotEmpty) {
          print('📅 Primer dato: ${resultado.first['fecha']}');
          print('📅 Último dato: ${resultado.last['fecha']}');
        }

        return resultado;
      }
      return [];
    } catch (e) {
      print('❌ Error obteniendo datos: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchDatosPorHora(
    String token,
    String schema,
    String nombre,
    String columna,
    String fecha,
  ) async {
    return fetchDatosPorHoraConDispositivo(
      token,
      schema,
      nombre,
      columna,
      fecha,
    );
  }

  Future<Map<String, double>?> calcularEstadisticas(
    String token,
    String schema,
    String nombre,
    String columna,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.crateDatos}/$schema/$nombre/datos?limit=10000',
      );

      final response = await http
          .get(url, headers: ApiConfig.getHeaders(token: token))
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> datos = data['datos'] ?? [];

        List<double> valores = [];
        for (var registro in datos) {
          if (registro[columna] != null) {
            double? valor = double.tryParse(registro[columna].toString());
            if (valor != null) valores.add(valor);
          }
        }

        if (valores.isEmpty) return null;

        valores.sort();
        double sum = valores.reduce((a, b) => a + b);
        double promedio = sum / valores.length;
        double maximo = valores.last;
        double minimo = valores.first;

        return {
          'promedio': promedio,
          'maximo': maximo,
          'minimo': minimo,
          'total': valores.length.toDouble(),
        };
      }
      return null;
    } catch (e) {
      print('Error calculando estadísticas: $e');
      return null;
    }
  }
}
