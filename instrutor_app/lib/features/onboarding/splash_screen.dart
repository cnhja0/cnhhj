import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/cnhhj_logo.dart';

/// Tela inicial. Carrega por ~2 segundos enquanto:
///   • Restaura a sessão persistida (se houver)
///   • Decide rota seguinte: home (se logado) ou login (se não)
///
/// Visual cinematográfico alinhado ao tema "carro":
///   • Logo CNHhj emerge do centro com scale + fade
///   • Roda de direção gira em loop logo abaixo (efeito "motor ligado")
///   • Texto "Carregando..." aparece sutil
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
    final AuthRepository auth = ref.read(authRepositoryProvider);

    // Roda em paralelo: restaurar sessão + esperar 2s mínimo para a Splash
    // ser visualmente percebida pelo usuário (e não ser corte seco).
    await Future.wait<void>(<Future<void>>[
      auth.restoreSession(),
      Future<void>.delayed(const Duration(milliseconds: 2000)),
    ]);

    if (!mounted) return;
    if (auth.currentSession != null) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Logo emerge do centro com scale forte + fade
              const CnhhjLogo(size: 120)
                  .animate()
                  .scaleXY(
                    begin: 0.5,
                    end: 1.0,
                    duration: 700.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 500.ms)
                  .then(delay: 300.ms)
                  .animate(
                      onPlay: (AnimationController c) =>
                          c.repeat(reverse: true))
                  .scaleXY(
                    begin: 1.0,
                    end: 1.04,
                    duration: 1400.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 36),
              // Roda de direção girando em loop — "motor ligado"
              const Icon(
                PhosphorIconsFill.steeringWheel,
                size: 34,
                color: AppColors.textPrimary,
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms)
                  .scaleXY(
                    begin: 0.3,
                    end: 1.0,
                    delay: 500.ms,
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  )
                  .then()
                  .animate(
                      onPlay: (AnimationController c) => c.repeat())
                  .rotate(
                    duration: 1400.ms,
                    curve: Curves.linear,
                  ),
              const SizedBox(height: 14),
              // Texto sutil indicando carregamento
              Text(
                'Carregando...',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary.withOpacity(0.55),
                  letterSpacing: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 900.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
