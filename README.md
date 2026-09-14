# MovieDiary Mobile

MovieDiary's Flutter application.

## Supported toolchain

This repository is pinned to Flutter 3.44.3 (stable), which includes Dart
3.12.2. The checked-in `.fvmrc` is the machine-readable source of truth. The
minimum Flutter version is also declared in `pubspec.yaml` because the project
uses `flutter.config.enable-swift-package-manager`.

With FVM installed:

```powershell
fvm install
fvm flutter --version
fvm flutter pub get
```

Without FVM, install Flutter 3.44.3 stable and invoke that SDK explicitly. Do
not rely on whichever older `flutter` executable happens to be first on PATH.
On the configured Windows workstation, the matching SDK is currently at
`C:\Media\Programming\flutter-stable\bin\flutter.bat`.

## Verification

Run these commands with the pinned SDK from the repository root:

```powershell
fvm flutter test
fvm flutter analyze
fvm flutter build apk --debug --dart-define=MOVIEDIARY_API_BASE_URL=http://10.0.2.2:5000/
```

The Android E2E target uses the local API through the emulator host alias
`10.0.2.2`.
