import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'tabs/tab_financial.dart';
import 'tabs/tab_lesson.dart';
import 'tabs/tab_more.dart';
import 'tabs/tab_requests.dart';
import 'tabs/tab_schedule.dart';

/// Casca do app pós-login: bottom nav **flutuante e animada** com 5 abas.
///
/// Visual inspirado em apps modernos: barra preta arredondada flutuando
/// acima do fundo amarelo, com indicador circular amarelo que "salta"
/// para o item ativo com animação suave.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _index = widget.initialTab;

  static const List<_TabInfo> _tabs = <_TabInfo>[
    _TabInfo('Aula',          Icons.school_outlined,           Icons.school_rounded),
    _TabInfo('Solicitações',  Icons.notifications_none_rounded, Icons.notifications_rounded),
    _TabInfo('Agenda',        Icons.calendar_today_outlined,   Icons.calendar_today_rounded),
    _TabInfo('Financeiro',    Icons.attach_money_rounded,      Icons.attach_money_rounded),
    _TabInfo('Mais',          Icons.more_horiz_rounded,        Icons.more_horiz_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          TabLesson(),
          TabRequests(),
          TabSchedule(),
          TabFinancial(),
          TabMore(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _FloatingNavBar(
            tabs: _tabs,
            currentIndex: _index,
            onTap: (int i) => setState(() => _index = i),
          ),
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
                  // Indicador circular amarelo (cresce quando ativo)
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
                  // Ícone (escala sutil + troca cor quando ativo)
                  AnimatedScale(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    scale: selected ? 1.15 : 1.0,
                    child: Icon(
                      selected ? tab.selectedIcon : tab.icon,
                      color: selected ? AppColors.textPrimary : Colors.white,
                      size: 22,
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
