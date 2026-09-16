import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class KpiCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final String iconName;
  final Color iconColor;
  final int delay;

  const KpiCardWidget({
    super.key,
    required this.label,
    required this.value,
    required this.iconName,
    required this.iconColor,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E2028)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconData(iconName), color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFAFAFA),
              letterSpacing: -0.3,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'event_available_rounded':
        return Icons.event_available_rounded;
      case 'attach_money':
        return Icons.payments_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      default:
        return Icons.circle;
    }
  }
}
