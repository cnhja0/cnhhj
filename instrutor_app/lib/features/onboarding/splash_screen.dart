import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/cnhhj_logo.dart';
import '../../shared/widgets/onboarding_progress_bar.dart';

/// Tela inicial exibida enquanto o app decide para onde mandar o usuário
/// (login, onboarding ou home, dependendo do estado de autenticação).
///
/// Visualmente replica o frame "Carregamento" do Figma: fundo amarelo
/// com o logo centralizado e barra de progresso (apenas decorativa
/// nesta tela — usada como elemento de marca).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextRoute();
  }

  Future<void> _decideNextRoute() async {
    // Espera de 1.5s para a Splash ser visível.
    // No futuro: checar sessão atual e decidir entre login /
    // onboarding (cadastro incompleto) / home (já cadastrado).
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 40),
              OnboardingProgressBar(
                totalSteps: 3,
                currentStep: 0, // tudo pendente — visual decorativo
              ),
              Spacer(),
              CnhhjLogo(size: 96),
              Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
