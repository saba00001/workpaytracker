import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarLegendWidget extends StatelessWidget {
  const CalendarLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2028)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem(color: const Color(0xFF10B981), label: 'ნამუშევარია'),
          _LegendItem(color: const Color(0xFFEF4444), label: 'არ მიმუშავია'),
          _LegendItem(color: const Color(0xFFF59E0B), label: 'დაგეგმილი'),
          _LegendItem(
            color: const Color(0xFFFAFAFA),
            label: 'დღეს',
            isOutline: true,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isOutline;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : color.withAlpha(200),
            shape: BoxShape.circle,
            border: isOutline ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
