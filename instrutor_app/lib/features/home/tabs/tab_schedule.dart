import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/profile.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/mock/_seed.dart';
import '../../../shared/widgets/widgets.dart';

/// Aba AGENDA — calendário de aulas confirmadas.
class TabSchedule extends ConsumerStatefulWidget {
  const TabSchedule({super.key});

  @override
  ConsumerState<TabSchedule> createState() => _TabScheduleState();
}

class _TabScheduleState extends ConsumerState<TabSchedule> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final String userId =
        ref.read(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;
    final AsyncValue<List<Booking>> async =
        ref.watch(_confirmedProvider(userId));

    return CnhhjScaffold(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TabHeader(
            title: 'Sua agenda',
            subtitle: async.value == null
                ? null
                : '${async.value!.where((Booking b) => b.status == BookingStatus.confirmed).length} '
                    'aula(s) confirmada(s)',
          ),
          const SizedBox(height: 14),
          Expanded(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              ),
              error: (Object err, _) => Center(child: Text('Erro: $err')),
              data: (List<Booking> bookings) {
                final Map<DateTime, List<Booking>> byDay =
                    _groupByDay(bookings);
                final DateTime keyDay = _selected ?? _focused;
                final DateTime normalized =
                    DateTime(keyDay.year, keyDay.month, keyDay.day);
                final List<Booking> dayItems =
                    byDay[normalized] ?? const <Booking>[];

                return Column(
                  children: <Widget>[
                    CnhhjCard(
                      padding: const EdgeInsets.all(8),
                      border: Border.all(
                        color: AppColors.textPrimary,
                        width: 1.5,
                      ),
                      child: TableCalendar<Booking>(
                        locale: 'pt_BR',
                        firstDay: DateTime.utc(2024, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focused,
                        selectedDayPredicate: (DateTime d) =>
                            _selected != null && isSameDay(_selected, d),
                        eventLoader: (DateTime d) =>
                            byDay[DateTime(d.year, d.month, d.day)] ??
                            const <Booking>[],
                        onDaySelected: (DateTime sel, DateTime focused) {
                          setState(() {
                            _selected = sel;
                            _focused = focused;
                          });
                        },
                        calendarStyle: const CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: AppColors.primaryLighter,
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle:
                              TextStyle(color: AppColors.textPrimary),
                          selectedDecoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle:
                              TextStyle(color: AppColors.surface),
                          markerDecoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: dayItems.isEmpty
                          ? const CnhhjEmptyState(
                              icon: PhosphorIconsDuotone.calendarBlank,
                              message: 'Sem aulas neste dia.',
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: dayItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (BuildContext c, int i) =>
                                  _BookingTile(booking: dayItems[i]),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<Booking>> _groupByDay(List<Booking> all) {
    final Map<DateTime, List<Booking>> map = <DateTime, List<Booking>>{};
    for (final Booking b in all) {
      if (b.status != BookingStatus.confirmed &&
          b.status != BookingStatus.completed) {
        continue;
      }
      final DateTime key = DateTime(
        b.scheduledStart.year,
        b.scheduledStart.month,
        b.scheduledStart.day,
      );
      map.putIfAbsent(key, () => <Booking>[]).add(b);
    }
    return map;
  }
}

final FutureProviderFamily<List<Booking>, String> _confirmedProvider =
    FutureProvider.family<List<Booking>, String>((Ref ref, String userId) {
  return ref.watch(bookingRepositoryProvider).listForInstructor(userId);
});

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final Profile? student = MockState.instance.profiles[booking.studentId];
    final DateFormat hf = DateFormat('HH:mm');
    return CnhhjCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: booking.status == BookingStatus.completed
                  ? AppColors.success
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${hf.format(booking.scheduledStart)} — ${hf.format(booking.scheduledEnd)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  student?.fullName ?? 'Aluno',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CnhhjBadge.status(
            label: booking.status.label,
            kind: booking.status == BookingStatus.completed
                ? BadgeKind.success
                : BadgeKind.neutral,
          ),
        ],
      ),
    );
  }
}
