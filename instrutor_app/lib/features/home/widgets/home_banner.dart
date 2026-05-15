import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../home_state.dart';

/// Banner rotativo no topo da Home — 3 criativos que se alternam a cada 5s
/// com indicadores (dots) abaixo. Suporta swipe manual e tap em cada slide.
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

  List<_BannerSlide> _slides(BuildContext context, WidgetRef ref) {
    return <_BannerSlide>[
      _BannerSlide(
        title: 'Sua CNH começa\naqui!',
        subtitle: 'Aulas completas com você',
        icon: PhosphorIconsDuotone.steeringWheel,
        backgroundColor: AppColors.textPrimary,
        titleColor: AppColors.primary,
        subtitleColor: AppColors.surface,
        iconBackground: AppColors.primary,
        iconColor: AppColors.textPrimary,
        actionLabel: 'Configurar aula',
        onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
      ),
      _BannerSlide(
        title: 'Receba mais\nsolicitações',
        subtitle: 'Mantenha sua agenda atualizada',
        icon: PhosphorIconsDuotone.calendarDots,
        backgroundColor: AppColors.success,
        titleColor: AppColors.surface,
        subtitleColor: AppColors.surface,
        iconBackground: AppColors.surface,
        iconColor: AppColors.success,
        actionLabel: 'Ver agenda',
        onTap: () => ref.read(tabIndexProvider.notifier).state = 3,
      ),
      _BannerSlide(
        title: 'Complete seu\nperfil',
        subtitle: 'Foto e bio aumentam visibilidade',
        icon: PhosphorIconsDuotone.userCircle,
        backgroundColor: AppColors.primaryLight,
        titleColor: AppColors.textPrimary,
        subtitleColor: AppColors.textSecondary,
        iconBackground: AppColors.textPrimary,
        iconColor: AppColors.primary,
        actionLabel: 'Editar perfil',
        onTap: () => context.push(AppRoutes.profileEdit),
      ),
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

class _BannerSlide {
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
  });

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
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});
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
