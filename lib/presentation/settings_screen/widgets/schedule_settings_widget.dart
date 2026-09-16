import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScheduleSettingsWidget extends StatelessWidget {
  final List<bool> workDays;
  final void Function(int index, bool value) onChanged;

  const ScheduleSettingsWidget({
    super.key,
    required this.workDays,
    required this.onChanged,
  });

  static const List<String> _dayNames = [
    'ორშაბათი',
    'სამშაბათი',
    'ოთხშაბათი',
    'ხუთშაბათი',
    'პარასკევი',
    'შაბათი',
    'კვირა',
  ];

  static const List<String> _dayShort = [
    'ორშ',
    'სამ',
    'ოთხ',
    'ხუთ',
    'პარ',
    'შაბ',
    'კვი',
  ];

  @override
  Widget build(BuildContext context) {
    final activeDays = workDays.where((d) => d).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E2028)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'სამუშაო გრაფიკი',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFAFAFA),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withAlpha(40),
                  ),
                ),
                child: Text(
                  '$activeDays დღე/კვირა',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'შეხსენება გამოჩნდება მონიშნულ დღეებში',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          // Quick toggle pill row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final active = workDays[i];
              return GestureDetector(
                onTap: () => onChanged(i, !active),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF10B981).withAlpha(25)
                        : const Color(0xFF16181C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF10B981).withAlpha(80)
                          : const Color(0xFF1E2028),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _dayShort[i].substring(0, 1),
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? const Color(0xFF10B981)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          // Full day list
          ...List.generate(7, (i) {
            final active = workDays[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      _dayShort[i],
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? const Color(0xFF10B981)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  Text(
                    _dayNames[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: active
                          ? const Color(0xFFFAFAFA)
                          : const Color(0xFF6B7280),
                      fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: active,
                    onChanged: (v) => onChanged(i, v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF10B981),
                    inactiveThumbColor: const Color(0xFF4B5563),
                    inactiveTrackColor: const Color(0xFF1C1E24),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
