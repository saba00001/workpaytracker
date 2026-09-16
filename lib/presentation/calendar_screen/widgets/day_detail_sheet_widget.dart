import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/work_data_service.dart';

class DayDetailSheetWidget extends StatelessWidget {
  final DateTime date;
  final WorkDay? workDay;
  final double dailyWage;
  final Future<void> Function(bool) onConfirm;

  const DayDetailSheetWidget({
    super.key,
    required this.date,
    required this.workDay,
    required this.dailyWage,
    required this.onConfirm,
  });

  String _fmt(DateTime d) =>
      '${_weekday(d.weekday)}, ${d.day} ${_month(d.month)} ${d.year}';

  String _weekday(int w) => const [
    '',
    'ორშაბათი',
    'სამშაბათი',
    'ოთხშაბათი',
    'ხუთშაბათი',
    'პარასკევი',
    'შაბათი',
    'კვირა',
  ][w];

  String _month(int m) => const [
    '',
    'იანვარი',
    'თებერვალი',
    'მარტი',
    'აპრილი',
    'მაისი',
    'ივნისი',
    'ივლისი',
    'აგვისტო',
    'სექტემბერი',
    'ოქტომბერი',
    'ნოემბერი',
    'დეკემბერი',
  ][m];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final isFuture = dateOnly.isAfter(todayOnly);
    final isToday = dateOnly == todayOnly;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111214),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2D35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fmt(date),
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFAFAFA),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (isToday)
                            _chip('დღეს', const Color(0xFFFAFAFA))
                          else if (isFuture)
                            _chip('მომავალი', const Color(0xFFF59E0B))
                          else if (workDay == null)
                            _chip('დაუფიქსირებელი', const Color(0xFF6B7280))
                          else if (workDay!.worked)
                            _chip('ნამუშევარია ✓', const Color(0xFF10B981))
                          else
                            _chip('არ მიმუშავია', const Color(0xFFEF4444)),
                        ],
                      ),
                    ),
                    if (workDay != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: workDay!.worked
                              ? const Color(0xFF10B981).withAlpha(15)
                              : const Color(0xFFEF4444).withAlpha(10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: workDay!.worked
                                ? const Color(0xFF10B981).withAlpha(50)
                                : const Color(0xFFEF4444).withAlpha(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              workDay!.worked
                                  ? '₾${workDay!.wageEarned.toStringAsFixed(0)}'
                                  : '₾0',
                              style: GoogleFonts.dmSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: workDay!.worked
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF6B7280),
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Text(
                              'გამომუშ.',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!isFuture) ...[
                  if (workDay == null || isToday)
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'ნამუშევარია',
                            color: const Color(0xFF10B981),
                            icon: Icons.check_circle_rounded,
                            onTap: () => onConfirm(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'არ მიმუშავია',
                            color: const Color(0xFFEF4444),
                            icon: Icons.cancel_rounded,
                            onTap: () => onConfirm(false),
                          ),
                        ),
                      ],
                    )
                  else
                    _ActionButton(
                      label: workDay!.worked
                          ? 'დასვენებად მოინიშნება'
                          : 'ნამუშევრად მოინიშნება',
                      color: workDay!.worked
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      icon: workDay!.worked
                          ? Icons.cancel_rounded
                          : Icons.check_circle_rounded,
                      onTap: () => onConfirm(!workDay!.worked),
                    ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withAlpha(40),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFFF59E0B),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ეს დღე ჯერ არ დამდგარა',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
