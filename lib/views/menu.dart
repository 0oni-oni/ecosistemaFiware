// lib/views/menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/repositories/auth_repository.dart';

import 'usuarios/usuarios_view.dart';
import 'usuarios/usuarios_admin_view.dart';
import 'dispositivos/dispositivos_view.dart';
import 'analytics/analytics_view.dart';
import 'crate_explorer/crate_explorer_view.dart';
import '/views/login_view.dart';

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({Key? key}) : super(key: key);

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final currentUser = auth.currentUser;

    // 🔒 BLOQUEO CRÍTICO: si no hay usuario, NO renderizar menú
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool esAdmin = currentUser.isAdmin;

    // 📄 PÁGINAS
    final List<Widget> pages = [
      if (esAdmin) const UsuariosView(),
      const DispositivosView(),
      const AnalyticsView(),
      const CrateExplorerView(),
      if (esAdmin) const UsuariosAdminView(),
    ];

    // 🧭 DESTINOS
    final List<NavigationDestination> destinations = [
      if (esAdmin)
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Usuarios',
        ),
      const NavigationDestination(
        icon: Icon(Icons.devices_outlined),
        selectedIcon: Icon(Icons.devices),
        label: 'Dispositivos',
      ),
      const NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: 'Sensores',
      ),
      const NavigationDestination(
        icon: Icon(Icons.storage_outlined),
        selectedIcon: Icon(Icons.storage),
        label: 'CrateDB',
      ),
      if (esAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    // 🛡️ PROTECCIÓN DE ÍNDICE
    if (_selectedIndex >= pages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedIndex = 0);
        }
      });
    }

    void _onItemTapped(int index) {
      if (!_isLoggingOut && mounted) {
        setState(() => _selectedIndex = index);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartLab FIWARE'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentUser.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  esAdmin ? 'Admin' : 'Usuario',
                  style: TextStyle(
                    fontSize: 10,
                    color: esAdmin ? Colors.orange : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout),
            onPressed: _isLoggingOut ? null : () => _handleLogout(auth),
          ),
        ],
      ),
      body: pages.isNotEmpty && _selectedIndex < pages.length
          ? pages[_selectedIndex]
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex >= destinations.length
            ? 0
            : _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: destinations,
      ),
    );
  }

  Future<void> _handleLogout(AuthRepository auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoggingOut = true);

      try {
        await auth.logout();
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginView()),
            (_) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoggingOut = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
