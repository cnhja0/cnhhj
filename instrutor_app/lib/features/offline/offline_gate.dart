import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/widgets.dart';
import 'connectivity_provider.dart';

/// Wrapper global que monitora conectividade e exibe modal "Sem sinal"
/// (espelhando o frame do Figma) quando o app perde conexão.
///
/// Coloque na raiz do app, envolvendo o MaterialApp.
class OfflineGate extends ConsumerStatefulWidget {
  const OfflineGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<OfflineGate> createState() => _OfflineGateState();
}

class _OfflineGateState extends ConsumerState<OfflineGate> {
  bool _modalOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(connectivityProvider, (bool? prev, bool next) {
      if (!next && !_modalOpen) {
        _modalOpen = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await showCnhhjModal(
            context: context,
            icon: Icons.wifi_off_rounded,
            title: 'SEM SINAL',
            message:
                'Parece que você está sem sinal, atualize a página para seus dados continuarem atualizados.',
            primaryLabel: 'Atualizar',
            onPrimary: () {
              // Em produção, refazer a verificação.
              ref.read(connectivityProvider.notifier).setOnline(true);
              Navigator.of(context).pop();
            },
            dismissible: false,
          );
          _modalOpen = false;
        });
      }
    });
    return widget.child;
  }
}
