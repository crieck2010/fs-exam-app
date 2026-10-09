import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';
import 'features/study/srs/study_repository.dart';

/// Entry point. Theme choice is loaded before the first frame so there is
/// no light/dark flash on startup.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
        Provider(create: (_) => StudyRepository(prefs)),
      ],
      child: const FsExamApp(),
    ),
  );
}
