import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum WorkStatus { worked, notWorked, scheduled, pending }

class StatusBadgeWidget extends StatelessWidget {
  final WorkStatus status;
  final bool compact;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.color.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withAlpha(77), width: 1),
      ),
      child: Text(
        config.label,
        style: GoogleFonts.ibmPlexSans(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: config.color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  _BadgeConfig _getConfig() {
    switch (status) {
      case WorkStatus.worked:
        return _BadgeConfig(const Color(0xFF10B981), 'Worked');
      case WorkStatus.notWorked:
        return _BadgeConfig(const Color(0xFFEF4444), 'Not Worked');
      case WorkStatus.scheduled:
        return _BadgeConfig(const Color(0xFFF59E0B), 'Scheduled');
      case WorkStatus.pending:
        return _BadgeConfig(const Color(0xFF6B7280), 'Pending');
    }
  }
}

class _BadgeConfig {
  final Color color;
  final String label;
  const _BadgeConfig(this.color, this.label);
}
