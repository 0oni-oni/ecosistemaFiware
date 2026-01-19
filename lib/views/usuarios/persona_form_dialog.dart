// lib/views/usuarios/persona_form_dialog.dart (VERSIÓN FINAL MEJORADA)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/repositories/auth_repository.dart';
import '/repositories/personas_repository.dart';
import '/services/notification_service.dart';
import '/utils/validators.dart';
import '/models/persona.dart';

class PersonaFormDialog extends StatefulWidget {
  final Persona? persona;

  const PersonaFormDialog({Key? key, this.persona}) : super(key: key);

  @override
  State<PersonaFormDialog> createState() => _PersonaFormDialogState();
}

class _PersonaFormDialogState extends State<PersonaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cedulaController = TextEditingController();

  String _rolSeleccionado = 'estudiante';
  bool _isLoading = false;

  final List<String> _roles = [
    'estudiante',
    'profesor',
    'administrador',
    'visitante',
  ];

  bool get _isEditing => widget.persona != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nombreController.text = widget.persona!.nombre;
      _cedulaController.text = widget.persona!.cedula;
      _rolSeleccionado = widget.persona!.rol;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  /// ✅ VALIDAR CÉDULA DUPLICADA
  bool _validarCedulaDuplicada(String cedula) {
    final personasRepo = context.read<PersonasRepository>();

    // Si estamos editando, ignorar la cédula actual
    if (_isEditing) {
      return personasRepo.personas.any(
        (p) => p.cedula == cedula && p.id != widget.persona!.id,
      );
    }

    // Si estamos creando, verificar si ya existe
    return personasRepo.personas.any((p) => p.cedula == cedula);
  }

  Future<void> _guardar() async {
    // ✅ Validar formulario con mensajes visibles
    if (!_formKey.currentState!.validate()) {
      // ✅ Mensaje de error PERSISTENTE (10 segundos)
      NotificationService.error(
        context,
        '❌ Por favor corrija los errores en el formulario',
        duration: const Duration(seconds: 10),
      );
      return;
    }

    final cedula = _cedulaController.text.trim();

    // ✅ VALIDAR CÉDULA DUPLICADA ANTES DE ENVIAR
    if (_validarCedulaDuplicada(cedula)) {
      NotificationService.error(
        context,
        '❌ La cédula $cedula ya está registrada',
        duration: const Duration(seconds: 10),
      );
      return;
    }

    setState(() => _isLoading = true);

    final token = context.read<AuthRepository>().token;
    if (token == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        NotificationService.error(
          context,
          '❌ Sesión expirada. Por favor inicie sesión nuevamente',
          duration: const Duration(seconds: 10),
        );
      }
      return;
    }

    bool success;
    final nombre = _nombreController.text.trim();

    try {
      if (_isEditing) {
        // ACTUALIZAR
        success = await context.read<PersonasRepository>().actualizarPersona(
          token,
          personaId: widget.persona!.id,
          nombre: nombre,
          cedula: cedula,
          rol: _rolSeleccionado,
        );
      } else {
        // CREAR
        success = await context.read<PersonasRepository>().crearPersona(
          token,
          nombre: nombre,
          cedula: cedula,
          rol: _rolSeleccionado,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          Navigator.pop(context);

          // ✅ Notificación de éxito VISIBLE (8 segundos)
          NotificationService.success(
            context,
            _isEditing
                ? '✅ Persona "$nombre" actualizada correctamente'
                : '✅ Persona "$nombre" creada correctamente',
            duration: const Duration(seconds: 8),
          );
        } else {
          // ✅ Notificación de error VISIBLE Y PERSISTENTE (12 segundos)
          NotificationService.error(
            context,
            _isEditing
                ? '❌ Error al actualizar persona. Intente nuevamente'
                : '❌ Error al crear persona. Verifique los datos e intente nuevamente',
            duration: const Duration(seconds: 12),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // ✅ Error con detalles técnicos (15 segundos)
        NotificationService.error(
          context,
          '❌ Error inesperado: ${e.toString()}',
          duration: const Duration(seconds: 15),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_isEditing ? Icons.edit : Icons.person_add, color: Colors.blue),
          const SizedBox(width: 8),
          Text(_isEditing ? 'Editar Persona' : 'Nueva Persona'),
        ],
      ),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo *',
                  prefixIcon: Icon(Icons.person),
                  helperText: 'Ej: Juan Pérez García',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: Validators.nombre,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Campo Cédula
              TextFormField(
                controller: _cedulaController,
                decoration: const InputDecoration(
                  labelText: 'Cédula *',
                  prefixIcon: Icon(Icons.badge),
                  helperText: '10 dígitos (validación ecuatoriana)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 10,
                validator: Validators.cedula,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Selector de Rol
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Rol *',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                items: _roles.map((rol) {
                  return DropdownMenuItem(
                    value: rol,
                    child: Text(rol[0].toUpperCase() + rol.substring(1)),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _rolSeleccionado = value);
                        }
                      },
              ),

              // Info de tarjeta si existe
              if (_isEditing && widget.persona!.tarjetaId != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tarjeta asignada: ${widget.persona!.tarjetaId}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
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
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isEditing ? 'Guardar Cambios' : 'Crear Persona'),
        ),
      ],
    );
  }
}
