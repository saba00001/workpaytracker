import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PeriodInfoWidget extends StatelessWidget {
  final DateTime periodStart;
  final double lastPayment;
  final double lifetimeEarnings;

  const PeriodInfoWidget({
    super.key,
    required this.periodStart,
    required this.lastPayment,
    required this.lifetimeEarnings,
  });

  String _fmt(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2028)),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'Period started',
            value: _fmt(periodStart),
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFF6B7280),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFF1A1D23), height: 1),
          ),
          _InfoRow(
            label: 'Last payment',
            value: lastPayment > 0
                ? '₾${lastPayment.toStringAsFixed(0)}'
                : 'None yet',
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFF1A1D23), height: 1),
          ),
          _InfoRow(
            label: 'Lifetime earnings',
            value: '₾${lifetimeEarnings.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF10B981),
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(20),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight
                ? const Color(0xFF10B981)
                : const Color(0xFFFAFAFA),
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
