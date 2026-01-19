// lib/views/usuarios/personas_tab.dart (REFACTORIZADO)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/repositories/auth_repository.dart';
import '/repositories/personas_repository.dart';
import '/services/notification_service.dart';
import '/widgets/common_widgets.dart';
import 'persona_form_dialog.dart';

class PersonasTab extends StatelessWidget {
  const PersonasTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonasRepository>(
      builder: (context, personasRepo, _) {
        // Estado de carga
        if (personasRepo.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Estado de error
        if (personasRepo.error != null) {
          return ErrorStateWidget(
            message: personasRepo.error!,
            icon: Icons.error,
            onRetry: () async {
              final token = context.read<AuthRepository>().token;
              if (token != null) {
                await personasRepo.fetchPersonas(token);
              }
            },
          );
        }

        // Estado vacío
        if (personasRepo.personas.isEmpty) {
          return EmptyStateWidget(
            message: 'No hay personas registradas',
            subtitle: 'Presiona + para agregar la primera persona',
            icon: Icons.people_outline,
          );
        }

        // Lista de personas
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              final token = context.read<AuthRepository>().token;
              if (token != null) {
                await personasRepo.fetchPersonas(token);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: personasRepo.personas.length,
              itemBuilder: (context, index) {
                final persona = personasRepo.personas[index];
                return _PersonaCard(persona: persona);
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
      builder: (context) => const PersonaFormDialog(),
    );
  }
}

/// Widget para tarjeta de persona
class _PersonaCard extends StatelessWidget {
  final dynamic persona;

  const _PersonaCard({required this.persona});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Text(
            persona.nombre[0].toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          persona.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.badge, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Cédula: ${persona.cedula}'),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.work, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Rol: ${persona.rol}'),
              ],
            ),
            if (persona.tarjetaId != null)
              Row(
                children: [
                  const Icon(Icons.credit_card, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Tarjeta: ${persona.tarjetaId}',
                    style: const TextStyle(color: Colors.blue),
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
                builder: (context) => PersonaFormDialog(persona: persona),
              );
            } else if (value == 'Eliminar') {
              await _confirmarEliminar(context, persona.id, persona.nombre);
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

  Future<void> _confirmarEliminar(
    BuildContext context,
    int personaId,
    String nombre,
  ) async {
    // ✅ Confirmación visible
    final confirm = await NotificationService.confirm(
      context,
      title: '⚠️ Confirmar Eliminación',
      message:
          '¿Está seguro de eliminar a "$nombre"?\n\nEsta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      type: NotificationType.error,
    );

    if (confirm && context.mounted) {
      final token = context.read<AuthRepository>().token;
      if (token != null) {
        final success = await context
            .read<PersonasRepository>()
            .eliminarPersona(token, personaId);

        if (context.mounted) {
          if (success) {
            // ✅ Notificación de éxito VISIBLE
            NotificationService.success(
              context,
              '✅ Persona "$nombre" eliminada correctamente',
            );
          } else {
            // ✅ Notificación de error VISIBLE
            NotificationService.error(
              context,
              '❌ Error al eliminar persona "$nombre"',
            );
          }
        }
      }
    }
  }
}
