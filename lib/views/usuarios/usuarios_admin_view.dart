// lib/views/usuarios/usuarios_admin_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/repositories/auth_repository.dart';
import '/settings/api_config.dart';

class UsuariosAdminView extends StatefulWidget {
  const UsuariosAdminView({Key? key}) : super(key: key);

  @override
  State<UsuariosAdminView> createState() => _UsuariosAdminViewState();
}

class _UsuariosAdminViewState extends State<UsuariosAdminView> {
  bool _cargando = true;
  List<Map<String, dynamic>> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);

    final token = context.read<AuthRepository>().token;
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/users'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _usuarios = data.cast<Map<String, dynamic>>();
          _cargando = false;
        });
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final currentUser = auth.currentUser;

    // ✅ PROTECCIÓN AGREGADA
    if (currentUser == null || !currentUser.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Panel de Administración',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Solo administradores pueden acceder',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final isRoot = currentUser.role == 'root';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarUsuarios,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _cargarUsuarios,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = _usuarios[index];
                  return _buildUsuarioCard(usuario, isRoot);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoNuevoUsuario(),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Usuario'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No hay usuarios registrados',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioCard(Map<String, dynamic> usuario, bool isRoot) {
    final username = usuario['username'] ?? 'Sin nombre';
    final role = usuario['role'] ?? 'user';
    final userId = usuario['id'];

    final colorRole = role == 'root'
        ? Colors.purple
        : role == 'admin'
        ? Colors.blue
        : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorRole.withOpacity(0.1),
          child: Icon(
            role == 'root' ? Icons.admin_panel_settings : Icons.person,
            color: colorRole,
          ),
        ),
        title: Text(
          username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorRole.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                  color: colorRole,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (userId != null) ...[
              const SizedBox(height: 4),
              Text(
                'ID: $userId',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: isRoot && role != 'root'
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _mostrarDialogoEditarUsuario(usuario);
                  } else if (value == 'delete') {
                    _confirmarEliminar(usuario);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  void _mostrarDialogoNuevoUsuario() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String roleSeleccionado = 'admin';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Usuario Admin'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario *',
                  hintText: 'nombre_usuario',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña *',
                  hintText: 'Mínimo 6 caracteres',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: roleSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    prefixIcon: Icon(Icons.security),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'user', child: Text('Usuario')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => roleSeleccionado = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final username = usernameController.text.trim();
              final password = passwordController.text.trim();

              if (username.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complete todos los campos'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (password.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'La contraseña debe tener mínimo 6 caracteres',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _crearUsuario(username, password, roleSeleccionado);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearUsuario(
    String username,
    String password,
    String role,
  ) async {
    final token = context.read<AuthRepository>().token;
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/users'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
        }),
      );

      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarUsuarios();
        } else {
          final error = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error['detail'] ?? 'Error desconocido'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogoEditarUsuario(Map<String, dynamic> usuario) {
    final passwordController = TextEditingController();
    String roleSeleccionado = usuario['role'] ?? 'admin';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar: ${usuario['username']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva Contraseña (opcional)',
                  hintText: 'Dejar vacío para no cambiar',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: roleSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    prefixIcon: Icon(Icons.security),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'user', child: Text('Usuario')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => roleSeleccionado = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _actualizarUsuario(
                usuario['id'],
                passwordController.text.trim(),
                roleSeleccionado,
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _actualizarUsuario(
    int userId,
    String? password,
    String role,
  ) async {
    final token = context.read<AuthRepository>().token;
    if (token == null) return;

    final body = <String, dynamic>{'role': role};
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(body),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarUsuarios();
        } else {
          throw Exception('Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> usuario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar el usuario "${usuario['username']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _eliminarUsuario(usuario['id']);
    }
  }

  Future<void> _eliminarUsuario(int userId) async {
    final token = context.read<AuthRepository>().token;
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarUsuarios();
        } else {
          throw Exception('Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
