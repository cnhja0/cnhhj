import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/cnhhj_logo.dart';

/// Tela inicial. Carrega por ~2 segundos enquanto:
///   • Restaura a sessão persistida (se houver)
///   • Decide rota seguinte: home (se logado) ou login (se não)
///
/// Visualmente: logo CNHhj centralizado com pulso suave e bolinhas
/// de loading no rodapé.
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
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            const CnhhjLogo(size: 120)
                .animate()
                .scaleXY(
                  begin: 0.8,
                  end: 1.0,
                  duration: 700.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 500.ms)
                .then(delay: 200.ms)
                .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1.0,
                  end: 1.04,
                  duration: 1200.ms,
                  curve: Curves.easeInOut,
                ),
            Positioned(
              bottom: 60,
              child: const _LoadingDots()
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3 bolinhas pulsando no fundo da splash — indica que algo está rolando.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (int i) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (AnimationController c) => c.repeat())
            .fadeIn(duration: 400.ms, delay: (i * 150).ms)
            .then()
            .fadeOut(duration: 400.ms, delay: 600.ms);
      }),
    );
  }
}
