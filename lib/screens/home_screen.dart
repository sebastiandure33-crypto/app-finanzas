import 'package:flutter/material.dart';

import 'deudas_screen.dart';
import 'movimientos_screen.dart';
import 'reportes_screen.dart';
import 'resumen_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  void _irA(int i) => setState(() => _indice = i);

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      ResumenScreen(irA: _irA),
      const MovimientosScreen(),
      const DeudasScreen(),
      const ReportesScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _indice, children: pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _irA,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: 'Deudas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}
