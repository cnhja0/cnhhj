import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../home_state.dart';

/// Banner rotativo no topo da Home — slides que se alternam a cada 5s
/// com indicadores (dots) abaixo. Suporta swipe manual e tap em cada slide.
///
/// ╔══════════════════════════════════════════════════════════════════╗
/// ║ Como adicionar/editar criativos                                  ║
/// ╠══════════════════════════════════════════════════════════════════╣
/// ║                                                                  ║
/// ║ 1. CRIATIVO DE IMAGEM (banner pronto do designer):               ║
/// ║                                                                  ║
/// ║    a. Salve o arquivo em:                                        ║
/// ║       instrutor_app/assets/images/banners/seu_nome.png           ║
/// ║                                                                  ║
/// ║    b. Adicione um _BannerSlide com imageAsset:                   ║
/// ║       _BannerSlide.image(                                        ║
/// ║         imageAsset: 'assets/images/banners/seu_nome.png',        ║
/// ║         onTap: () => ...,                                        ║
/// ║       )                                                          ║
/// ║                                                                  ║
/// ║    c. Dimensão recomendada: 720x310px (proporção 2.3:1)          ║
/// ║       Formato: PNG ou JPG · até ~200KB cada                      ║
/// ║                                                                  ║
/// ║ 2. CRIATIVO DE TEXTO + ÍCONE (caso atual, sem imagem):           ║
/// ║                                                                  ║
/// ║    Use o construtor padrão _BannerSlide(...) com title,          ║
/// ║    subtitle, icon, cores, actionLabel.                           ║
/// ║                                                                  ║
/// ║ Os indicadores embaixo ajustam automaticamente ao número de      ║
/// ║ slides na lista.                                                 ║
/// ╚══════════════════════════════════════════════════════════════════╝
class HomeBanner extends ConsumerStatefulWidget {
  const HomeBanner({super.key});

  @override
  ConsumerState<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends ConsumerState<HomeBanner> {
  final PageController _controller = PageController();
  Timer? _autoTimer;
  int _current = 0;

  static const Duration _autoInterval = Duration(seconds: 5);
  static const Duration _animDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _scheduleAutoAdvance();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(_autoInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final int slidesCount = _slides(context, ref).length;
      final int next = (_current + 1) % slidesCount;
      _controller.animateToPage(
        next,
        duration: _animDuration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _restartTimer() {
    _scheduleAutoAdvance();
  }

  /// Lista dos criativos do banner.
  ///
  /// EDITE AQUI para trocar/adicionar criativos. Veja o cabeçalho da
  /// classe [HomeBanner] para instruções detalhadas.
  List<_BannerSlide> _slides(BuildContext context, WidgetRef ref) {
    return <_BannerSlide>[
      // ─── Criativo 1 ─────────────────────────────────────────────
      _BannerSlide.image(
        imageAsset: 'assets/images/banners/banner_1.png',
        onTap: () => context.push(AppRoutes.profileEdit),
      ),

      // ─── Criativo 2 ─────────────────────────────────────────────
      _BannerSlide.image(
        imageAsset: 'assets/images/banners/banner_2.png',
        onTap: () => ref.read(tabIndexProvider.notifier).state = 4, // aba Mais
      ),

      // ─── Criativo 3 ─────────────────────────────────────────────
      _BannerSlide.image(
        imageAsset: 'assets/images/banners/banner_3.png',
        onTap: () => ref.read(tabIndexProvider.notifier).state = 1, // aba Aula
      ),

      // ─── EXEMPLOS de fallback texto+ícone (descomente para usar) ──
      // _BannerSlide(
      //   title: 'Sua CNH começa\naqui!',
      //   subtitle: 'Aulas completas com você',
      //   icon: PhosphorIconsDuotone.steeringWheel,
      //   backgroundColor: AppColors.textPrimary,
      //   titleColor: AppColors.primary,
      //   subtitleColor: AppColors.surface,
      //   iconBackground: AppColors.primary,
      //   iconColor: AppColors.textPrimary,
      //   actionLabel: 'Configurar aula',
      //   onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
      // ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<_BannerSlide> slides = _slides(context, ref);

    return Column(
      children: <Widget>[
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (int i) {
              setState(() => _current = i);
              _restartTimer();
            },
            itemBuilder: (BuildContext c, int i) =>
                _SlideCard(slide: slides[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(
            slides.length,
            (int i) => AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _current ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _current
                    ? AppColors.textPrimary
                    : AppColors.textPrimary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Modelo de um slide do banner. Pode ser de dois tipos:
///
/// - **Texto + ícone** (construtor padrão): renderiza tipograficamente.
/// - **Imagem** (construtor [_BannerSlide.image]): renderiza o asset
///   fornecido como background full-bleed, sem texto sobreposto.
class _BannerSlide {
  /// Slide tipo "texto + ícone" — gerado por código.
  const _BannerSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.iconBackground,
    required this.iconColor,
    required this.actionLabel,
    required this.onTap,
  }) : imageAsset = null;

  /// Slide tipo "imagem" — usa um asset PNG/JPG como background.
  /// Recomendado: 720x310px, ~200KB máx.
  const _BannerSlide.image({
    required String this.imageAsset,
    required this.onTap,
  })  : title = '',
        subtitle = '',
        icon = PhosphorIconsRegular.circle,
        backgroundColor = AppColors.surface,
        titleColor = AppColors.textPrimary,
        subtitleColor = AppColors.textPrimary,
        iconBackground = AppColors.textPrimary,
        iconColor = AppColors.primary,
        actionLabel = '';

  final String? imageAsset;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color iconBackground;
  final Color iconColor;
  final String actionLabel;
  final VoidCallback onTap;

  bool get isImage => imageAsset != null;
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});
  final _BannerSlide slide;

  @override
  Widget build(BuildContext context) {
    if (slide.isImage) {
      return _ImageSlide(slide: slide);
    }
    return _TextIconSlide(slide: slide);
  }
}

/// Slide de imagem — asset PNG/JPG ocupa todo o card como background.
class _ImageSlide extends StatelessWidget {
  const _ImageSlide({required this.slide});
  final _BannerSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: slide.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                slide.imageAsset!,
                fit: BoxFit.cover,
                errorBuilder:
                    (BuildContext c, Object e, StackTrace? s) => Container(
                  color: AppColors.surfaceOverlay,
                  alignment: Alignment.center,
                  child: const Icon(
                    PhosphorIconsRegular.imageBroken,
                    color: AppColors.textMuted,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slide de texto + ícone (criativo gerado por código).
class _TextIconSlide extends StatelessWidget {
  const _TextIconSlide({required this.slide});
  final _BannerSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: slide.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: slide.onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        slide.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: slide.subtitleColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        slide.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: slide.titleColor,
                          height: 1.05,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: slide.titleColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: slide.titleColor.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              slide.actionLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: slide.titleColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              PhosphorIconsRegular.arrowRight,
                              size: 11,
                              color: slide.titleColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: slide.iconBackground,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    slide.icon,
                    size: 48,
                    color: slide.iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
