// lib/views/usuarios/tarjeta_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/repositories/auth_repository.dart';
import '/repositories/tarjetas_repository.dart';
import '/repositories/personas_repository.dart';
import '/services/notification_service.dart';
import '/utils/validators.dart';
import '/models/tarjeta.dart';

class TarjetaFormDialog extends StatefulWidget {
  final Tarjeta? tarjeta;

  const TarjetaFormDialog({Key? key, this.tarjeta}) : super(key: key);

  @override
  State<TarjetaFormDialog> createState() => _TarjetaFormDialogState();
}

class _TarjetaFormDialogState extends State<TarjetaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();

  String _estadoSeleccionado = 'activo';
  int? _personaIdSeleccionada;
  bool _isLoading = false;

  final List<String> _estados = ['activo', 'baja', 'perdida'];

  bool get _isEditing => widget.tarjeta != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _idController.text = widget.tarjeta!.id;
      _estadoSeleccionado = widget.tarjeta!.estado;
      _personaIdSeleccionada = widget.tarjeta!.personaId;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  bool _validarTarjetaDuplicada(String cardId) {
    final tarjetasRepo = context.read<TarjetasRepository>();

    if (_isEditing) {
      return false;
    }

    return tarjetasRepo.tarjetas.any((t) => t.id == cardId);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      NotificationService.error(
        context,
        'Por favor corrija los errores en el formulario',
        duration: const Duration(seconds: 10),
      );
      return;
    }

    final cardId = _idController.text.trim().toUpperCase();

    if (_validarTarjetaDuplicada(cardId)) {
      NotificationService.error(
        context,
        'La tarjeta $cardId ya está registrada',
        duration: const Duration(seconds: 10),
      );
      return;
    }

    setState(() => _isLoading = true);

    final token = context.read<AuthRepository>().token;
    if (token == null) {
      setState(() => _isLoading = false);
      NotificationService.error(
        context,
        'Sesión expirada. Inicie sesión nuevamente',
        duration: const Duration(seconds: 10),
      );
      return;
    }

    bool success;

    try {
      if (_isEditing) {
        success = await context.read<TarjetasRepository>().actualizarTarjeta(
          token,
          cardId: widget.tarjeta!.id,
          estado: _estadoSeleccionado,
          personaId: _personaIdSeleccionada,
        );
      } else {
        success = await context.read<TarjetasRepository>().crearTarjeta(
          token,
          id: cardId,
          estado: _estadoSeleccionado,
          personaId: _personaIdSeleccionada,
        );
      }

      setState(() => _isLoading = false);

      if (success) {
        final personaNombre = _personaIdSeleccionada != null
            ? context
                  .read<PersonasRepository>()
                  .getPersonaPorId(_personaIdSeleccionada!)
                  ?.nombre
            : null;

        Navigator.pop(context);

        NotificationService.success(
          context,
          _isEditing
              ? 'Tarjeta "$cardId" actualizada correctamente'
              : personaNombre != null
              ? 'Tarjeta "$cardId" creada y asignada a $personaNombre'
              : 'Tarjeta "$cardId" creada correctamente',
          duration: const Duration(seconds: 8),
        );
      } else {
        NotificationService.error(
          context,
          _isEditing ? 'Error al actualizar tarjeta' : 'Error al crear tarjeta',
          duration: const Duration(seconds: 12),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      NotificationService.error(
        context,
        'Error inesperado: $e',
        duration: const Duration(seconds: 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final personas = context.watch<PersonasRepository>().personas;

    return AlertDialog(
      title: Text(_isEditing ? 'Editar Tarjeta' : 'Nueva Tarjeta RFID'),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _idController,
                enabled: !_isEditing && !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'ID de Tarjeta',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: _isEditing ? null : Validators.tarjetaId,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: _estados
                    .map(
                      (estado) =>
                          DropdownMenuItem(value: estado, child: Text(estado)),
                    )
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _estadoSeleccionado = value);
                        }
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: _personaIdSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Asignar a Persona',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sin asignar'),
                  ),
                  ...personas.map((persona) {
                    return DropdownMenuItem<int?>(
                      value: persona.id,
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 200,
                            child: Text(
                              persona.nombre,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() => _personaIdSeleccionada = value);
                      },
              ),
            ],
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
              : Text(_isEditing ? 'Guardar Cambios' : 'Crear Tarjeta'),
        ),
      ],
    );
  }
}
