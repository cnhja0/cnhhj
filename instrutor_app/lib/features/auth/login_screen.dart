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

/// Tela de login com animações especiais:
///
/// - **Entrada**: logo e card emergem do centro com scale + fade
/// - **Saída** (após login bem-sucedido): o conteúdo desliza para a direita
///   acelerando, simultaneamente uma roda de direção atravessa a tela
///   como um carro em alta velocidade, e só então navega para a Home.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Duração total da animação de saída (slide do conteúdo + carro).
  static const Duration _exitDuration = Duration(milliseconds: 800);

  /// Quando true, conteúdo desliza pra direita e o carro atravessa a tela.
  bool _exiting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runExitAnimation() async {
    if (!mounted) return;
    setState(() => _exiting = true);
    await Future<void>.delayed(_exitDuration);
    if (!mounted) return;
    context.go(AppRoutes.home);
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
      await _runExitAnimation();
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
      await _runExitAnimation();
    } else {
      final String? err = ref.read(loginControllerProvider).errorMessage;
      if (err != null) CnhhjSnack.error(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LoginState state = ref.watch(loginControllerProvider);

    return CnhhjLoadingOverlay(
      // Esconde o spinner durante a animação de saída — a animação é
      // o feedback suficiente.
      show: state.loading && !_exiting,
      message: 'Entrando...',
      child: CnhhjScaffold(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Stack(
          children: <Widget>[
            // ─── Conteúdo principal — desliza pra direita ao sair ────
            AnimatedSlide(
              duration: _exitDuration,
              curve: Curves.easeInQuart, // acelera (como carro saindo)
              offset: _exiting ? const Offset(1.4, 0) : Offset.zero,
              child: AnimatedOpacity(
                duration: _exitDuration,
                opacity: _exiting ? 0.0 : 1.0,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(height: 24),
                        // Logo entra com scale + fade do centro
                        const CnhhjLogo(size: 80)
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .scaleXY(
                              begin: 0.6,
                              end: 1.0,
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(height: 22),
                        const _PromoBanner()
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .scaleXY(
                              begin: 0.92,
                              end: 1.0,
                              delay: 200.ms,
                              duration: 400.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 22),
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
                              CnhhjGoogleSignInButton(
                                onPressed: _exiting ? null : _googleSignIn,
                              ),
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
                                  if (!v.contains('@')) {
                                    return 'E-mail inválido';
                                  }
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
                                onPressed: _exiting ? null : _submit,
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
                            .fadeIn(delay: 350.ms, duration: 450.ms)
                            .scaleXY(
                              begin: 0.94,
                              end: 1.0,
                              delay: 350.ms,
                              duration: 450.ms,
                              curve: Curves.easeOutCubic,
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            CnhhjTextLink(
                              label: 'Clique aqui e crie a sua.',
                              bold: true,
                              onPressed: _exiting
                                  ? null
                                  : () => context.go(AppRoutes.signUp),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 300.ms),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── Carro atravessando a tela durante a saída ──────────
            if (_exiting)
              const Positioned.fill(
                child: IgnorePointer(child: _CarDriveAcross()),
              ),
          ],
        ),
      ),
    );
  }
}

/// Roda de direção que atravessa a tela rapidamente da esquerda para
/// a direita — efeito de "carro saindo" durante a transição.
class _CarDriveAcross extends StatelessWidget {
  const _CarDriveAcross();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -2.2, end: 2.8),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInQuart,
      builder: (BuildContext context, double xAlign, Widget? child) {
        return Stack(
          children: <Widget>[
            // Speed lines (rastros de velocidade)
            Align(
              alignment: Alignment(xAlign - 0.6, 0.05),
              child: _SpeedLine(opacity: (xAlign + 2.2) / 5.0),
            ),
            // Roda de direção girando
            Align(
              alignment: Alignment(xAlign, 0),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: child,
              ),
            ),
          ],
        );
      },
      child: const Icon(
        PhosphorIconsFill.steeringWheel,
        size: 56,
        color: AppColors.primary,
      )
          .animate(onPlay: (AnimationController c) => c.repeat())
          .rotate(
            duration: 400.ms,
            curve: Curves.linear,
          ),
    );
  }
}

/// Linha de velocidade — rastro horizontal atrás da roda.
class _SpeedLine extends StatelessWidget {
  const _SpeedLine({required this.opacity});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.textPrimary.withOpacity(0.0),
            AppColors.textPrimary.withOpacity(opacity.clamp(0.0, 0.55)),
          ],
        ),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// Banner promocional do topo do login.
///
/// Suporta dois modos:
///
/// 1. **Imagem customizada (preferido quando você tiver o criativo):**
///    Salve o arquivo em
///    `instrutor_app/assets/images/login/banner.png`
///    (recomendado: 720x310px, PNG ou JPG, até ~200KB).
///    Ao detectar o asset, o banner renderiza a imagem em full-bleed.
///
/// 2. **Fallback gerado por código** (atual, quando o asset não existe):
///    Card preto com gradient + texto "SUA CNH COMEÇA AQUI!" + pílula
///    amarela com logo CNHhj. É o que aparece se você ainda não
///    forneceu uma imagem.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  /// Caminho do criativo customizado. Se este arquivo existir no bundle,
  /// é renderizado em vez do fallback gerado.
  static const String _customAsset = 'assets/images/login/banner.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        // Tenta carregar a imagem custom. Se falhar (asset não existe),
        // mostra o fallback gerado por código.
        child: Image.asset(
          _customAsset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 150,
          errorBuilder:
              (BuildContext c, Object e, StackTrace? s) =>
                  const _PromoBannerFallback(),
        ),
      ),
    );
  }
}

/// Fallback do banner promocional — gerado por código.
/// Aparece quando o asset `assets/images/login/banner.png` não existe.
class _PromoBannerFallback extends StatelessWidget {
  const _PromoBannerFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1a1a1a), Color(0xFF000000)],
        ),
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
