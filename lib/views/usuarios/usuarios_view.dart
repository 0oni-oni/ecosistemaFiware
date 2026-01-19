// lib/views/usuarios/usuarios_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/repositories/auth_repository.dart';
import '/repositories/personas_repository.dart';
import '/repositories/tarjetas_repository.dart';
import 'personas_tab.dart';
import 'tarjetas_tab.dart';

class UsuariosView extends StatelessWidget {
  const UsuariosView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final user = auth.currentUser;

    // 🔒 BLOQUEO TOTAL: si no es admin, esta vista NO existe
    if (user == null || !user.isAdmin) {
      return const SizedBox.shrink();
    }

    return const _UsuariosAdminView();
  }
}

class _UsuariosAdminView extends StatefulWidget {
  const _UsuariosAdminView({Key? key}) : super(key: key);

  @override
  State<_UsuariosAdminView> createState() => _UsuariosAdminViewState();
}

class _UsuariosAdminViewState extends State<_UsuariosAdminView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthRepository>();
    final token = auth.token;

    if (token == null) return;

    await Future.wait([
      context.read<PersonasRepository>().fetchPersonas(token),
      context.read<TarjetasRepository>().fetchTarjetas(token),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Personas'),
            Tab(icon: Icon(Icons.credit_card), text: 'Tarjetas'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [PersonasTab(), TarjetasTab()],
          ),
        ),
      ],
    );
  }
}
