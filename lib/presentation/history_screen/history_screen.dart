import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/work_data_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final WorkDataService _service = WorkDataService();

  bool _loading = true;
  List<MonthlyPeriod> _periods = [];
  double _lifetimeReceived = 0.0;
  int _totalWorkedDays = 0;

  late AnimationController _entranceCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final periods = await _service.loadMonthlyPeriods();
    final allDays = await _service.loadWorkDays();

    final relevant =
        periods
            .where((p) => p.workedDays > 0 || p.transactions.isNotEmpty)
            .toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final lifetime = periods.fold<double>(0, (s, p) => s + p.totalReceived);
    final totalWorked = allDays.where((d) => d.worked).length;

    setState(() {
      _periods = relevant;
      _lifetimeReceived = lifetime;
      _totalWorkedDays = totalWorked;
      _loading = false;
    });
    _entranceCtrl.forward(from: 0);
  }

  static const List<String> _geoMonths = [
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

  static const List<String> _geoMonthsShort = [
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

  String _formatMonthYear(DateTime d) => '${_geoMonths[d.month - 1]} ${d.year}';
  String _formatDateShort(DateTime d) =>
      '${d.day} ${_geoMonthsShort[d.month - 1]}';
  String _formatDate(DateTime d) =>
      '${d.day} ${_geoMonthsShort[d.month - 1]} ${d.year}';

  void _showTransactionDetail(PaymentTransaction tx, MonthlyPeriod period) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TransactionDetailSheet(
        transaction: tx,
        period: period,
        formatDate: _formatDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF10B981),
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: const Color(0xFF10B981),
                        backgroundColor: const Color(0xFF16181C),
                        child: _periods.isEmpty ? _buildEmpty() : _buildList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ისტორია',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFAFAFA),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${_periods.length} პერიოდი',
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

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF111214),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1E2028)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF2A2D35),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ისტორია ცარიელია',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'სამუშაო დღეების დაფიქსირების შემდეგ\nისტორია გამოჩნდება.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: _periods.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildLifetimeCard();
        return _buildPeriodCard(_periods[index - 1]);
      },
    );
  }

  Widget _buildLifetimeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF064E3B).withAlpha(180),
            const Color(0xFF0A0B0D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withAlpha(15),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withAlpha(50),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'მთლიანად მიღებული',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _lifetimeReceived),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => Text(
                        '₾${value.toStringAsFixed(0)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFAFAFA),
                          letterSpacing: -0.8,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_periods.length}',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    'პერიოდი',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_totalWorkedDays > 0) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF1A2E1A), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  color: Color(0xFF10B981),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'სულ ნამუშევარი დღეები: $_totalWorkedDays',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodCard(MonthlyPeriod period) {
    final isFullyPaid = period.isFullyPaid;
    final isPartial = period.totalReceived > 0 && !isFullyPaid;
    final hasUnpaid = period.totalReceived == 0 && period.totalEarned > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFullyPaid
              ? const Color(0xFF10B981).withAlpha(40)
              : isPartial
              ? const Color(0xFFF59E0B).withAlpha(40)
              : const Color(0xFF1E2028),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatMonthYear(period.startDate),
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFAFAFA),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                _statusBadge(isFullyPaid, isPartial, hasUnpaid),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'პერიოდი: ${_formatDateShort(period.startDate)} — ${_formatDateShort(period.endDate)}',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF16181C),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _summaryRow('ნამუშევარი დღეები', '${period.workedDays}'),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'დღიური ანაზღაურება',
                    '₾${period.dailyWage.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'გამომუშავებული',
                    '₾${period.totalEarned.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'მიღებული',
                    '₾${period.totalReceived.toStringAsFixed(0)}',
                    valueColor: const Color(0xFF10B981),
                  ),
                  if (period.remaining > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow(
                      'დარჩენილი',
                      '₾${period.remaining.toStringAsFixed(0)}',
                      valueColor: const Color(0xFFF59E0B),
                    ),
                  ],
                ],
              ),
            ),
            if (period.transactions.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF1A1D23), height: 1),
              const SizedBox(height: 12),
              Text(
                'ჩარიცხვები',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ...period.transactions.map(
                (tx) => _buildTransactionRow(tx, period),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(PaymentTransaction tx, MonthlyPeriod period) {
    return GestureDetector(
      onTap: () => _showTransactionDetail(tx, period),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withAlpha(8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withAlpha(20)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.note.isNotEmpty ? tx.note : 'ჩარიცხვა',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFFFAFAFA),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDate(tx.date),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    '+₾${tx.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF4B5563),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(bool isFullyPaid, bool isPartial, bool hasUnpaid) {
    if (isFullyPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              'სრულად მიღებულია',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else if (isPartial) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF59E0B).withAlpha(50)),
        ),
        child: Text(
          'ნაწილობრივ მიღებულია',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: const Color(0xFFF59E0B),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else if (hasUnpaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF4444).withAlpha(40)),
        ),
        child: Text(
          'ჯერ არ მიღებულა',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: const Color(0xFFEF4444),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFFFAFAFA),
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Transaction detail bottom sheet
class _TransactionDetailSheet extends StatelessWidget {
  final PaymentTransaction transaction;
  final MonthlyPeriod period;
  final String Function(DateTime) formatDate;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.period,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final isFullPayment = transaction.amount >= period.totalEarned;
    final isPartial =
        !isFullPayment && period.totalReceived < period.totalEarned;

    String statusLabel;
    Color statusColor;
    if (isFullPayment || period.isFullyPaid) {
      statusLabel = 'სრული ჩარიცხვა';
      statusColor = const Color(0xFF10B981);
    } else {
      statusLabel = 'ნაწილობრივი ჩარიცხვა';
      statusColor = const Color(0xFFF59E0B);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16181C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2D35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 16),
          Text(
            'ჩარიცხვა',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFAFAFA),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₾${transaction.amount.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF10B981),
              letterSpacing: -1,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111214),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2028)),
            ),
            child: Column(
              children: [
                _detailRow(
                  'თანხა',
                  '₾${transaction.amount.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 10),
                _detailRow('თარიღი', formatDate(transaction.date)),
                const SizedBox(height: 10),
                _detailRow('სტატუსი', statusLabel, valueColor: statusColor),
                const SizedBox(height: 10),
                _detailRow(
                  'შენიშვნა',
                  transaction.note.isNotEmpty ? transaction.note : '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111214),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E2028)),
              ),
              child: Center(
                child: Text(
                  'დახურვა',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFFFAFAFA),
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
