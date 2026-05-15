import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import 'home_state.dart';
import 'tabs/tab_home.dart';
import 'tabs/tab_lesson.dart';
import 'tabs/tab_more.dart';
import 'tabs/tab_requests.dart';
import 'tabs/tab_schedule.dart';

/// Casca do app pós-login: bottom nav **flutuante e animada** com 5 abas.
///
/// Ordem: Home · Aula · Solicitações · Agenda · Mais.
/// Ícones: Phosphor (linha quando inativo, fill quando ativo).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  /// Aba inicial. As rotas /home/aula, /home/solicitacoes, etc. apontam
  /// para cá com o índice correspondente.
  final int initialTab;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tabIndexProvider.notifier).state = widget.initialTab;
    });
  }

  static const List<_TabInfo> _tabs = <_TabInfo>[
    _TabInfo('Home',         PhosphorIconsRegular.house,         PhosphorIconsFill.house),
    _TabInfo('Aula',         PhosphorIconsRegular.steeringWheel, PhosphorIconsFill.steeringWheel),
    _TabInfo('Solicitações', PhosphorIconsRegular.tray,          PhosphorIconsFill.tray),
    _TabInfo('Agenda',       PhosphorIconsRegular.calendarDots,  PhosphorIconsFill.calendarDots),
    _TabInfo('Mais',         PhosphorIconsRegular.dotsThree,     PhosphorIconsFill.dotsThree),
  ];

  @override
  Widget build(BuildContext context) {
    final int index = ref.watch(tabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _IndexedStackFade(
        index: index,
        children: const <Widget>[
          TabHome(),
          TabLesson(),
          TabRequests(),
          TabSchedule(),
          TabMore(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _FloatingNavBar(
            tabs: _tabs,
            currentIndex: index,
            onTap: (int i) =>
                ref.read(tabIndexProvider.notifier).state = i,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
        ),
      ),
    );
  }
}

class _TabInfo {
  const _TabInfo(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Versão animada do IndexedStack: mantém todos os filhos vivos (estado
/// preservado por aba) e usa AnimatedOpacity para suavizar a transição
/// entre eles. TickerMode desliga animações dos filhos inativos por perf.
class _IndexedStackFade extends StatelessWidget {
  const _IndexedStackFade({
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 220),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List<Widget>.generate(children.length, (int i) {
        final bool active = i == index;
        return IgnorePointer(
          ignoring: !active,
          child: AnimatedOpacity(
            duration: duration,
            curve: Curves.easeInOut,
            opacity: active ? 1.0 : 0.0,
            child: TickerMode(
              enabled: active,
              child: children[i],
            ),
          ),
        );
      }),
    );
  }
}

/// Barra de navegação flutuante preta com indicador circular amarelo
/// animado sobre o item selecionado.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_TabInfo> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List<Widget>.generate(tabs.length, (int i) {
          final _TabInfo tab = tabs[i];
          final bool selected = i == currentIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              borderRadius: BorderRadius.circular(34),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    width: selected ? 46 : 0,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    scale: selected ? 1.12 : 1.0,
                    child: Icon(
                      selected ? tab.selectedIcon : tab.icon,
                      color: selected ? AppColors.textPrimary : Colors.white,
                      size: 24,
                      semanticLabel: tab.label,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
