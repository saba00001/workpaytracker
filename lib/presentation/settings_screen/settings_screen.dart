import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/work_data_service.dart';
import '../../services/notification_service.dart';
import './widgets/notification_settings_widget.dart';
import './widgets/schedule_settings_widget.dart';
import './widgets/wage_settings_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final WorkDataService _service = WorkDataService();
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  late AppSettings _settings;
  late TextEditingController _wageController;

  @override
  void initState() {
    super.initState();
    _wageController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _wageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    final s = await _service.loadSettings();
    setState(() {
      _settings = s;
      _wageController.text = s.dailyWage.toStringAsFixed(0);
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    final wage = double.tryParse(_wageController.text.trim()) ?? 80.0;
    final updated = _settings.copyWith(dailyWage: wage);
    await _service.saveSettings(updated);

    if (updated.notificationsEnabled) {
      await NotificationService().requestPermission();
      await NotificationService().scheduleDailyNotification(
        hour: updated.reminderHour,
        minute: updated.reminderMinute,
      );
    } else {
      await NotificationService().cancelDailyNotification();
    }

    setState(() {
      _settings = updated;
      _saving = false;
    });

    Fluttertoast.showToast(
      msg: '✓ პარამეტრები შენახულია',
      backgroundColor: const Color(0xFF10B981),
      textColor: Colors.white,
      fontSize: 14,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onScheduleChanged(int index, bool value) {
    setState(() {
      final newDays = List<bool>.from(_settings.workDays);
      newDays[index] = value;
      _settings = _settings.copyWith(workDays: newDays);
    });
  }

  void _onReminderTimeChanged(int hour, int minute) {
    setState(() {
      _settings = _settings.copyWith(
        reminderHour: hour,
        reminderMinute: minute,
      );
    });
  }

  void _onNotificationsToggled(bool value) {
    setState(() {
      _settings = _settings.copyWith(notificationsEnabled: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              )
            : Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildSectionLabel('შემოსავალი'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: WageSettingsWidget(controller: _wageController),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildSectionLabel('სამუშაო დღეები'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: ScheduleSettingsWidget(
                          workDays: _settings.workDays,
                          onChanged: _onScheduleChanged,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildSectionLabel('შეტყობინებები'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: NotificationSettingsWidget(
                          reminderHour: _settings.reminderHour,
                          reminderMinute: _settings.reminderMinute,
                          notificationsEnabled: _settings.notificationsEnabled,
                          onTimeChanged: _onReminderTimeChanged,
                          onToggle: _onNotificationsToggled,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: _buildSaveButton(),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withAlpha(50),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'პარამეტრები',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFAFAFA),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'ტრეკერის კონფიგურაცია',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saving ? null : _saveSettings,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _saving
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _saving ? const Color(0xFF111214) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _saving
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF10B981).withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF10B981),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'შენახვა',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
