import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
      // TODO: navegar para home quando ela existir.
      CnhhjSnack.success(context, 'Login realizado!');
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
      CnhhjSnack.success(context, 'Login realizado!');
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
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 24),
                const CnhhjLogo(size: 72),
                const SizedBox(height: 16),
                const _PromoBanner(),
                const SizedBox(height: 20),
                CnhhjCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Faça o login na sua conta',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CnhhjGoogleSignInButton(onPressed: _googleSignIn),
                      const SizedBox(height: 14),
                      CnhhjTextField(
                        controller: _emailController,
                        hint: 'Digite seu email',
                        icon: Icons.mail_outline,
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
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Não tem conta? ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    CnhhjTextLink(
                      label: 'Clique aqui e crie a sua.',
                      bold: true,
                      onPressed: () => context.go(AppRoutes.signUp),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder do banner promocional do topo (no Figma é uma imagem
/// "SUA CNH COMEÇA AQUI! AULAS COMPLETAS"). Quando você fornecer o asset
/// real, substituímos este widget por `Image.asset('assets/images/promo_banner.png')`.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'AQUI!',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aulas completas',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.surface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'CNHhj',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
