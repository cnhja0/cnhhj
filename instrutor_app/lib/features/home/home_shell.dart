import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'tabs/tab_financial.dart';
import 'tabs/tab_lesson.dart';
import 'tabs/tab_more.dart';
import 'tabs/tab_requests.dart';
import 'tabs/tab_schedule.dart';

/// Casca do app pós-login: bottom nav com 5 abas (AULA, SOLICITAÇÕES,
/// AGENDA, FINANCEIRO, MAIS). Cada aba é uma sub-tela independente.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _index = widget.initialTab;

  static const List<_TabInfo> _tabs = <_TabInfo>[
    _TabInfo('AULA',         Icons.school_outlined,           Icons.school),
    _TabInfo('SOLICITAÇÕES', Icons.notifications_none,        Icons.notifications),
    _TabInfo('AGENDA',       Icons.calendar_today_outlined,   Icons.calendar_today),
    _TabInfo('FINANCEIRO',   Icons.attach_money_outlined,     Icons.attach_money),
    _TabInfo('MAIS',         Icons.more_horiz_outlined,       Icons.more_horiz),
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
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: List<Widget>.generate(_tabs.length, (int i) {
              final _TabInfo tab = _tabs[i];
              final bool selected = i == _index;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _index = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          selected ? tab.selectedIcon : tab.icon,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
