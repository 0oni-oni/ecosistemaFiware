// lib/views/usuarios/tarjetas_tab.dart (REFACTORIZADO)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/repositories/auth_repository.dart';
import '/repositories/tarjetas_repository.dart';
import '/services/notification_service.dart';
import '/widgets/common_widgets.dart';
import 'tarjeta_form_dialog.dart';

class TarjetasTab extends StatelessWidget {
  const TarjetasTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TarjetasRepository>(
      builder: (context, tarjetasRepo, _) {
        // Estado de carga
        if (tarjetasRepo.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Estado de error
        if (tarjetasRepo.error != null) {
          return ErrorStateWidget(
            message: tarjetasRepo.error!,
            icon: Icons.error,
            onRetry: () async {
              final token = context.read<AuthRepository>().token;
              if (token != null) {
                await tarjetasRepo.fetchTarjetas(token);
              }
            },
          );
        }

        // Estado vacío
        if (tarjetasRepo.tarjetas.isEmpty) {
          return EmptyStateWidget(
            message: 'No hay tarjetas registradas',
            subtitle: 'Presiona + para registrar la primera tarjeta',
            icon: Icons.credit_card_outlined,
          );
        }

        // Lista de tarjetas
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              final token = context.read<AuthRepository>().token;
              if (token != null) {
                await tarjetasRepo.fetchTarjetas(token);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tarjetasRepo.tarjetas.length,
              itemBuilder: (context, index) {
                final tarjeta = tarjetasRepo.tarjetas[index];
                return _TarjetaCard(tarjeta: tarjeta);
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _mostrarFormulario(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _mostrarFormulario(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TarjetaFormDialog(),
    );
  }
}

/// Widget para tarjeta RFID
class _TarjetaCard extends StatelessWidget {
  final dynamic tarjeta;

  const _TarjetaCard({required this.tarjeta});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tarjeta.estadoColor.withOpacity(0.2),
          child: Icon(Icons.credit_card, color: tarjeta.estadoColor),
        ),
        title: Text(
          tarjeta.id,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Dueño: ${tarjeta.personaNombre ?? "Sin asignar"}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: tarjeta.estadoColor),
                const SizedBox(width: 6),
                Text(
                  'Estado: ${tarjeta.estado.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tarjeta.estadoColor,
                  ),
                ),
              ],
            ),
            if (tarjeta.fechaEntrega != null)
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Entrega: ${DateFormat('dd/MM/yyyy').format(tarjeta.fechaEntrega!)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'Editar') {
              showDialog(
                context: context,
                builder: (context) => TarjetaFormDialog(tarjeta: tarjeta),
              );
            } else if (value == 'Eliminar') {
              await _confirmarEliminar(context, tarjeta.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'Editar',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'Eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, String cardId) async {
    // ✅ Confirmación visible
    final confirm = await NotificationService.confirm(
      context,
      title: '⚠️ Confirmar Eliminación',
      message:
          '¿Está seguro de eliminar la tarjeta "$cardId"?\n\nEsta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      type: NotificationType.error,
    );

    if (confirm && context.mounted) {
      final token = context.read<AuthRepository>().token;
      if (token != null) {
        final success = await context
            .read<TarjetasRepository>()
            .eliminarTarjeta(token, cardId);

        if (context.mounted) {
          if (success) {
            // ✅ Notificación de éxito VISIBLE
            NotificationService.success(
              context,
              '✅ Tarjeta "$cardId" eliminada correctamente',
            );
          } else {
            // ✅ Notificación de error VISIBLE
            NotificationService.error(
              context,
              '❌ Error al eliminar tarjeta "$cardId"',
            );
          }
        }
      }
    }
  }
}
