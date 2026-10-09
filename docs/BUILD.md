# Build & Run

Requires the Flutter SDK (3.38+): https://docs.flutter.dev/get-started/install

First run on a fresh checkout (platform folders are not committed):

```bash
flutter create --platforms=android,ios .
```

Then:

```bash
cd fs-exam-app
flutter pub get        # install dependencies
flutter analyze        # lints (must be clean)
flutter test           # unit tests
flutter run            # debug on a connected device / emulator
```

## Regenerating question banks

```bash
pip install -e ../fs-exam-prep   # the Phase 1 engine
python3 tools/generate_banks.py --n 10 --seeds 7 42
```

Then list any new seed files in `BankRepository.availableBanks`.

## Release builds

```bash
flutter build appbundle   # Google Play upload
flutter build apk         # sideload / testing
flutter build ipa         # App Store (needs macOS + Xcode)
```

## Store checklist (Phase 3)

- Google Play: $25 one-time developer registration.
- Apple App Store: $99/year Apple Developer Program.
- Before submission: real app icon (`flutter_launcher_icons`), splash
  screen, privacy policy URL (required by both stores once ads/analytics
  ship), and the Phase 3 `Entitlements` implementation.
- CI (`.github/workflows/ci.yml`) runs `flutter analyze` + `flutter test`
  on every push.
