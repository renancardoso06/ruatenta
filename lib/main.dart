import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/ocorrencia_repository.dart';
import 'screens/home_shell.dart';
import 'state/ocorrencias_controller.dart';

void main() {
  runApp(const BairroEmDiaApp());
}

class BairroEmDiaApp extends StatelessWidget {
  const BairroEmDiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // create é chamado uma única vez; o Provider chama dispose() do
      // controller quando o app é encerrado
      create: (_) =>
          OcorrenciasController(LocalOcorrenciaRepository())..iniciar(),
      child: MaterialApp(
        title: 'RuAtenta',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00695C),
          ),
          useMaterial3: true,
        ),
        home: const HomeShell(),
      ),
    );
  }
}
