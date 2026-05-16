import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
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
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      final int s = Validators.passwordStrength(_passwordController.text);
      if (s != _passwordStrength) setState(() => _passwordStrength = s);
    });
  }

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
          email: Validators.normalizeEmail(_emailController.text),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
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
                const SizedBox(height: 24),
                CnhhjCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Crie sua conta',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Você é instrutor de aulas práticas de CNH',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CnhhjTextField(
                        controller: _nameController,
                        hint: 'Nome completo',
                        icon: PhosphorIconsRegular.user,
                        textInputAction: TextInputAction.next,
                        validator: Validators.fullName,
                      ),
                      const SizedBox(height: 10),
                      CnhhjTextField(
                        controller: _emailController,
                        hint: 'Digite seu email',
                        icon: PhosphorIconsRegular.envelope,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 10),
                      CnhhjPasswordField(
                        controller: _passwordController,
                        hint: 'Crie uma senha',
                        textInputAction: TextInputAction.next,
                        validator: Validators.password,
                      ),
                      if (_passwordController.text.isNotEmpty)
                        _PasswordStrengthBar(strength: _passwordStrength),
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
                        icon: PhosphorIconsRegular.userPlus,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Já tem conta? ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    CnhhjTextLink(
                      label: 'Entrar',
                      bold: true,
                      onPressed: () => context.go(AppRoutes.login),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 300.ms),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra horizontal de 4 segmentos que pinta de acordo com a força da
/// senha (0..4). Discreta — não exige interação, só feedback visual.
class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});
  final int strength; // 0..4

  static const List<String> _labels = <String>[
    '',
    'Muito fraca',
    'Fraca',
    'Boa',
    'Forte',
  ];

  Color _segColor(int idx) {
    if (idx >= strength) return AppColors.textPrimary.withOpacity(0.1);
    if (strength <= 1) return AppColors.error;
    if (strength == 2) return AppColors.warning;
    if (strength == 3) return AppColors.primary;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: List<Widget>.generate(
              4,
              (int i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: _segColor(i),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          if (strength > 0) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              _labels[strength],
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
