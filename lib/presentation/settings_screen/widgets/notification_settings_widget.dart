import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../../../services/notification_service.dart';

class NotificationSettingsWidget extends StatefulWidget {
  final int reminderHour;
  final int reminderMinute;
  final bool notificationsEnabled;
  final void Function(int hour, int minute) onTimeChanged;
  final void Function(bool) onToggle;

  const NotificationSettingsWidget({
    super.key,
    required this.reminderHour,
    required this.reminderMinute,
    required this.notificationsEnabled,
    required this.onTimeChanged,
    required this.onToggle,
  });

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  bool _fullScreenGranted = false;

  @override
  void initState() {
    super.initState();
    _checkFullScreenPermission();
  }

  Future<void> _checkFullScreenPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final granted = await NotificationService()
          .checkFullScreenIntentPermission();
      if (mounted) setState(() => _fullScreenGranted = granted);
    } catch (_) {}
  }

  String _formatTime(int h, int m) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: widget.reminderHour,
        minute: widget.reminderMinute,
      ),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Color(0xFF16181C),
              onSurface: Color(0xFFFAFAFA),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF111214),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.onTimeChanged(picked.hour, picked.minute);
    }
  }

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
          Row(
            children: [
              Text(
                'შეხსენებები',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFAFAFA),
                ),
              ),
              const Spacer(),
              Switch(
                value: widget.notificationsEnabled,
                onChanged: widget.onToggle,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF10B981),
                inactiveThumbColor: const Color(0xFF4B5563),
                inactiveTrackColor: const Color(0xFF1C1E24),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '"იმუშავე დღეს?" — შეხსენება მითითებულ დროს',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: widget.notificationsEnabled
                ? () => _pickTime(context)
                : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: widget.notificationsEnabled ? 1.0 : 0.4,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16181C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.notificationsEnabled
                        ? const Color(0xFF10B981).withAlpha(50)
                        : const Color(0xFF1E2028),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'შეხსენების დრო',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(
                              widget.reminderHour,
                              widget.reminderMinute,
                            ),
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFAFAFA),
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withAlpha(40),
                        ),
                      ),
                      child: Text(
                        'შეცვლა',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.notificationsEnabled) ...[
            const SizedBox(height: 12),
            // Full-screen intent status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _fullScreenGranted
                    ? const Color(0xFF10B981).withAlpha(8)
                    : const Color(0xFFF59E0B).withAlpha(8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _fullScreenGranted
                      ? const Color(0xFF10B981).withAlpha(25)
                      : const Color(0xFFF59E0B).withAlpha(25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _fullScreenGranted
                        ? Icons.fullscreen_rounded
                        : Icons.fullscreen_exit_rounded,
                    color: _fullScreenGranted
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'მთლიან ეკრანზე ჩვენება',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _fullScreenGranted
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fullScreenGranted
                              ? 'ნებადართულია — შეხსენება სრულ ეკრანზე გამოჩნდება'
                              : 'საჭიროებს ნებართვას — Android-ის პარამეტრებში ჩართეთ "სრული ეკრანის შეტყობინებები"',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
