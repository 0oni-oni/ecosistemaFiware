// lib/views/dispositivos/dispositivo_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/repositories/auth_repository.dart';
import '/repositories/dispositivos_repository.dart';
import '/settings/api_config.dart';

class DispositivoFormDialog extends StatefulWidget {
  const DispositivoFormDialog({Key? key}) : super(key: key);

  @override
  State<DispositivoFormDialog> createState() => _DispositivoFormDialogState();
}

class _DispositivoFormDialogState extends State<DispositivoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();

  String _tipoDispositivo = 'sensor';
  String _transporteSeleccionado = 'MQTT';
  bool _isLoading = false;

  List<AtributoFormData> _atributos = [
    AtributoFormData(nombre: 'temperature', tipo: 'Number', objectId: 't'),
  ];

  final List<String> _transportes = ['MQTT', 'HTTP'];
  final List<String> _tiposDato = ['Number', 'Text', 'Boolean'];

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  void _agregarAtributo() {
    setState(() {
      _atributos.add(
        AtributoFormData(nombre: '', tipo: 'Number', objectId: ''),
      );
    });
  }

  void _eliminarAtributo(int index) {
    if (_atributos.length > 1) {
      setState(() => _atributos.removeAt(index));
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final deviceId = _deviceIdController.text.trim();

    if (_tipoDispositivo == 'acceso' &&
        !deviceId.toLowerCase().startsWith('acceso')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Los dispositivos de control de acceso deben empezar con "acceso"',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final token = context.read<AuthRepository>().token;
    if (token == null) return;

    List<Map<String, dynamic>> atributosFinales = _atributos.map((attr) {
      final map = {'name': attr.nombre, 'type': attr.tipo};
      if (attr.objectId.isNotEmpty) {
        map['object_id'] = attr.objectId;
      }
      return map;
    }).toList();

    if (_tipoDispositivo == 'sensor_gps') {
      atributosFinales.addAll([
        {'name': 'latitude', 'type': 'Number', 'object_id': 'lat'},
        {'name': 'longitude', 'type': 'Number', 'object_id': 'lon'},
      ]);
    }

    final payload = {
      'device_id': deviceId,
      'entity_name': deviceId,
      'entity_type': _tipoDispositivo == 'acceso' ? 'AccessControl' : 'Sensor',
      'transport': _transporteSeleccionado,
      'service_api_key': 'smartlab_key',
      'attributes': atributosFinales,
    };

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dispositivosEndpoint}'),
            headers: ApiConfig.getHeaders(token: token),
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          await context.read<DispositivosRepository>().fetchDispositivos(token);

          Navigator.pop(context);

          _mostrarConfiguracionDispositivo(deviceId);
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarConfiguracionDispositivo(String deviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Dispositivo Creado')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dispositivo: $deviceId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Divider(height: 24),

              if (_transporteSeleccionado == 'MQTT') ...[
                _buildSeccionCopiable('CONFIGURACION MQTT', '''
// WiFi
const char* ssid = "TU_WIFI";
const char* password = "TU_PASSWORD";

// MQTT FIWARE (TLS)
const char* mqtt_server = "ecosistemafiware.com";
const int mqtt_port = 8883;
const char* mqtt_topic = "json/1234/$deviceId/attrs";
'''),
                const SizedBox(height: 12),

                _buildSeccionCopiable('CERTIFICADO CA (TLS)', '''
const char* ca_cert = R"EOF(
-----BEGIN CERTIFICATE-----
MIIDCTCCAfGgAwIBAgIUe+32j/DndaoCbMvczzGZuTQdfX4wDQYJKoZIhvcNAQEL
BQAwFDESMBAGA1UEAwwJRklXQVJFX0NBMB4XDTI1MTEyNjIwNTQyOFoXDTM1MTEy
NDIwNTQyOFowFDESMBAGA1UEAwwJRklXQVJFX0NBMIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEA2IEjZFoC1DTJ0lMrMD3M5z7rMsB8RiIITwwlUMdxt7pS
FZOPfiCg5SaEOffqeJKyYRoLp8Zerg+kzEIF9fCdwhvvtFeX2CLZErUgg76zYxOr
1Kgq4hJKijaPlk9KEgRSSKKB+rDeSjh+29LdWrVpCI79HI9BpNPhBPhyd3bSm8dV
9DHMLMzikz1iMsMLlcsSj+jil0SN3yoHT0tPlHsChH8ZXh8qOSR75R+kFdFmqWDF
SiGRLpjOTGbpyujjqlqnoI6UDOS542gfNdSCXiWupnp/U4imqIr0IDuWegqfzz3e
+e1VxnuSH8YkPlieWjX1LdQNqaRvTMcYgJFd4PuXRQIDAQABo1MwUTAdBgNVHQ4E
FgQU0/605aI0Zp/mNMTNchgKwqTCMaMwHwYDVR0jBBgwFoAU0/605aI0Zp/mNMTN
chgKwqTCMaMwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAhSuy
CFnwMvKI2mi/3y8l0bIHfw8jMeWOiTLPT/VCScgK1co3ujQhihgzFIdzuCY8hjxp
87/vcwJvQRGV48BpD+LZfatuhWFiL7EdivddaQDRR8FoXD9Td2PV1pqba62luYD8
RqUkIc785xy6UZuDi/3PKKI5WfMKPYvRfqg60UQIL/E5mAMV2R/tZz1u+GKikmW/
MQ4/sorxLPO8JhRYN4a9AuD/Qj/hByiKUIJKacNzLawzR9c24Eh/INZjNzFxbJQm
gyIyCSHWR3qdycvTyO7uXUxr6+hWrSRdEnZqGdpltvy27Pdz7S0rj9VQjtpJXmhe
jQtaldmJIbt7/kcKeA==
-----END CERTIFICATE-----
)EOF";
'''),
                const SizedBox(height: 12),
              ] else ...[
                _buildSeccionCopiable('CONFIGURACION HTTP', '''
// WiFi
const char* ssid = "TU_WIFI";
const char* password = "TU_PASSWORD";

// HTTP FIWARE
const char* server = "https://ecosistemafiware.com:8000";
const char* api_key = "smartlab_key";
const char* device_id = "$deviceId";
'''),
                const SizedBox(height: 12),
              ],

              _buildSeccionCopiable(
                'FORMATO JSON A ENVIAR',
                _generarEjemploJSON(),
              ),

              const SizedBox(height: 12),

              _buildSeccionCopiable(
                'CODIGO EJEMPLO (ESP32)',
                _generarCodigoEjemplo(deviceId),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionCopiable(String titulo, String contenido) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blue,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: contenido));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copiado al portapapeles'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Copiar',
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            contenido.trim(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
      ],
    );
  }

  String _generarEjemploJSON() {
    Map<String, dynamic> ejemplo = {};

    for (var attr in _atributos) {
      if (attr.objectId.isNotEmpty) {
        if (attr.tipo == 'Number') {
          ejemplo[attr.objectId] = attr.nombre.contains('temp') ? 25.3 : 50.0;
        } else if (attr.tipo == 'Boolean') {
          ejemplo[attr.objectId] = true;
        } else {
          ejemplo[attr.objectId] = 'ejemplo';
        }
      }
    }

    if (_tipoDispositivo == 'sensor_gps') {
      ejemplo['lat'] = -0.9345;
      ejemplo['lon'] = -78.6103;
    }

    return jsonEncode(ejemplo);
  }

  String _generarCodigoEjemplo(String deviceId) {
    if (_transporteSeleccionado == 'MQTT') {
      String atributos = '';
      int count = 0;
      for (var attr in _atributos) {
        if (attr.objectId.isNotEmpty) {
          if (count > 0) atributos += '  payload += ",";\n';
          if (attr.tipo == 'Number') {
            atributos +=
                '  payload += "\\"${attr.objectId}\\":" + String(${attr.nombre}Value, 1);\n';
          } else {
            atributos +=
                '  payload += "\\"${attr.objectId}\\":\\"" + ${attr.nombre}Value + "\\"";\n';
          }
          count++;
        }
      }

      if (_tipoDispositivo == 'sensor_gps') {
        if (count > 0) atributos += '  payload += ",";\n';
        atributos += '  payload += "\\"lat\\":" + String(latitude, 6);\n';
        atributos += '  payload += ",";\n';
        atributos += '  payload += "\\"lon\\":" + String(longitude, 6);\n';
      }

      return '''
// Ejemplo de envio MQTT
void enviarDatos() {
  String payload = "{";
$atributos  payload += "}";
  
  client.publish("json/1234/$deviceId/attrs", payload.c_str());
  Serial.println("Enviado: " + payload);
}
''';
    } else {
      String body = '';
      int count = 0;
      for (var attr in _atributos) {
        if (attr.objectId.isNotEmpty) {
          body +=
              '    "${attr.objectId}": ' +
              (attr.tipo == 'Number' ? '25.3' : '"valor"');
          count++;
          if (count < _atributos.length || _tipoDispositivo == 'sensor_gps')
            body += ',';
          body += '\n';
        }
      }

      if (_tipoDispositivo == 'sensor_gps') {
        body += '    "lat": -0.9345,\n';
        body += '    "lon": -78.6103\n';
      }

      return '''
// Ejemplo de envio HTTP
void enviarDatos() {
  HTTPClient http;
  http.begin("https://ecosistemafiware.com:8000/iot/json?k=smartlab_key&i=$deviceId");
  http.addHeader("Content-Type", "application/json");
  
  String payload = "{\n" +
$body  "}";
  
  int httpCode = http.POST(payload);
  Serial.println("HTTP Code: " + String(httpCode));
  http.end();
}
''';
    }
  }

  // ============ FIN PARTE 1 ============
  // ============ INICIO PARTE 2 ============

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Dispositivo IoT'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Tipo de Dispositivo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                Card(
                  color: _tipoDispositivo == 'acceso'
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Sensor Normal'),
                        subtitle: const Text(
                          'Temperatura, humedad, presion, etc.',
                        ),
                        value: 'sensor',
                        groupValue: _tipoDispositivo,
                        onChanged: (value) {
                          setState(() {
                            _tipoDispositivo = value!;
                            _transporteSeleccionado = 'MQTT';
                            _atributos = [
                              AtributoFormData(
                                nombre: 'temperature',
                                tipo: 'Number',
                                objectId: 't',
                              ),
                            ];
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Sensor con GPS'),
                        subtitle: const Text(
                          'Incluye latitude y longitude automaticamente',
                        ),
                        value: 'sensor_gps',
                        groupValue: _tipoDispositivo,
                        onChanged: (value) {
                          setState(() {
                            _tipoDispositivo = value!;
                            _transporteSeleccionado = 'MQTT';
                            _atributos = [
                              AtributoFormData(
                                nombre: 'speed',
                                tipo: 'Number',
                                objectId: 's',
                              ),
                            ];
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Control de Acceso RFID'),
                        subtitle: const Text(
                          'Nombre debe empezar con "acceso"',
                        ),
                        value: 'acceso',
                        groupValue: _tipoDispositivo,
                        onChanged: (value) {
                          setState(() {
                            _tipoDispositivo = value!;
                            _transporteSeleccionado = 'HTTP';
                            _atributos = [
                              AtributoFormData(
                                nombre: 'tarjeta',
                                tipo: 'Text',
                                objectId: 't',
                              ),
                            ];
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  '2. Identificacion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                if (_tipoDispositivo == 'acceso')
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ejemplos: acceso_lab1, acceso_aula2, acceso_principal',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_tipoDispositivo == 'sensor_gps')
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'GPS: Se agregaran automaticamente latitude y longitude',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),

                TextFormField(
                  controller: _deviceIdController,
                  decoration: InputDecoration(
                    labelText: 'Device ID *',
                    hintText: _tipoDispositivo == 'acceso'
                        ? 'acceso_lab1, acceso_aula2'
                        : _tipoDispositivo == 'sensor_gps'
                        ? 'gps_truck01, gps_vehicle02'
                        : 'temp001, Station01, sensor_hum',
                    prefixIcon: const Icon(Icons.fingerprint),
                    helperText: _tipoDispositivo == 'acceso'
                        ? 'Debe empezar con "acceso"'
                        : 'Identificador unico del dispositivo',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Requerido';
                    }
                    if (_tipoDispositivo == 'acceso' &&
                        !value.toLowerCase().startsWith('acceso')) {
                      return 'Debe empezar con "acceso"';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  '3. Configuracion Tecnica',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _transporteSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Protocolo',
                    prefixIcon: Icon(Icons.wifi),
                  ),
                  items: _transportes.map((transporte) {
                    return DropdownMenuItem(
                      value: transporte,
                      child: Text(transporte),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null)
                      setState(() => _transporteSeleccionado = value);
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '4. Atributos${_tipoDispositivo == 'sensor_gps' ? ' (GPS se agrega automaticamente)' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: _agregarAtributo,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ..._atributos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final atributo = entry.value;
                  return _buildAtributoCard(index, atributo);
                }).toList(),

                if (_tipoDispositivo == 'sensor_gps') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.gps_fixed, color: Colors.green, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Atributos GPS (automaticos)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'latitude (Number) - object_id: lat\nlongitude (Number) - object_id: lon',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }

  Widget _buildAtributoCard(int index, AtributoFormData atributo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: atributo.nombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'temperature',
                      isDense: true,
                    ),
                    onChanged: (value) => atributo.nombre = value,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: atributo.tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      isDense: true,
                    ),
                    items: _tiposDato.map((tipo) {
                      return DropdownMenuItem(value: tipo, child: Text(tipo));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => atributo.tipo = value);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarAtributo(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: atributo.objectId,
              decoration: const InputDecoration(
                labelText: 'Object ID *',
                hintText: 't',
                isDense: true,
                helperText: 'Para mapeo: {"t": 25.3}',
              ),
              onChanged: (value) => atributo.objectId = value,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Requerido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AtributoFormData {
  String nombre;
  String tipo;
  String objectId;

  AtributoFormData({
    required this.nombre,
    required this.tipo,
    required this.objectId,
  });
}
