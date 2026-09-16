import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/work_data_service.dart';
import './widgets/calendar_grid_widget.dart';
import './widgets/calendar_legend_widget.dart';
import './widgets/day_detail_sheet_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  final WorkDataService _service = WorkDataService();

  bool _loading = true;
  DateTime _displayMonth = DateTime.now();
  List<WorkDay> _allWorkDays = [];
  AppSettings _settings = AppSettings();

  late AnimationController _monthCtrl;
  late Animation<double> _monthFade;

  @override
  void initState() {
    super.initState();
    _monthCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );
    _monthFade = CurvedAnimation(
      parent: _monthCtrl,
      curve: Curves.easeOutCubic,
    );
    _loadData();
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final days = await _service.loadWorkDays();
    final settings = await _service.loadSettings();
    setState(() {
      _allWorkDays = days;
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _changeMonth(int delta) async {
    await _monthCtrl.reverse();
    setState(() {
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month + delta,
        1,
      );
    });
    _monthCtrl.forward();
  }

  void _onDayTap(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    WorkDay? wd;
    for (final d in _allWorkDays) {
      final dOnly = DateTime(d.date.year, d.date.month, d.date.day);
      if (dOnly == dateOnly) {
        wd = d;
        break;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DayDetailSheetWidget(
        date: date,
        workDay: wd,
        dailyWage: _settings.dailyWage,
        onConfirm: (worked) async {
          Navigator.pop(context);
          await _service.recordWorkDay(date, worked, _settings.dailyWage);
          await _loadData();
        },
      ),
    );
  }

  Map<String, int> _getMonthStats() {
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final lastDay = DateTime(_displayMonth.year, _displayMonth.month + 1, 0);
    int worked = 0;
    int notWorked = 0;
    double earned = 0;
    for (final wd in _allWorkDays) {
      final d = DateTime(wd.date.year, wd.date.month, wd.date.day);
      if (!d.isBefore(firstDay) && !d.isAfter(lastDay)) {
        if (wd.worked) {
          worked++;
          earned += wd.wageEarned;
        } else {
          notWorked++;
        }
      }
    }
    return {'worked': worked, 'notWorked': notWorked, 'earned': earned.round()};
  }

  static const List<String> _geoMonthNames = [
    'იანვარი',
    'თებერვალი',
    'მარტი',
    'აპრილი',
    'მაისი',
    'ივნისი',
    'ივლისი',
    'აგვისტო',
    'სექტემბერი',
    'ოქტომბერი',
    'ნოემბერი',
    'დეკემბერი',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF10B981),
                      ),
                    )
                  : _buildContent(),
            ),
          ],
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
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'კალენდარი',
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFAFAFA),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'სამუშაო ისტორია',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final stats = _getMonthStats();
    final isCurrentMonth =
        _displayMonth.year == DateTime.now().year &&
        _displayMonth.month == DateTime.now().month;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF10B981),
      backgroundColor: const Color(0xFF16181C),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        child: Column(
          children: [
            _buildMonthNav(),
            const SizedBox(height: 14),
            _buildMonthStats(stats, isCurrentMonth),
            const SizedBox(height: 14),
            FadeTransition(
              opacity: _monthFade,
              child: CalendarGridWidget(
                displayMonth: _displayMonth,
                workDays: _allWorkDays,
                workSchedule: _settings.workDays,
                onDayTap: _onDayTap,
              ),
            ),
            const SizedBox(height: 14),
            const CalendarLegendWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E2028)),
      ),
      child: Row(
        children: [
          _NavButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => _changeMonth(-1),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${_geoMonthNames[_displayMonth.month - 1]} ${_displayMonth.year}',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFAFAFA),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            onTap: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStats(Map<String, int> stats, bool isCurrentMonth) {
    return Row(
      children: [
        Expanded(
          child: _MonthStatCard(
            label: 'ნამუშევარი',
            value: '${stats['worked']}',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MonthStatCard(
            label: 'დასვენება',
            value: '${stats['notWorked']}',
            color: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MonthStatCard(
            label: 'გამომუშ.',
            value: '₾${stats['earned']}',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF16181C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E2028)),
        ),
        child: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      ),
    );
  }
}

class _MonthStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MonthStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(35)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: color.withAlpha(180),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
