import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import 'sign_up_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _acceptedTerms = false;
  bool _acceptedPromos = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      CnhhjSnack.error(
        context,
        'Você precisa aceitar os termos e a política de privacidade.',
      );
      return;
    }

    final bool ok = await ref
        .read(signUpControllerProvider.notifier)
        .createInstructorAccount(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );

    if (!mounted) return;
    if (ok) {
      CnhhjSnack.success(context, 'Conta criada! Vamos completar seu cadastro.');
      context.go('/onboarding/1');
    } else {
      final String? err = ref.read(signUpControllerProvider).errorMessage;
      if (err != null) CnhhjSnack.error(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SignUpState state = ref.watch(signUpControllerProvider);

    return CnhhjLoadingOverlay(
      show: state.loading,
      message: 'Criando sua conta...',
      child: CnhhjScaffold(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 24),
                const CnhhjLogo(size: 72),
                const SizedBox(height: 24),
                CnhhjCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Crie sua conta',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Você é instrutor de aulas práticas de CNH',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CnhhjTextField(
                        controller: _nameController,
                        hint: 'Nome completo',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (String? v) =>
                            (v == null || v.trim().length < 3)
                                ? 'Informe seu nome completo'
                                : null,
                      ),
                      const SizedBox(height: 10),
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
                        hint: 'Crie uma senha',
                        textInputAction: TextInputAction.next,
                        validator: (String? v) {
                          if (v == null || v.isEmpty) return 'Crie uma senha';
                          if (v.length < 6) {
                            return 'A senha precisa ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      CnhhjPasswordField(
                        controller: _confirmController,
                        hint: 'Confirme a senha',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (String? v) {
                          if (v != _passwordController.text) {
                            return 'As senhas não conferem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CnhhjCheckbox(
                        value: _acceptedTerms,
                        onChanged: (bool v) =>
                            setState(() => _acceptedTerms = v),
                        label:
                            'Li e aceito os Termos de Uso e a Política de Privacidade',
                      ),
                      CnhhjCheckbox(
                        value: _acceptedPromos,
                        onChanged: (bool v) =>
                            setState(() => _acceptedPromos = v),
                        label:
                            'Desejo receber notificações de promoções da plataforma',
                      ),
                      const SizedBox(height: 16),
                      CnhhjPrimaryButton(
                        label: 'Criar conta',
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Já tem conta? ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    CnhhjTextLink(
                      label: 'Entrar',
                      bold: true,
                      onPressed: () => context.go(AppRoutes.login),
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
