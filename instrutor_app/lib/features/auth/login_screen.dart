import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import 'login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final bool ok = await ref
        .read(loginControllerProvider.notifier)
        .signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.home);
    } else {
      final String? err = ref.read(loginControllerProvider).errorMessage;
      if (err != null) CnhhjSnack.error(context, err);
    }
  }

  Future<void> _googleSignIn() async {
    final bool ok =
        await ref.read(loginControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.home);
    } else {
      final String? err = ref.read(loginControllerProvider).errorMessage;
      if (err != null) CnhhjSnack.error(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LoginState state = ref.watch(loginControllerProvider);

    return CnhhjLoadingOverlay(
      show: state.loading,
      message: 'Entrando...',
      child: CnhhjScaffold(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 24),
                const CnhhjLogo(size: 72)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scaleXY(
                      begin: 0.9,
                      end: 1.0,
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 18),
                const _PromoBanner()
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 20),
                CnhhjCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Faça o login na sua conta',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CnhhjGoogleSignInButton(onPressed: _googleSignIn),
                      const SizedBox(height: 14),
                      CnhhjTextField(
                        controller: _emailController,
                        hint: 'Digite seu email',
                        icon: PhosphorIconsRegular.envelope,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (String? v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe o e-mail';
                          }
                          if (!v.contains('@')) return 'E-mail inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      CnhhjPasswordField(
                        controller: _passwordController,
                        hint: 'Digite sua senha',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (String? v) {
                          if (v == null || v.isEmpty) {
                            return 'Informe a senha';
                          }
                          if (v.length < 6) {
                            return 'A senha precisa ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: CnhhjTextLink(
                          label: 'Esqueci minha senha',
                          fontSize: 12,
                          onPressed: () {
                            // TODO: rota de recuperação de senha
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      CnhhjPrimaryButton(
                        label: 'Entrar',
                        icon: PhosphorIconsRegular.signIn,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: CnhhjTextLink(
                          label: 'Políticas de Privacidade',
                          fontSize: 12,
                          onPressed: () {
                            // TODO: abrir tela/url de políticas
                          },
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Não tem conta? ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    CnhhjTextLink(
                      label: 'Clique aqui e crie a sua.',
                      bold: true,
                      onPressed: () => context.go(AppRoutes.signUp),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 300.ms),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner promocional do topo do login.
/// Quando você fornecer o asset real, substituímos por `Image.asset(...)`.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1a1a1a), Color(0xFF000000)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'SUA CNH COMEÇA',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'AQUI!',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Icon(
                      PhosphorIconsFill.check,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Aulas completas com instrutores credenciados',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.surface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const CnhhjLogo(size: 32, iconOnly: true),
          ),
        ],
      ),
    );
  }
}
