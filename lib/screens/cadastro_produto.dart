// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_side_menu.dart';

class CadastroProdutoScreen extends StatefulWidget {
  const CadastroProdutoScreen({super.key});

  @override
  State<CadastroProdutoScreen> createState() => _CadastroProdutoScreenState();
}

class _CadastroProdutoScreenState extends State<CadastroProdutoScreen> {
  bool _drawerExpanded = true;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      Future.microtask(() {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      });
      return const SizedBox();
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: Image.asset(
          'assets/Logo2.png',
          height: 40,
          fit: BoxFit.contain,
        ),
      ),

      drawer: AppSideMenu(
        expanded: _drawerExpanded,
        onToggle: () => setState(() => _drawerExpanded = !_drawerExpanded),
        selectedRoute: ModalRoute.of(context)?.settings.name,
        onNavigate: (route) {
          Navigator.pop(context);
          if (route == (ModalRoute.of(context)?.settings.name)) return;
          Navigator.pushReplacementNamed(context, route);
        },
      ),
      body: const Center(
          child: Text(
            'Page Cadastro Produto',
            style: TextStyle(fontSize: 32),
          ),
        ),
    );
  }
}

