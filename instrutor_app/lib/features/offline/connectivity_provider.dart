import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado simples de conectividade. Esta é uma implementação manual/mock
/// — basta substituir por `connectivity_plus` quando for hora de produção.
///
/// Uso típico:
/// ```dart
/// final bool online = ref.watch(connectivityProvider);
/// if (!online) showCnhhjModal(...);
/// ```
class ConnectivityNotifier extends Notifier<bool> {
  @override
  bool build() => true; // assume online inicialmente

  /// Permite simular queda/retorno de conexão em telas de teste.
  /// Em produção isso vai ser substituído por listener real.
  void setOnline(bool value) => state = value;
}

final NotifierProvider<ConnectivityNotifier, bool> connectivityProvider =
    NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);
