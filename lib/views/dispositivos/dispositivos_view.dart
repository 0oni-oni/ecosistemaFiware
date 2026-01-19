// lib/views/dispositivos/dispositivos_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/repositories/auth_repository.dart';
import '/repositories/dispositivos_repository.dart';
import '/models/dispositivo.dart';
import 'dispositivo_form_dialog.dart';

class DispositivosView extends StatefulWidget {
  const DispositivosView({Key? key}) : super(key: key);

  @override
  State<DispositivosView> createState() => _DispositivosViewState();
}

class _DispositivosViewState extends State<DispositivosView> {
  String _filtroTipo = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final token = context.read<AuthRepository>().token;
    if (token != null) {
      final repo = context.read<DispositivosRepository>();
      await Future.wait([
        repo.fetchDispositivos(token),
        repo.fetchTiposDispositivos(token),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final currentUser = auth.currentUser;

    // ✅ PROTECCIÓN: Si no hay usuario, mostrar loading
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool esAdmin = currentUser.isAdmin;

    // ✅ AHORA TODOS PUEDEN VER DISPOSITIVOS
    return Consumer<DispositivosRepository>(
      builder: (context, dispositivosRepo, _) {
        if (dispositivosRepo.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (dispositivosRepo.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${dispositivosRepo.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        // Filtrar dispositivos
        final dispositivosFiltrados = _filtrarDispositivos(
          dispositivosRepo.dispositivos,
        );

        return Scaffold(
          body: Column(
            children: [
              // Filtros
              _buildFiltros(dispositivosRepo),

              // Lista
              Expanded(
                child: dispositivosFiltrados.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: dispositivosFiltrados.length,
                          itemBuilder: (context, index) {
                            final dispositivo = dispositivosFiltrados[index];
                            return _buildDispositivoCard(
                              context,
                              dispositivo,
                              esAdmin, // ✅ Pasar si es admin
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          // ✅ TODOS pueden crear dispositivos
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _mostrarFormularioNuevo(context),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Dispositivo'),
          ),
        );
      },
    );
  }

  Widget _buildFiltros(DispositivosRepository repo) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por tipo:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text('Todos (${repo.dispositivos.length})'),
                selected: _filtroTipo == 'Todos',
                onSelected: (selected) {
                  if (selected) setState(() => _filtroTipo = 'Todos');
                },
              ),
              FilterChip(
                label: Text(
                  'Control Acceso (${repo.getDispositivosControlAcceso().length})',
                ),
                selected: _filtroTipo == 'Control Acceso',
                onSelected: (selected) {
                  if (selected) setState(() => _filtroTipo = 'Control Acceso');
                },
              ),
              FilterChip(
                label: Text(
                  'Sensores (${repo.getDispositivosSensor().length})',
                ),
                selected: _filtroTipo == 'Sensores',
                onSelected: (selected) {
                  if (selected) setState(() => _filtroTipo = 'Sensores');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Dispositivo> _filtrarDispositivos(List<Dispositivo> dispositivos) {
    switch (_filtroTipo) {
      case 'Control Acceso':
        return dispositivos.where((d) => d.requiereValidacion).toList();
      case 'Sensores':
        return dispositivos.where((d) => !d.requiereValidacion).toList();
      default:
        return dispositivos;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.devices_other, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _filtroTipo == 'Todos'
                ? 'No hay dispositivos registrados'
                : 'No hay dispositivos de tipo $_filtroTipo',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Usa el botón "+" para registrar uno nuevo.'),
        ],
      ),
    );
  }

  Widget _buildDispositivoCard(
    BuildContext context,
    Dispositivo dispositivo,
    bool esAdmin, // ✅ Recibe si es admin
  ) {
    final color = dispositivo.requiereValidacion ? Colors.blue : Colors.green;
    final iconData = dispositivo.requiereValidacion
        ? Icons.meeting_room
        : Icons.sensors;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(iconData, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                dispositivo.deviceId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            if (dispositivo.codigoTipo != 'N/A')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dispositivo.codigoTipo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dispositivo.tipoLegible),
            Text(
              dispositivo.protocolo,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        // ✅ SOLO ADMIN PUEDE ELIMINAR
        trailing: esAdmin
            ? IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                onPressed: () =>
                    _confirmarEliminar(context, dispositivo.deviceId),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información básica
                _buildInfoRow(Icons.category, 'Tipo', dispositivo.tipoLegible),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.settings_remote,
                  'Protocolo',
                  dispositivo.protocolo,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.security,
                  'Validación',
                  dispositivo.requiereValidacion ? 'Sí' : 'No',
                ),

                // Notas si existen
                if (dispositivo.notas != null) ...[
                  const Divider(height: 24),
                  const Text(
                    'Información Adicional',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  if (dispositivo.notas!.ubicacion != null)
                    _buildInfoRow(
                      Icons.location_on,
                      'Ubicación',
                      dispositivo.notas!.ubicacion!,
                    ),

                  if (dispositivo.notas!.responsable != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.person,
                      'Responsable',
                      dispositivo.notas!.responsable!,
                    ),
                  ],

                  if (dispositivo.notas!.notas != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.note,
                      'Notas',
                      dispositivo.notas!.notas!,
                    ),
                  ],
                ],

                // Fecha de registro
                if (dispositivo.fechaRegistro != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Registro',
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(dispositivo.fechaRegistro!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  void _mostrarFormularioNuevo(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DispositivoFormDialog(),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, String deviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas eliminar el dispositivo $deviceId?'),
            const SizedBox(height: 8),
            const Text(
              'Se eliminará de:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const Text('• IoT Agent', style: TextStyle(fontSize: 12)),
            const Text(
              '• Orion Context Broker',
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              '• Suscripciones activas',
              style: TextStyle(fontSize: 12),
            ),
            const Text('• Notas en MySQL', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            const Text(
              '⚠️ El historial en CrateDB se conserva',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar Todo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final token = context.read<AuthRepository>().token;
      if (token != null) {
        final result = await context
            .read<DispositivosRepository>()
            .eliminarDispositivo(token, deviceId);

        if (mounted) {
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['mensaje'] ?? 'Eliminado con éxito'),
                backgroundColor: Colors.green,
              ),
            );

            if (result['detalles'] != null) {
              _mostrarDetallesEliminacion(context, result['detalles']);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['mensaje'] ?? 'Error al eliminar'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  void _mostrarDetallesEliminacion(
    BuildContext context,
    Map<String, dynamic> detalles,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resultado de la Eliminación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetalleItem(
                'IoT Agent',
                detalles['iot_agent'],
                Icons.router,
              ),
              _buildDetalleItem(
                'Orion Entity',
                detalles['orion_entity'],
                Icons.cloud,
              ),
              const Divider(),
              const Text(
                'Suscripciones eliminadas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...((detalles['subscriptions'] as List?) ?? []).map((sub) {
                if (sub is Map) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text('• ${sub['id']}: ${sub['status']}'),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• $sub'),
                );
              }).toList(),
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

  Widget _buildDetalleItem(String label, dynamic valor, IconData icon) {
    final isSuccess = valor == 'eliminado' || valor == 'eliminado';
    final color = isSuccess ? Colors.green : Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(
            valor.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
