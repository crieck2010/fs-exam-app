# Notifications

Local-notification nudges for the study loop (v0.3.0+). All scheduling is
on-device — no server, no accounts. Everything is guarded: if the plugin
is unavailable or permission is denied, the app works exactly as before.

## Shipped in v0.3.0

| # | Nudge | Schedule | Condition |
|---|-------|----------|-----------|
| 1 | Question of the day | Daily 8:00 AM | Toggle on |
| 2 | Streak saver | One-time 8:00 PM today | QOTD unanswered **and** streak > 0 |
| 3 | Weekly report | Monday 8:00 AM | Toggle on |

**The streak saver is the clever one.** A local notification can't run
code at fire time, so instead of background execution the app re-arms the
saver on every launch: if the QOTD is still unanswered at 8 PM and a
streak is alive, a one-time notification is scheduled for tonight; once
the QOTD is answered, it's cancelled. Exactly conditional, zero
background work. (Trade-off: the user must open the app at least once
that day to arm it — fine for a streak product.)

Toggles live in Settings → Notifications, persisted in SharedPreferences
(`notif_qotd_v1`, `notif_streak_saver_v1`, `notif_weekly_v1`), all default
on. Implementation: `lib/core/notifications/notification_service.dart`
(API verified against flutter_local_notifications 22.3.1).

## Suggested ideas (status)

1. ✅ **QOTD morning nudge** — shipped.
2. ✅ **Streak saver (evening, conditional)** — shipped.
3. ✅ **Weekly report Monday** — shipped.
4. 🔜 **Review avalanche** — when the SRS due queue crosses 25: "23
   questions are due — clear them in 10 minutes?" Needs background fetch
   or a server; candidate for Phase 3.
5. 🔜 **Milestone celebrations** — 7/30/100-day streaks, 100/1,000
   questions answered. Checkable on app open (no background needed);
   cheap — suggested for v0.3.1.
6. 🔜 **Comeback nudge** — 48h without opening the app: "Your review
   queue missed you." Needs background execution; Phase 3.
7. 🔜→✅ **Exam countdown** — shipped in v0.4.0 as an in-app countdown
   card (phased advice) plus a smarter QOTD notification body in the
   crunch zone; the exam date lives in Settings.
8. 🔜→✅ **Weak-area ping** — shipped in v0.4.0: urgent home card in the
   final 30 days (dismissible daily) + the dynamic notification body.
   A background-scheduled variant remains a Phase 3 candidate.

## Platform setup

First run on a fresh checkout (platform folders are not committed):

```bash
flutter create --platforms=android,ios .
```

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

We use `AndroidScheduleMode.inexactAllowWhileIdle`, so no exact-alarm
permission is needed. `POST_NOTIFICATIONS` (Android 13+) is requested at
runtime by the plugin.

### iOS

Permission is requested in code (`requestPermissions(alert:badge:sound:)`).
No entitlements changes needed for local notifications.

## Testing checklist (on device)

- [ ] Fresh install → permission prompt appears once
- [ ] QOTD nudge fires at 8:00 AM (change device clock to verify)
- [ ] Answer QOTD → 8:00 PM streak saver never fires
- [ ] Skip QOTD with streak > 0 → saver fires at 8:00 PM
- [ ] Toggle off in Settings → pending notification cancelled
- [ ] Deny permission → app works normally, no crashes
