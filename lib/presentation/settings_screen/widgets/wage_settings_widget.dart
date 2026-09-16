import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class WageSettingsWidget extends StatefulWidget {
  final TextEditingController controller;

  const WageSettingsWidget({super.key, required this.controller});

  @override
  State<WageSettingsWidget> createState() => _WageSettingsWidgetState();
}

class _WageSettingsWidgetState extends State<WageSettingsWidget> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
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
          Text(
            'დღიური ანაზღაურება',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFAFAFA),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'თანხა, რომელიც ემატება ყოველ სამუშაო დღეს',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          Focus(
            onFocusChange: (f) => setState(() => _focused = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: const Color(0xFF16181C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focused
                      ? const Color(0xFF10B981)
                      : const Color(0xFF1E2028),
                  width: _focused ? 1.5 : 1,
                ),
              ),
              child: TextFormField(
                controller: widget.controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFAFAFA),
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  prefixText: '₾  ',
                  prefixStyle: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                  hintText: '80',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 20,
                    color: const Color(0xFF374151),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'შეიყვანეთ დღიური ანაზღაურება';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'შეიყვანეთ სწორი თანხა (0-ზე მეტი)';
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
