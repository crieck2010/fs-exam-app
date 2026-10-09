import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Local-notification nudges for the study loop.
///
/// Shipped in v0.3.0 (see docs/NOTIFICATIONS.md for the full idea list):
///   1. QOTD morning nudge — daily 8:00 AM.
///   2. Streak saver — one-time 8:00 PM, only if today's question is still
///      unanswered and a streak is alive. Re-armed on every app open, so no
///      background execution is needed.
///   3. Weekly report — Monday 8:00 AM.
///
/// Everything is guarded: if the plugin is unavailable (or the user denied
/// permission), the app works exactly as before — notifications are a nudge
/// layer, never a dependency.
///
/// API surface verified against flutter_local_notifications 22.3.1
/// (2026-09). If `flutter pub upgrade` moves the major version, re-check
/// `zonedSchedule`'s parameter list first.
class NotificationService {
  final SharedPreferences _prefs;
  FlutterLocalNotificationsPlugin? _plugin;
  bool _ready = false;

  static const _kQotd = 'notif_qotd_v1';
  static const _kStreakSaver = 'notif_streak_saver_v1';
  static const _kWeekly = 'notif_weekly_v1';

  static const int _idQotd = 100;
  static const int _idStreakSaver = 101;
  static const int _idWeekly = 102;

  NotificationService(this._prefs);

  bool get qotdEnabled => _prefs.getBool(_kQotd) ?? true;
  bool get streakSaverEnabled => _prefs.getBool(_kStreakSaver) ?? true;
  bool get weeklyEnabled => _prefs.getBool(_kWeekly) ?? true;

  Future<void> setQotdEnabled(bool value) =>
      _prefs.setBool(_kQotd, value);
  Future<void> setStreakSaverEnabled(bool value) =>
      _prefs.setBool(_kStreakSaver, value);
  Future<void> setWeeklyEnabled(bool value) =>
      _prefs.setBool(_kWeekly, value);

  bool get isReady => _ready;

  /// Initializes time zones, the plugin, and requests OS permission.
  /// Never throws — callers don't need to guard.
  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        // Fall back to tz.local (UTC); times may be off until next launch.
      }
      _plugin = FlutterLocalNotificationsPlugin();
      await _plugin!.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _plugin!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin!
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _ready = true;
    } catch (_) {
      _ready = false;
      _plugin = null;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'fs_exam_study',
          'Study reminders',
          channelDescription:
              'Question of the day, streak saver, and weekly report nudges',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Reconciles scheduled notifications with current settings and study
  /// state. Call on home load and after the QOTD is answered.
  ///
  /// The streak saver is the clever one: because it is (re)scheduled on
  /// every app open and cancelled once the QOTD is answered, it is exactly
  /// conditional with zero background execution.
  Future<void> refreshSchedules({
    required bool qotdAnsweredToday,
    required int streakCount,
    String? weakAreaName,
    int? examDaysUntil,
  }) async {
    if (!_ready) return;
    try {
      final plugin = _plugin!;

      if (qotdEnabled) {
        await _scheduleDaily(
          id: _idQotd,
          title: "Today's FS question is ready",
          // In the exam crunch zone the nudge names the weak area —
          // the body is dynamic because schedules re-arm on every open.
          body: _qotdBody(weakAreaName, examDaysUntil),
          hour: 8,
          match: DateTimeComponents.time,
        );
      } else {
        await plugin.cancel(_idQotd);
      }

      // Re-arm the saver every open; it only fires if the QOTD is still
      // unanswered at 8 PM. No streak, no saver — the morning nudge suffices.
      await plugin.cancel(_idStreakSaver);
      if (!qotdAnsweredToday && streakSaverEnabled && streakCount > 0) {
        await _scheduleOnceToday(
          id: _idStreakSaver,
          title: 'Your $streakCount-day streak is on the line',
          body: "Answer today's question before midnight to keep it.",
          hour: 20,
        );
      }

      if (weeklyEnabled) {
        await _scheduleDaily(
          id: _idWeekly,
          title: 'Your weekly study report is ready',
          body: 'See your focus areas and strengths.',
          hour: 8,
          weekday: DateTime.monday,
          match: DateTimeComponents.dayOfWeekAndTime,
        );
      } else {
        await plugin.cancel(_idWeekly);
      }
    } catch (_) {
      // A failed schedule must never break the study flow.
    }
  }

  /// QOTD nudge body. In the crunch zone (exam <= 30 days out) with a
  /// known weak area, the nudge says so — specificity beats generic.
  String _qotdBody(String? weakAreaName, int? examDaysUntil) {
    if (weakAreaName != null &&
        examDaysUntil != null &&
        examDaysUntil >= 1 &&
        examDaysUntil <= 30) {
      return '$examDaysUntil days to exam day — $weakAreaName needs work. '
          "Today's question is ready.";
    }
    return 'One question keeps your streak alive.';
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required DateTimeComponents match,
    int weekday = DateTime.monday,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (match == DateTimeComponents.dayOfWeekAndTime) {
      while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    } else if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin!.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: match,
    );
  }

  Future<void> _scheduleOnceToday({
    required int id,
    required String title,
    required String body,
    required int hour,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!scheduled.isAfter(now)) return; // too late; tomorrow's nudge covers it
    await _plugin!.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Opens the OS notification settings for this app.
  Future<void> openSystemSettings() async {
    try {
      await _plugin?.openAppNotificationSettings();
    } catch (_) {}
  }
}
