import 'package:flutter/material.dart';

import 'acompanhar_screen.dart';
import 'indicadores_screen.dart';
import 'mapa_screen.dart';
import 'registrar_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  void _irPara(int i) => setState(() => _indice = i);

  Widget _paginaAtual() {
    switch (_indice) {
      case 0:
        return const MapaScreen();
      case 1:
        return RegistrarScreen(onRegistrado: () => _irPara(2));
      case 2:
        return const AcompanharScreen();
      default:
        return const IndicadoresScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _paginaAtual()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _irPara,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
            tooltip: 'Mapa de ocorrências',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_location_alt_outlined),
            selectedIcon: Icon(Icons.add_location_alt),
            label: 'Registrar',
            tooltip: 'Registrar um problema',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Acompanhar',
            tooltip: 'Acompanhar ocorrências',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Indicadores',
            tooltip: 'Indicadores do bairro',
          ),
        ],
      ),
    );
  }
}
