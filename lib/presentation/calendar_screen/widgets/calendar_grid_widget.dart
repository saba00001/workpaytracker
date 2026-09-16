import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/work_data_service.dart';

class CalendarGridWidget extends StatelessWidget {
  final DateTime displayMonth;
  final List<WorkDay> workDays;
  final List<bool> workSchedule;
  final void Function(DateTime) onDayTap;

  const CalendarGridWidget({
    super.key,
    required this.displayMonth,
    required this.workDays,
    required this.workSchedule,
    required this.onDayTap,
  });

  static const List<String> _dayLabels = ['ო', 'ს', 'ო', 'ხ', 'პ', 'შ', 'კ'];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth = DateTime(
      displayMonth.year,
      displayMonth.month + 1,
      0,
    ).day;
    final startOffset = firstDay.weekday - 1;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final wdMap = <DateTime, WorkDay>{};
    for (final wd in workDays) {
      final k = DateTime(wd.date.year, wd.date.month, wd.date.day);
      wdMap[k] = wd;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2028)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Day labels row
          Row(
            children: List.generate(7, (i) {
              final isWeekend = i >= 5;
              return Expanded(
                child: Center(
                  child: Text(
                    _dayLabels[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isWeekend
                          ? const Color(0xFF4B5563)
                          : const Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, index) {
              if (index < startOffset) return const SizedBox.shrink();

              final day = index - startOffset + 1;
              final date = DateTime(displayMonth.year, displayMonth.month, day);
              final dateOnly = DateTime(date.year, date.month, date.day);
              final isToday = dateOnly == todayOnly;
              final isFuture = dateOnly.isAfter(todayOnly);
              final wd = wdMap[dateOnly];

              final dow = date.weekday - 1;
              final isScheduled = workSchedule[dow];

              Color bgColor = Colors.transparent;
              Color textColor = const Color(0xFF6B7280);
              Color? borderColor;
              bool isWorked = false;

              if (wd != null) {
                if (wd.worked) {
                  bgColor = const Color(0xFF10B981).withAlpha(30);
                  textColor = const Color(0xFF10B981);
                  borderColor = const Color(0xFF10B981).withAlpha(80);
                  isWorked = true;
                } else {
                  bgColor = const Color(0xFFEF4444).withAlpha(20);
                  textColor = const Color(0xFFEF4444).withAlpha(180);
                  borderColor = const Color(0xFFEF4444).withAlpha(50);
                }
              } else if (isFuture && isScheduled) {
                bgColor = const Color(0xFFF59E0B).withAlpha(15);
                textColor = const Color(0xFFF59E0B).withAlpha(180);
                borderColor = const Color(0xFFF59E0B).withAlpha(40);
              } else if (isFuture) {
                textColor = const Color(0xFF374151);
              } else {
                // Past unconfirmed
                textColor = const Color(0xFF374151);
              }

              if (isToday) {
                if (wd == null) {
                  bgColor = Colors.white.withAlpha(12);
                  textColor = const Color(0xFFFAFAFA);
                }
                borderColor = const Color(0xFFFAFAFA).withAlpha(200);
              }

              return GestureDetector(
                onTap: () => onDayTap(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: isToday ? 2 : 1)
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$day',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: isToday
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        if (isWorked) ...[
                          const SizedBox(height: 1),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
