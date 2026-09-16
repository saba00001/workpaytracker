import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/work_data_service.dart';

class EarningsSparklineWidget extends StatelessWidget {
  final List<WorkDay> periodDays;

  const EarningsSparklineWidget({super.key, required this.periodDays});

  @override
  Widget build(BuildContext context) {
    if (periodDays.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Period Activity',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              periodDays.length > 20 ? 20 : periodDays.length,
              (i) {
                final idx = periodDays.length > 20
                    ? periodDays.length - 20 + i
                    : i;
                final day = periodDays[idx];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300 + i * 30),
                      curve: Curves.easeOutCubic,
                      height: day.worked ? 28 : 10,
                      decoration: BoxDecoration(
                        color: day.worked
                            ? const Color(0xFF10B981).withAlpha(180)
                            : const Color(0xFFEF4444).withAlpha(80),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
