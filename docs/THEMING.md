# Theming

Material 3, one seed color (`0xFF1B5C3F`, surveyor green), two schemes.

## How it works

- `AppTheme.light` / `AppTheme.dark`: `ColorScheme.fromSeed` with
  `brightness: Brightness.light` / `Brightness.dark`. One seed keeps both
  modes visually consistent automatically.
- `ThemeController` (a `ChangeNotifier`): holds the `ThemeMode`,
  persists it to SharedPreferences under `theme_mode`
  (`system` | `light` | `dark`).
- `main()` awaits SharedPreferences **before** `runApp`, so the correct
  theme applies on the very first frame — no flash.
- `FsExamApp` wires `theme`, `darkTheme`, and `themeMode` from the
  controller; the Settings screen's `SegmentedButton<ThemeMode>` is the
  only writer.

## UI best-practice notes

- Screens constrain content to `maxWidth: 720` so the layout stays
  comfortable on tablets as well as phones.
- Choice buttons are full-width with ≥48dp touch targets and text labels
  (no icon-only actions in the quiz flow).
- Feedback uses color *plus* icon *plus* text ("Correct" / "Not quite"),
  never color alone.
- The quiz flow is linear (Back / Next) with a progress bar — no hidden
  gestures required to complete a session.
