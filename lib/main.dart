import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/theme_controller.dart';
import 'features/study/srs/study_repository.dart';

/// Entry point. Theme choice is loaded before the first frame so there is
/// no light/dark flash on startup. Notification init is guarded internally
/// and never throws — the app works fully without notification permission.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService(prefs);
  await notifications.init();
  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
        Provider(create: (_) => StudyRepository(prefs)),
        Provider<NotificationService>.value(value: notifications),
      ],
      child: const FsExamApp(),
    ),
  );
}
