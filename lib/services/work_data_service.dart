import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WorkDay {
  final DateTime date;
  final bool worked;
  final double wageEarned;

  WorkDay({required this.date, required this.worked, required this.wageEarned});

  factory WorkDay.fromMap(Map<String, dynamic> map) => WorkDay(
    date: DateTime.parse(map['date'] as String),
    worked: map['worked'] as bool,
    wageEarned: (map['wageEarned'] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'date': _dateOnly(date).toIso8601String(),
    'worked': worked,
    'wageEarned': wageEarned,
  };
}

/// A single payment transaction within a monthly period.
class PaymentTransaction {
  final String id;
  final DateTime date;
  final double amount;
  final String note;

  PaymentTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.note,
  });

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) =>
      PaymentTransaction(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        amount: (map['amount'] as num).toDouble(),
        note: (map['note'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'amount': amount,
    'note': note,
  };
}

/// A monthly salary period with partial payment support.
class MonthlyPeriod {
  final String id; // e.g. "2026-08"
  final DateTime startDate;
  final DateTime endDate;
  final int workedDays;
  final double dailyWage;
  final double totalEarned;
  final double totalReceived;
  final List<PaymentTransaction> transactions;
  final bool isClosed; // true when month is over / manually closed

  MonthlyPeriod({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.workedDays,
    required this.dailyWage,
    required this.totalEarned,
    required this.totalReceived,
    required this.transactions,
    required this.isClosed,
  });

  double get remaining =>
      (totalEarned - totalReceived).clamp(0.0, double.infinity);
  bool get isFullyPaid => remaining == 0 && totalEarned > 0;

  factory MonthlyPeriod.fromMap(Map<String, dynamic> map) {
    try {
      final txList =
          (map['transactions'] as List?)
              ?.map(
                (e) => PaymentTransaction.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          [];
      return MonthlyPeriod(
        id: map['id'] as String,
        startDate: DateTime.parse(map['startDate'] as String),
        endDate: DateTime.parse(map['endDate'] as String),
        workedDays: map['workedDays'] as int,
        dailyWage: (map['dailyWage'] as num).toDouble(),
        totalEarned: (map['totalEarned'] as num).toDouble(),
        totalReceived: (map['totalReceived'] as num).toDouble(),
        transactions: txList,
        isClosed: (map['isClosed'] as bool?) ?? false,
      );
    } catch (_) {
      return MonthlyPeriod(
        id: '',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        workedDays: 0,
        dailyWage: 0,
        totalEarned: 0,
        totalReceived: 0,
        transactions: [],
        isClosed: false,
      );
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'workedDays': workedDays,
    'dailyWage': dailyWage,
    'totalEarned': totalEarned,
    'totalReceived': totalReceived,
    'transactions': transactions.map((t) => t.toMap()).toList(),
    'isClosed': isClosed,
  };

  MonthlyPeriod copyWith({
    int? workedDays,
    double? dailyWage,
    double? totalEarned,
    double? totalReceived,
    List<PaymentTransaction>? transactions,
    bool? isClosed,
    DateTime? endDate,
  }) => MonthlyPeriod(
    id: id,
    startDate: startDate,
    endDate: endDate ?? this.endDate,
    workedDays: workedDays ?? this.workedDays,
    dailyWage: dailyWage ?? this.dailyWage,
    totalEarned: totalEarned ?? this.totalEarned,
    totalReceived: totalReceived ?? this.totalReceived,
    transactions: transactions ?? this.transactions,
    isClosed: isClosed ?? this.isClosed,
  );
}

/// Legacy PaymentPeriod kept for migration compatibility.
class PaymentPeriod {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final int workedDays;
  final double dailyWage;
  final double totalEarned;
  final DateTime paidDate;

  PaymentPeriod({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.workedDays,
    required this.dailyWage,
    required this.totalEarned,
    required this.paidDate,
  });

  factory PaymentPeriod.fromMap(Map<String, dynamic> map) => PaymentPeriod(
    id: map['id'] as int,
    startDate: DateTime.parse(map['startDate'] as String),
    endDate: DateTime.parse(map['endDate'] as String),
    workedDays: map['workedDays'] as int,
    dailyWage: (map['dailyWage'] as num).toDouble(),
    totalEarned: (map['totalEarned'] as num).toDouble(),
    paidDate: DateTime.parse(map['paidDate'] as String),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'workedDays': workedDays,
    'dailyWage': dailyWage,
    'totalEarned': totalEarned,
    'paidDate': paidDate.toIso8601String(),
  };
}

class AppSettings {
  final double dailyWage;
  final List<bool> workDays; // Mon=0 ... Sun=6
  final int reminderHour;
  final int reminderMinute;
  final bool notificationsEnabled;

  AppSettings({
    this.dailyWage = 80.0,
    List<bool>? workDays,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.notificationsEnabled = true,
  }) : workDays = workDays ?? [true, true, true, true, true, false, false];

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    try {
      return AppSettings(
        dailyWage: (map['dailyWage'] as num).toDouble(),
        workDays: (map['workDays'] as List).cast<bool>(),
        reminderHour: map['reminderHour'] as int,
        reminderMinute: map['reminderMinute'] as int,
        notificationsEnabled: map['notificationsEnabled'] as bool,
      );
    } catch (_) {
      return AppSettings();
    }
  }

  Map<String, dynamic> toMap() => {
    'dailyWage': dailyWage,
    'workDays': workDays,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'notificationsEnabled': notificationsEnabled,
  };

  AppSettings copyWith({
    double? dailyWage,
    List<bool>? workDays,
    int? reminderHour,
    int? reminderMinute,
    bool? notificationsEnabled,
  }) => AppSettings(
    dailyWage: dailyWage ?? this.dailyWage,
    workDays: workDays ?? this.workDays,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
  );
}

/// Normalise any DateTime to a date-only value (midnight local time).
DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Build a period ID string from year+month.
String _periodId(int year, int month) =>
    '$year-${month.toString().padLeft(2, '0')}';

class WorkDataService {
  static const String _settingsKey = 'app_settings_v2';
  static const String _workDaysKey = 'work_days_v2';
  static const String _monthlyPeriodsKey = 'monthly_periods_v3';
  // Legacy keys kept for migration
  static const String _paymentHistoryKey = 'payment_history_v2';
  static const String _periodStartKey = 'period_start_v2';
  static const String _nextIdKey = 'next_payment_id_v2';

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString(_settingsKey);
    raw ??= prefs.getString('app_settings');
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toMap()));
  }

  // ── Work Days ─────────────────────────────────────────────────────────────

  Future<List<WorkDay>> loadWorkDays() async {
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString(_workDaysKey);
    raw ??= prefs.getString('work_days');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => WorkDay.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWorkDays(List<WorkDay> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _workDaysKey,
      jsonEncode(days.map((d) => d.toMap()).toList()),
    );
  }

  /// Records or updates a work day entry. Prevents duplicates.
  /// Also updates the current monthly period's earned amount.
  Future<void> recordWorkDay(DateTime date, bool worked, double wage) async {
    final days = await loadWorkDays();
    final dateOnly = _dateOnly(date);
    days.removeWhere((d) => _dateOnly(d.date) == dateOnly);
    days.add(
      WorkDay(date: dateOnly, worked: worked, wageEarned: worked ? wage : 0),
    );
    days.sort((a, b) => a.date.compareTo(b.date));
    await saveWorkDays(days);

    // Update the monthly period for this date
    await _syncMonthlyPeriod(dateOnly.year, dateOnly.month, wage);
  }

  // ── Monthly Periods ───────────────────────────────────────────────────────

  Future<List<MonthlyPeriod>> loadMonthlyPeriods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_monthlyPeriodsKey);
    if (raw == null) {
      // Migrate from legacy payment history if present
      return await _migrateFromLegacy();
    }
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => MonthlyPeriod.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMonthlyPeriods(List<MonthlyPeriod> periods) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _monthlyPeriodsKey,
      jsonEncode(periods.map((p) => p.toMap()).toList()),
    );
  }

  /// Get or create the monthly period for a given year/month.
  Future<MonthlyPeriod> getOrCreateMonthlyPeriod(
    int year,
    int month,
    double dailyWage,
  ) async {
    final periods = await loadMonthlyPeriods();
    final id = _periodId(year, month);
    final existing = periods.where((p) => p.id == id).firstOrNull;
    if (existing != null) return existing;

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0); // last day of month
    final newPeriod = MonthlyPeriod(
      id: id,
      startDate: start,
      endDate: end,
      workedDays: 0,
      dailyWage: dailyWage,
      totalEarned: 0,
      totalReceived: 0,
      transactions: [],
      isClosed: false,
    );
    periods.add(newPeriod);
    await saveMonthlyPeriods(periods);
    return newPeriod;
  }

  /// Recalculate and sync a monthly period's worked days and earned amount
  /// from the actual work day records.
  Future<void> _syncMonthlyPeriod(int year, int month, double wage) async {
    final allDays = await loadWorkDays();
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    final monthDays = allDays.where((d) {
      final dateOnly = _dateOnly(d.date);
      return !dateOnly.isBefore(firstDay) && !dateOnly.isAfter(lastDay);
    }).toList();

    final workedCount = monthDays.where((d) => d.worked).length;
    final earned = workedCount * wage;

    final periods = await loadMonthlyPeriods();
    final id = _periodId(year, month);
    final idx = periods.indexWhere((p) => p.id == id);

    if (idx >= 0) {
      periods[idx] = periods[idx].copyWith(
        workedDays: workedCount,
        totalEarned: earned,
        dailyWage: wage,
      );
    } else {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0);
      periods.add(
        MonthlyPeriod(
          id: id,
          startDate: start,
          endDate: end,
          workedDays: workedCount,
          dailyWage: wage,
          totalEarned: earned,
          totalReceived: 0,
          transactions: [],
          isClosed: false,
        ),
      );
    }
    await saveMonthlyPeriods(periods);
  }

  /// Add a partial payment to the current month's period.
  /// Returns an error string if invalid, null if success.
  Future<String?> addPartialPayment(double amount) async {
    final now = DateTime.now();
    final settings = await loadSettings();
    await _syncMonthlyPeriod(now.year, now.month, settings.dailyWage);

    final periods = await loadMonthlyPeriods();
    final id = _periodId(now.year, now.month);
    final idx = periods.indexWhere((p) => p.id == id);

    MonthlyPeriod current;
    if (idx < 0) {
      current = await getOrCreateMonthlyPeriod(
        now.year,
        now.month,
        settings.dailyWage,
      );
      final periods2 = await loadMonthlyPeriods();
      final idx2 = periods2.indexWhere((p) => p.id == id);
      if (idx2 < 0) return 'შეცდომა: პერიოდი ვერ მოიძებნა';
      current = periods2[idx2];
    } else {
      current = periods[idx];
    }

    if (amount <= 0) {
      return 'თანხა უნდა იყოს 0-ზე მეტი';
    }
    if (current.totalReceived + amount > current.totalEarned) {
      return 'მიღებული თანხა არ შეიძლება იყოს გამომუშავებულ თანხაზე მეტი';
    }

    final txId = '${id}_${now.millisecondsSinceEpoch}';
    final tx = PaymentTransaction(
      id: txId,
      date: _dateOnly(now),
      amount: amount,
      note: current.totalReceived + amount >= current.totalEarned
          ? 'საბოლოო ჩარიცხვა'
          : 'ნაწილობრივი ჩარიცხვა',
    );

    final newReceived = current.totalReceived + amount;
    final updatedTxs = [...current.transactions, tx];
    final updated = current.copyWith(
      totalReceived: newReceived,
      transactions: updatedTxs,
    );

    final allPeriods = await loadMonthlyPeriods();
    final allIdx = allPeriods.indexWhere((p) => p.id == id);
    if (allIdx >= 0) {
      allPeriods[allIdx] = updated;
    } else {
      allPeriods.add(updated);
    }
    await saveMonthlyPeriods(allPeriods);
    return null; // success
  }

  /// Get the current month's period, creating it if needed.
  Future<MonthlyPeriod> getCurrentMonthPeriod() async {
    final now = DateTime.now();
    final settings = await loadSettings();
    await _syncMonthlyPeriod(now.year, now.month, settings.dailyWage);
    final periods = await loadMonthlyPeriods();
    final id = _periodId(now.year, now.month);
    return periods.firstWhere(
      (p) => p.id == id,
      orElse: () => MonthlyPeriod(
        id: id,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        workedDays: 0,
        dailyWage: settings.dailyWage,
        totalEarned: 0,
        totalReceived: 0,
        transactions: [],
        isClosed: false,
      ),
    );
  }

  /// Returns stats for the current payment period (backward compat).
  Future<Map<String, dynamic>> getCurrentPeriodStats() async {
    final now = DateTime.now();
    final settings = await loadSettings();
    await _syncMonthlyPeriod(now.year, now.month, settings.dailyWage);

    final allDays = await loadWorkDays();
    final periods = await loadMonthlyPeriods();
    final id = _periodId(now.year, now.month);
    final current = periods.firstWhere(
      (p) => p.id == id,
      orElse: () => MonthlyPeriod(
        id: id,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        workedDays: 0,
        dailyWage: settings.dailyWage,
        totalEarned: 0,
        totalReceived: 0,
        transactions: [],
        isClosed: false,
      ),
    );

    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final periodDays = allDays.where((d) {
      final dateOnly = _dateOnly(d.date);
      return !dateOnly.isBefore(firstDay) && !dateOnly.isAfter(lastDay);
    }).toList();

    // Lifetime = sum of all received payments across all periods
    final lifetimeReceived = periods.fold<double>(
      0,
      (s, p) => s + p.totalReceived,
    );

    return {
      'workedDays': current.workedDays,
      'dailyWage': settings.dailyWage,
      'currentEarnings': current.totalEarned,
      'totalReceived': current.totalReceived,
      'remaining': current.remaining,
      'periodStart': current.startDate,
      'periodEnd': current.endDate,
      'lastPayment': current.transactions.isNotEmpty
          ? current.transactions.last.amount
          : 0.0,
      'lastPaymentDate': current.transactions.isNotEmpty
          ? current.transactions.last.date
          : null,
      'lifetimeEarnings': lifetimeReceived,
      'periodDays': periodDays,
      'currentPeriod': current,
    };
  }

  /// Legacy: kept for backward compat with notification handler.
  Future<DateTime> getPeriodStart() async {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Legacy: kept for backward compat.
  Future<void> setPeriodStart(DateTime date) async {}

  /// Legacy: load payment history (returns closed periods as PaymentPeriod).
  Future<List<PaymentPeriod>> loadPaymentHistory() async {
    final periods = await loadMonthlyPeriods();
    return periods
        .where((p) => p.transactions.isNotEmpty)
        .map(
          (p) => PaymentPeriod(
            id: p.id.hashCode,
            startDate: p.startDate,
            endDate: p.endDate,
            workedDays: p.workedDays,
            dailyWage: p.dailyWage,
            totalEarned: p.totalEarned,
            paidDate: p.transactions.last.date,
          ),
        )
        .toList();
  }

  /// Legacy: kept for backward compat.
  Future<void> savePaymentHistory(List<PaymentPeriod> history) async {}

  /// Legacy: kept for backward compat with notification handler.
  Future<PaymentPeriod> markPaymentReceived({
    required DateTime periodStart,
    required List<WorkDay> currentDays,
    required double dailyWage,
  }) async {
    final now = DateTime.now();
    return PaymentPeriod(
      id: now.millisecondsSinceEpoch,
      startDate: periodStart,
      endDate: now,
      workedDays: currentDays.where((d) => d.worked).length,
      dailyWage: dailyWage,
      totalEarned: currentDays.where((d) => d.worked).length * dailyWage,
      paidDate: now,
    );
  }

  // ── Migration ─────────────────────────────────────────────────────────────

  Future<List<MonthlyPeriod>> _migrateFromLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_paymentHistoryKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      final legacyPeriods = list
          .map((e) => PaymentPeriod.fromMap(e as Map<String, dynamic>))
          .toList();
      final result = legacyPeriods.map((p) {
        final id = _periodId(p.startDate.year, p.startDate.month);
        final tx = PaymentTransaction(
          id: '${id}_migrated',
          date: p.paidDate,
          amount: p.totalEarned,
          note: 'ჩარიცხვა',
        );
        return MonthlyPeriod(
          id: id,
          startDate: p.startDate,
          endDate: p.endDate,
          workedDays: p.workedDays,
          dailyWage: p.dailyWage,
          totalEarned: p.totalEarned,
          totalReceived: p.totalEarned,
          transactions: [tx],
          isClosed: true,
        );
      }).toList();
      await saveMonthlyPeriods(result);
      return result;
    } catch (_) {
      return [];
    }
  }
}
