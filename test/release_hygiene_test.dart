import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MovieDiary 3.0 release metadata is explicit', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('version: 3.0.0+95'));
    expect(pubspec, isNot(contains('version: 2.0.1+94')));
  });

  test('local Android signing properties cannot be committed again', () {
    final ignore = File('.gitignore').readAsStringSync();

    expect(ignore, contains('/android/key.properties'));
    expect(ignore, contains('*.jks'));

    if (Directory('.git').existsSync()) {
      final tracked = Process.runSync(
        'git',
        const ['ls-files', '--error-unmatch', '--', 'android/key.properties'],
      );
      expect(tracked.exitCode, isNot(0));
    }
  });

  test('release diagnostics and banners are disabled deliberately', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final homeSource = File('lib/Widgets/m_home.dart').readAsStringSync();
    final settingsSource = File('lib/Widgets/Settings.dart').readAsStringSync();

    expect(mainSource, contains('if (kReleaseMode)'));
    expect(mainSource, contains('debugPrint ='));
    expect(homeSource, contains('debugShowCheckedModeBanner: false'));
    expect(homeSource, isNot(contains('error!.details')));
    expect(settingsSource, contains('This can’t be undone.'));
    expect(settingsSource,
        contains("removes its saved ratings and Watchlist items"));
  });
}
