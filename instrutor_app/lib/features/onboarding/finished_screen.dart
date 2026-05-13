import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// "Cadastro Finalizado!" — tela de sucesso após o wizard. CTA leva para
/// a Home (a tela "Configurar aula", que é a aba AULA do bottom nav).
class FinishedScreen extends ConsumerWidget {
  const FinishedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CnhhjScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CnhhjLogo(size: 80),
          const SizedBox(height: 48),
          CnhhjCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.verified_rounded,
                  size: 56,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  'CADASTRO FINALIZADO!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cadastro enviado para análise, assim que validarmos suas informações iremos te notificar a liberação do seu aplicativo pelo seu e-mail cadastrado.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                CnhhjPrimaryButton(
                  label: 'Configurar aula',
                  onPressed: () => context.go(AppRoutes.lesson),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
