import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Scaffold pré-configurado com o padrão visual do CNHhj:
/// fundo amarelo, padding lateral, SafeArea e suporte a barra de progresso
/// do onboarding como header opcional.
class CnhhjScaffold extends StatelessWidget {
  const CnhhjScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.backgroundColor = AppColors.primary,
    this.resizeToAvoidBottomInset = true,
    this.headerTop,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final bool resizeToAvoidBottomInset;

  /// Widget mostrado entre o topo seguro e o conteúdo principal — perfeito
  /// para a OnboardingProgressBar no onboarding do instrutor.
  final Widget? headerTop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: Column(
            children: <Widget>[
              if (headerTop != null) ...<Widget>[
                headerTop!,
                const SizedBox(height: 24),
              ],
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
