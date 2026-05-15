import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// "Cadastro Finalizado!" — tela de sucesso após o wizard. CTA leva para
/// a Home (aba AULA do bottom nav).
class FinishedScreen extends ConsumerWidget {
  const FinishedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CnhhjScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CnhhjLogo(size: 80)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 40),
          CnhhjCard(
            padding: const EdgeInsets.all(28),
            border: Border.all(color: AppColors.success, width: 2),
            child: Column(
              children: <Widget>[
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    PhosphorIconsFill.sealCheck,
                    size: 60,
                    color: AppColors.success,
                  ),
                )
                    .animate()
                    .scaleXY(
                      begin: 0.5,
                      end: 1.0,
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: 18),
                Text(
                  'CADASTRO FINALIZADO!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms),
                const SizedBox(height: 10),
                Text(
                  'Cadastro enviado para análise. Assim que validarmos suas informações, iremos te notificar a liberação do app pelo e-mail cadastrado.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 350.ms),
                const SizedBox(height: 24),
                CnhhjPrimaryButton(
                  label: 'Configurar aula',
                  icon: PhosphorIconsRegular.arrowRight,
                  onPressed: () => context.go(AppRoutes.lesson),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 350.ms)
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}
