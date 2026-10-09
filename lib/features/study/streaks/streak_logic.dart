/// Pure streak state machine. No I/O, no clock reads — the caller supplies
/// "today", so the logic is fully unit-testable and timezone-explicit.
class StreakState {
  final int count;
  final int best;
  final String? lastDate; // yyyy-MM-dd, local

  const StreakState({this.count = 0, this.best = 0, this.lastDate});

  Map<String, dynamic> toJson() => {
        'count': count,
        'best': best,
        'lastDate': lastDate,
      };

  factory StreakState.fromJson(Map<String, dynamic> json) => StreakState(
        count: (json['count'] as num?)?.toInt() ?? 0,
        best: (json['best'] as num?)?.toInt() ?? 0,
        lastDate: json['lastDate'] as String?,
      );
}

/// 'yyyy-MM-dd' in local time.
String dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Records one active day. Same-day calls are idempotent; a consecutive day
/// extends the streak; any gap restarts it at 1.
StreakState recordStreakDay(StreakState state, DateTime today) {
  final key = dateKey(today);
  if (state.lastDate == key) return state;

  String? yesterdayKey;
  if (state.lastDate != null) {
    final parts = state.lastDate!.split('-').map(int.parse).toList();
    final yesterday =
        DateTime(parts[0], parts[1], parts[2]).add(const Duration(days: 1));
    yesterdayKey = dateKey(yesterday);
  }

  final continued = yesterdayKey == key;
  final count = continued ? state.count + 1 : 1;
  return StreakState(
    count: count,
    best: count > state.best ? count : state.best,
    lastDate: key,
  );
}
