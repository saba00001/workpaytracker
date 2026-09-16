import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TodayConfirmWidget extends StatelessWidget {
  final bool? todayStatus;
  final Future<void> Function(bool) onConfirm;
  final VoidCallback? onExpand;

  const TodayConfirmWidget({
    super.key,
    required this.todayStatus,
    required this.onConfirm,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const geoWeekdays = ['', 'ორშ', 'სამ', 'ოთხ', 'ხუთ', 'პარ', 'შაბ', 'კვი'];
    const geoMonths = [
      '',
      'იანვ',
      'თებ',
      'მარ',
      'აპრ',
      'მაი',
      'ივნ',
      'ივლ',
      'აგვ',
      'სექ',
      'ოქტ',
      'ნოე',
      'დეკ',
    ];
    final dateStr =
        '${geoWeekdays[now.weekday]}, ${now.day} ${geoMonths[now.month]}';

    final borderColor = todayStatus == null
        ? const Color(0xFF1E2028)
        : todayStatus == true
        ? const Color(0xFF10B981).withAlpha(80)
        : const Color(0xFFEF4444).withAlpha(80);

    final bgColor = todayStatus == null
        ? const Color(0xFF111214)
        : todayStatus == true
        ? const Color(0xFF10B981).withAlpha(12)
        : const Color(0xFFEF4444).withAlpha(12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.today_rounded,
                color: Color(0xFF6B7280),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (onExpand != null)
                GestureDetector(
                  onTap: onExpand,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16181C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E2028)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.open_in_full_rounded,
                          size: 11,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'სრული ეკრანი',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (todayStatus == null) ...[
            Text(
              'იმუშავე დღეს?',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFAFAFA),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ConfirmButton(
                    label: 'დიახ, ვიმუშავე',
                    color: const Color(0xFF10B981),
                    icon: Icons.check_circle_rounded,
                    onTap: () => onConfirm(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ConfirmButton(
                    label: 'არა, არ მიმუშავია',
                    color: const Color(0xFFEF4444),
                    icon: Icons.cancel_rounded,
                    onTap: () => onConfirm(false),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        (todayStatus == true
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                            .withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    todayStatus == true
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: todayStatus == true
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todayStatus == true ? 'ნამუშევარია ✓' : 'არ მიმუშავია',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: todayStatus == true
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      Text(
                        'შეცვლა',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onExpand,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16181C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E2028)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          size: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'შეცვლა',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatefulWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ConfirmButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: widget.color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.color.withAlpha(60)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
