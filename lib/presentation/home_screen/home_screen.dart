import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/work_data_service.dart';
import './widgets/earnings_sparkline_widget.dart';
import './widgets/today_confirm_widget.dart';
import './widgets/work_confirmation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final WorkDataService _service = WorkDataService();

  bool _loading = true;
  int _workedDays = 0;
  double _dailyWage = 80.0;
  double _currentEarnings = 0.0;
  double _totalReceived = 0.0;
  double _remaining = 0.0;
  double _lifetimeEarnings = 0.0;
  DateTime _periodStart = DateTime.now();
  DateTime _periodEnd = DateTime.now();
  List<WorkDay> _periodDays = [];
  bool? _todayStatus;
  MonthlyPeriod? _currentPeriod;
  double? _lastPaymentAmount;
  DateTime? _lastPaymentDate;

  // Monthly stats
  int _monthRestDays = 0;
  int _remainingScheduledDays = 0;
  double _forecastTotal = 0.0;

  // Weekly stats
  int _weekWorkedDays = 0;
  double _weekEarnings = 0.0;

  // Missed days awaiting confirmation
  List<DateTime> _missedDays = [];

  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _loadData();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final stats = await _service.getCurrentPeriodStats();
    final allDays = await _service.loadWorkDays();
    final settings = await _service.loadSettings();
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    WorkDay? todayRecord;
    for (final d in allDays) {
      final dOnly = DateTime(d.date.year, d.date.month, d.date.day);
      if (dOnly == todayOnly) {
        todayRecord = d;
        break;
      }
    }

    // Calculate rest days in current month
    final firstDay = DateTime(today.year, today.month, 1);
    final lastDay = DateTime(today.year, today.month + 1, 0);
    int workedCount = 0;
    int notWorkedCount = 0;
    for (final wd in allDays) {
      final d = DateTime(wd.date.year, wd.date.month, wd.date.day);
      if (!d.isBefore(firstDay) && !d.isAfter(lastDay)) {
        if (wd.worked) {
          workedCount++;
        } else {
          notWorkedCount++;
        }
      }
    }

    // Calculate remaining scheduled work days in current month
    final wdMap = <DateTime, WorkDay>{};
    for (final wd in allDays) {
      wdMap[DateTime(wd.date.year, wd.date.month, wd.date.day)] = wd;
    }
    int remainingScheduled = 0;
    for (int d = today.day + 1; d <= lastDay.day; d++) {
      final date = DateTime(today.year, today.month, d);
      final dow = date.weekday - 1;
      if (settings.workDays[dow]) {
        remainingScheduled++;
      }
    }

    // Forecast
    final currentEarned = stats['currentEarnings'] as double;
    final forecastAdditional = remainingScheduled * settings.dailyWage;
    final forecastTotal = currentEarned + forecastAdditional;

    // Weekly stats (Mon-Sun of current week)
    final weekStart = todayOnly.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    int weekWorked = 0;
    double weekEarned = 0;
    for (final wd in allDays) {
      final d = DateTime(wd.date.year, wd.date.month, wd.date.day);
      if (!d.isBefore(weekStart) && !d.isAfter(weekEnd) && wd.worked) {
        weekWorked++;
        weekEarned += wd.wageEarned;
      }
    }

    // Find missed days (past scheduled work days with no confirmation)
    final missedDays = <DateTime>[];
    final checkFrom = firstDay;
    for (int d = 0; d < todayOnly.difference(checkFrom).inDays; d++) {
      final date = checkFrom.add(Duration(days: d));
      final dow = date.weekday - 1;
      if (settings.workDays[dow] && !wdMap.containsKey(date)) {
        missedDays.add(date);
      }
    }
    // Limit to last 7 unresolved days to avoid overwhelming the user
    final recentMissed = missedDays.length > 7
        ? missedDays.sublist(missedDays.length - 7)
        : missedDays;

    setState(() {
      _workedDays = stats['workedDays'] as int;
      _dailyWage = stats['dailyWage'] as double;
      _currentEarnings = stats['currentEarnings'] as double;
      _totalReceived = stats['totalReceived'] as double;
      _remaining = stats['remaining'] as double;
      _periodStart = stats['periodStart'] as DateTime;
      _periodEnd = stats['periodEnd'] as DateTime;
      _lifetimeEarnings = stats['lifetimeEarnings'] as double;
      _periodDays = (stats['periodDays'] as List).cast<WorkDay>();
      _todayStatus = todayRecord?.worked;
      _currentPeriod = stats['currentPeriod'] as MonthlyPeriod?;
      _lastPaymentAmount = stats['lastPayment'] as double?;
      _lastPaymentDate = stats['lastPaymentDate'] as DateTime?;
      _monthRestDays = notWorkedCount;
      _remainingScheduledDays = remainingScheduled;
      _forecastTotal = forecastTotal;
      _weekWorkedDays = weekWorked;
      _weekEarnings = weekEarned;
      _missedDays = recentMissed;
      _loading = false;
    });
    _entranceController.forward(from: 0);

    // Show missed day resolution dialog after load if needed
    if (recentMissed.isNotEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMissedDayDialog();
      });
    }
  }

  void _showMissedDayDialog() {
    if (_missedDays.isEmpty || !mounted) return;
    final missed = _missedDays.first;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MissedDayDialog(
        date: missed,
        wage: _dailyWage,
        onConfirm: (worked) async {
          Navigator.of(ctx).pop();
          await _service.recordWorkDay(missed, worked, _dailyWage);
          await _loadData();
        },
        onSkip: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _confirmToday(bool worked) async {
    HapticFeedback.mediumImpact();
    final today = DateTime.now();
    await _service.recordWorkDay(today, worked, _dailyWage);
    await _loadData();
    if (mounted) {
      final msg = worked
          ? '✓ ნამუშევარია — ₾${_dailyWage.toStringAsFixed(0)} დაემატა'
          : 'დასვენების დღე დაფიქსირდა';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: worked
              ? const Color(0xFF10B981)
              : const Color(0xFF1C1E24),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openFullScreenConfirm() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            WorkConfirmationScreen(
              onConfirm: _confirmToday,
              currentStatus: _todayStatus,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Future<void> _onPaymentReceived() async {
    if (_currentEarnings <= 0) return;

    final result = await showDialog<double>(
      context: context,
      barrierColor: Colors.black.withAlpha(160),
      builder: (ctx) => _PartialPaymentDialog(
        totalEarned: _currentEarnings,
        alreadyReceived: _totalReceived,
        remaining: _remaining,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
        workedDays: _workedDays,
        wage: _dailyWage,
      ),
    );

    if (result != null && result > 0) {
      HapticFeedback.heavyImpact();
      final error = await _service.addPartialPayment(result);
      await _loadData();
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '₾${result.toStringAsFixed(0)} მიღებულია',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: SafeArea(
        child: _loading
            ? _buildSkeleton()
            : FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF10B981),
                    backgroundColor: const Color(0xFF16181C),
                    child: _buildContent(),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildEarningsHero()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _buildProgressBar(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _buildFinancialRow(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _buildStatsRow(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: TodayConfirmWidget(
              todayStatus: _todayStatus,
              onConfirm: _confirmToday,
              onExpand: _openFullScreenConfirm,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _buildMonthlyStats(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _buildWeeklyAndForecast(),
          ),
        ),
        if (_lastPaymentAmount != null && _lastPaymentAmount! > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _buildLastPaymentInfo(),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _buildPaymentButton(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
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
              Icons.work_rounded,
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
                  'ხელფასის მენეჯერი',
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFAFAFA),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  _formatPeriodRange(_periodStart, _periodEnd),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Missed days indicator (replaces duplicate settings button)
          if (_missedDays.isNotEmpty)
            GestureDetector(
              onTap: _showMissedDayDialog,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withAlpha(80),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.pending_actions_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_missedDays.length}',
                            style: GoogleFonts.dmSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _currentEarnings > 0
        ? (_totalReceived / _currentEarnings).clamp(0.0, 1.0)
        : 0.0;
    final isFullyPaid = _remaining == 0 && _currentEarnings > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFullyPaid
              ? const Color(0xFF10B981).withAlpha(60)
              : const Color(0xFF1E2028),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'გადახდის პროგრესი',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                isFullyPaid
                    ? 'სრულად მიღებულია ✓'
                    : '₾${_totalReceived.toStringAsFixed(0)} / ₾${_currentEarnings.toStringAsFixed(0)}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isFullyPaid
                      ? const Color(0xFF10B981)
                      : const Color(0xFFFAFAFA),
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: const Color(0xFF1E2028),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFullyPaid
                      ? const Color(0xFF10B981)
                      : const Color(0xFF10B981),
                ),
              ),
            ),
          ),
          if (!isFullyPaid && _remaining > 0) ...[
            const SizedBox(height: 8),
            Text(
              'დარჩენილია: ₾${_remaining.toStringAsFixed(0)}',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: const Color(0xFFF59E0B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningsHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF064E3B).withAlpha(180),
              const Color(0xFF0A0B0D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF10B981).withAlpha(50),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withAlpha(20),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF10B981).withAlpha(40),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'მიმდინარე პერიოდი',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'გამომუშავებული',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _currentEarnings),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => Text(
                      '₾${value.toStringAsFixed(0)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFAFAFA),
                        letterSpacing: -2,
                        height: 1,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_workedDays დღე × ₾${_dailyWage.toStringAsFixed(0)}/დღე',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  if (_periodDays.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    EarningsSparklineWidget(periodDays: _periodDays),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialRow() {
    return Row(
      children: [
        Expanded(
          child: _FinanceCard(
            label: 'მიღებული',
            value: '₾${_totalReceived.toStringAsFixed(0)}',
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFF10B981).withAlpha(20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FinanceCard(
            label: 'დარჩენილი',
            value: '₾${_remaining.toStringAsFixed(0)}',
            icon: Icons.hourglass_bottom_rounded,
            iconColor: _remaining > 0
                ? const Color(0xFFF59E0B)
                : const Color(0xFF6B7280),
            iconBg: _remaining > 0
                ? const Color(0xFFF59E0B).withAlpha(20)
                : const Color(0xFF6B7280).withAlpha(20),
            highlight: _remaining > 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'ნამუშევარი',
            value: _workedDays.toString(),
            icon: Icons.event_available_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFF10B981).withAlpha(20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'დღიური ანაზღ.',
            value: '₾${_dailyWage.toStringAsFixed(0)}',
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFF59E0B).withAlpha(20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'სულ მიღებული',
            value: '₾${_lifetimeEarnings.toStringAsFixed(0)}',
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF818CF8),
            iconBg: const Color(0xFF818CF8).withAlpha(20),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyStats() {
    final now = DateTime.now();
    final geoMonths = [
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
    final monthLabel = '${geoMonths[now.month - 1]} ${now.year}';

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
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8).withAlpha(20),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF818CF8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ამ თვეში — $monthLabel',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFAFAFA),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'ნამუშევარი',
                  value: '$_workedDays',
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'დასვენება',
                  value: '$_monthRestDays',
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'გამომუშ.',
                  value: '₾${_currentEarnings.toStringAsFixed(0)}',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAndForecast() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekly summary
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
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
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.date_range_rounded,
                        color: Color(0xFF10B981),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ამ კვირაში',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFAFAFA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$_weekWorkedDays დღე',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₾${_weekEarnings.toStringAsFixed(0)} გამომუშ.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Salary forecast
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
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
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: Color(0xFFF59E0B),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'სავარ. შემ.',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFAFAFA),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '₾${_forecastTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF59E0B),
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+$_remainingScheduledDays დღე დარჩა',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastPaymentInfo() {
    final dateStr = _lastPaymentDate != null
        ? _formatDate(_lastPaymentDate!)
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2028)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: Color(0xFF6B7280), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ბოლო ჩარიცხვა: ₾${_lastPaymentAmount!.toStringAsFixed(0)}${dateStr.isNotEmpty ? ' · $dateStr' : ''}',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_remaining == 0 && _currentEarnings > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'სრულად მიღებულია ✓',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    final canPay = _remaining > 0;
    return GestureDetector(
      onTap: canPay ? _onPaymentReceived : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: canPay ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            gradient: canPay
                ? const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: canPay ? null : const Color(0xFF111214),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: canPay ? Colors.transparent : const Color(0xFF1E2028),
            ),
            boxShadow: canPay
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withAlpha(50),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payments_rounded,
                color: canPay ? Colors.white : const Color(0xFF4B5563),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'თანხის მიღება',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: canPay ? Colors.white : const Color(0xFF4B5563),
                  letterSpacing: -0.2,
                ),
              ),
              if (canPay) ...[
                const SizedBox(width: 8),
                Text(
                  '₾${_remaining.toStringAsFixed(0)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatPeriodRange(DateTime start, DateTime end) {
    final geoMonths = [
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
    return '${start.day} ${geoMonths[start.month - 1]} — ${end.day} ${geoMonths[end.month - 1]}';
  }

  String _formatDate(DateTime d) {
    final geoMonths = [
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
    return '${d.day} ${geoMonths[d.month - 1]}';
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _skeletonBox(44, 200),
          const SizedBox(height: 20),
          _skeletonBox(200, double.infinity),
          const SizedBox(height: 14),
          _skeletonBox(60, double.infinity),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _skeletonBox(80, double.infinity)),
              const SizedBox(width: 12),
              Expanded(child: _skeletonBox(80, double.infinity)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _skeletonBox(80, double.infinity)),
              const SizedBox(width: 12),
              Expanded(child: _skeletonBox(80, double.infinity)),
              const SizedBox(width: 12),
              Expanded(child: _skeletonBox(80, double.infinity)),
            ],
          ),
          const SizedBox(height: 14),
          _skeletonBox(120, double.infinity),
          const SizedBox(height: 14),
          _skeletonBox(70, double.infinity),
        ],
      ),
    );
  }

  Widget _skeletonBox(double h, double w) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: const Color(0xFF16181C),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─── Mini stat widget ─────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(35)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
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
              color: color.withAlpha(180),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool highlight;

  const _FinanceCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight
              ? const Color(0xFFF59E0B).withAlpha(60)
              : const Color(0xFF1E2028),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFFAFAFA),
              letterSpacing: -0.5,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
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
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
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
}

/// Missed day resolution dialog
class _MissedDayDialog extends StatelessWidget {
  final DateTime date;
  final double wage;
  final Future<void> Function(bool) onConfirm;
  final VoidCallback onSkip;

  const _MissedDayDialog({
    required this.date,
    required this.wage,
    required this.onConfirm,
    required this.onSkip,
  });

  String _formatDate(DateTime d) {
    const geoWeekdays = [
      '',
      'ორშაბათი',
      'სამშაბათი',
      'ოთხშაბათი',
      'ხუთშაბათი',
      'პარასკევი',
      'შაბათი',
      'კვირა',
    ];
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
    return '${geoWeekdays[d.weekday]}, ${d.day} ${geoMonths[d.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16181C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF1E2028)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(20),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withAlpha(60),
                ),
              ),
              child: const Icon(
                Icons.pending_actions_rounded,
                color: Color(0xFFF59E0B),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'დადასტურება საჭიროა',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFAFAFA),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(date),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'იმუშავე ამ დღეს?',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: const Color(0xFFFAFAFA),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onConfirm(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withAlpha(15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withAlpha(50),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'არა',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onConfirm(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withAlpha(50),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'დიახ',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onSkip,
              child: Text(
                'გამოტოვება',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Partial payment dialog — asks how much was received.
class _PartialPaymentDialog extends StatefulWidget {
  final double totalEarned;
  final double alreadyReceived;
  final double remaining;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int workedDays;
  final double wage;

  const _PartialPaymentDialog({
    required this.totalEarned,
    required this.alreadyReceived,
    required this.remaining,
    required this.periodStart,
    required this.periodEnd,
    required this.workedDays,
    required this.wage,
  });

  @override
  State<_PartialPaymentDialog> createState() => _PartialPaymentDialogState();
}

class _PartialPaymentDialogState extends State<_PartialPaymentDialog> {
  late TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.remaining.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _validate() {
    final val = double.tryParse(_ctrl.text.trim());
    if (val == null || val <= 0) {
      setState(() => _error = 'შეიყვანეთ სწორი თანხა');
      return;
    }
    if (widget.alreadyReceived + val > widget.totalEarned) {
      setState(
        () => _error =
            'მიღებული თანხა არ შეიძლება იყოს გამომუშავებულ თანხაზე მეტი',
      );
      return;
    }
    Navigator.of(context).pop(val);
  }

  String _fmtDate(DateTime d) {
    final geoMonths = [
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
    return '${d.day} ${geoMonths[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final afterPayment = (double.tryParse(_ctrl.text.trim()) ?? 0);
    final newReceived = widget.alreadyReceived + afterPayment;
    final newRemaining = (widget.totalEarned - newReceived).clamp(
      0.0,
      double.infinity,
    );

    return Dialog(
      backgroundColor: const Color(0xFF16181C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF1E2028)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withAlpha(60),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.payments_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'თანხის მიღება',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFAFAFA),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'რამდენი თანხა მიიღე?',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111214),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _error != null
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981).withAlpha(60),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFAFAFA),
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  prefixText: '₾  ',
                  prefixStyle: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFFEF4444),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111214),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E2028)),
              ),
              child: Column(
                children: [
                  _row(
                    'პერიოდი',
                    '${_fmtDate(widget.periodStart)} — ${_fmtDate(widget.periodEnd)}',
                  ),
                  const SizedBox(height: 8),
                  _row(
                    'გამომუშავებული',
                    '₾${widget.totalEarned.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  _row(
                    'უკვე მიღებული',
                    '₾${widget.alreadyReceived.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  _row(
                    'ახლა მიიღე',
                    '₾${afterPayment.toStringAsFixed(0)}',
                    highlight: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFF1E2028), height: 1),
                  ),
                  _row('დარჩება', '₾${newRemaining.toStringAsFixed(0)}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111214),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1E2028)),
                      ),
                      child: Center(
                        child: Text(
                          'გაუქმება',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _validate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withAlpha(50),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'დადასტურება',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: highlight ? 15 : 12,
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
