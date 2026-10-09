import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/theme/theme_controller.dart';
import '../study/srs/study_repository.dart';
import '../study/streaks/streak_logic.dart';

/// Settings: appearance (system / light / dark), notification nudges,
/// exam date, and about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _examDateKey;

  @override
  void initState() {
    super.initState();
    _examDateKey = context.read<StudyRepository>().examDateKey;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = context.watch<ThemeController>();
    final notifications = context.watch<NotificationService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Appearance', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              // SegmentedButton is the Material 3 control for exclusive
              // choice from a small set — the right widget for theme mode.
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.settings_suggest_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {themeController.mode},
                onSelectionChanged: (selection) =>
                    context.read<ThemeController>().setMode(selection.first),
              ),
              const SizedBox(height: 8),
              Text(
                'System follows your phone\u2019s setting. '
                'Your choice is saved on this device.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Text('Notifications', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              SwitchListTile(
                secondary: const Icon(Icons.today_outlined),
                title: const Text('Question of the day'),
                subtitle:
                    const Text('Daily 8:00 AM nudge with today\u2019s question'),
                value: notifications.qotdEnabled,
                onChanged: (value) async {
                  await notifications.setQotdEnabled(value);
                  await _resync(context, notifications);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.local_fire_department_outlined),
                title: const Text('Streak saver'),
                subtitle: const Text(
                    '8:00 PM reminder, only when today\u2019s question is '
                    'still unanswered and a streak is alive'),
                value: notifications.streakSaverEnabled,
                onChanged: (value) async {
                  await notifications.setStreakSaverEnabled(value);
                  await _resync(context, notifications);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.bar_chart_outlined),
                title: const Text('Weekly report'),
                subtitle:
                    const Text('Monday 8:00 AM — your week in review'),
                value: notifications.weeklyEnabled,
                onChanged: (value) async {
                  await notifications.setWeeklyEnabled(value);
                  await _resync(context, notifications);
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Open system notification settings'),
                onPressed: notifications.openSystemSettings,
              ),
              const SizedBox(height: 24),
              Text('Exam', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Exam date'),
                subtitle: Text(_examDateKey == null
                    ? 'Not set — the countdown and exam pings need it'
                    : _examDateKey!),
                trailing: _examDateKey == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear exam date',
                        onPressed: () async {
                          await context
                              .read<StudyRepository>()
                              .clearExamDate();
                          setState(() => _examDateKey = null);
                        },
                      ),
                onTap: () => _pickExamDate(context),
              ),
              const SizedBox(height: 24),
              Text('About', style: theme.textTheme.titleLarge),
              const ListTile(
                leading: Icon(Icons.info_outlined),
                title: Text('FS Exam Prep'),
                subtitle: Text('Quiz practice for the NCEES FS exam'),
              ),
              const ListTile(
                leading: Icon(Icons.storage_outlined),
                title: Text('Question bank'),
                subtitle: Text(
                    'Dynamically generated by the fs-exam-prep engine · schema v1'),
              ),
              const ListTile(
                leading: Icon(Icons.lock_outlined),
                title: Text('Version'),
                subtitle: Text('0.4.0 (engine schema v1.0.0)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reconciles schedules with the new toggle state. Conservative: never
  /// arms a streak saver from Settings (home re-arms it on every open
  /// with real state).
  Future<void> _resync(
      BuildContext context, NotificationService notifications) async {
    await notifications.refreshSchedules(
      qotdAnsweredToday: true,
      streakCount: 0,
    );
    if (context.mounted) setState(() {});
  }

  Future<void> _pickExamDate(BuildContext context) async {
    final now = DateTime.now();
    var initial = now.add(const Duration(days: 60));
    if (_examDateKey != null) {
      final parts = _examDateKey!.split('-').map(int.parse).toList();
      initial = DateTime(parts[0], parts[1], parts[2]);
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null && context.mounted) {
      final key = dateKey(picked);
      await context.read<StudyRepository>().setExamDate(key);
      setState(() => _examDateKey = key);
    }
  }
}
