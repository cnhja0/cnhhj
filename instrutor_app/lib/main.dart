import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega variáveis do .env. Env.load() já trata internamente a ausência
  // do arquivo (cai para defaults, modo mock).
  await Env.load();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ProviderScope(child: CnhhjApp()));
}
