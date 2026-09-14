import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

typedef _ReleaseMetadata = ({
  int major,
  int minor,
  int patch,
  int build,
});

// Update this test-owned contract in the same commit as a deliberate version
// bump. Application and deployment configuration must remain the source of
// truth; this constant makes a stale release gate explicit during review.
const _expectedReleaseMetadata = (
  major: 3,
  minor: 0,
  patch: 1,
  build: 96,
);

void main() {
  group('MovieDiary 3.0 release metadata', () {
    test('pubspec declares the intended current release', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(
        _validateCurrentRelease(_readDeclaredRelease(pubspec)),
        _expectedReleaseMetadata,
      );
    });

    test('accepts the current test-owned release contract', () {
      expect(
        _validateCurrentRelease('3.0.1+96'),
        _expectedReleaseMetadata,
      );
    });

    test('rejects legacy 2.x metadata explicitly', () {
      expect(
        () => _validateCurrentRelease('2.0.1+94'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('3.x'),
          ),
        ),
      );
    });

    test('rejects malformed or non-positive release metadata', () {
      for (final value in ['3.0+96', '3.0.1', '3.0.1+0', '03.0.1+96']) {
        expect(
          () => _parseReleaseMetadata(value),
          throwsA(isA<FormatException>()),
          reason: '$value must not satisfy the release metadata contract',
        );
      }
    });
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

String _readDeclaredRelease(String pubspec) {
  final matches = RegExp(
    r'^\s*version:\s*(\S+)\s*$',
    multiLine: true,
  ).allMatches(pubspec).toList();

  if (matches.length != 1) {
    throw StateError(
      'Expected exactly one explicit version declaration; '
      'found ${matches.length}.',
    );
  }

  return matches.single.group(1)!;
}

_ReleaseMetadata _validateCurrentRelease(String value) {
  final metadata = _parseReleaseMetadata(value);
  if (metadata.major != 3) {
    throw StateError(
      'Expected a 3.x MovieDiary release; found ${metadata.major}.x.',
    );
  }
  if (metadata != _expectedReleaseMetadata) {
    throw StateError(
      'Release metadata changed without updating the test-owned contract: '
      '$value.',
    );
  }
  return metadata;
}

_ReleaseMetadata _parseReleaseMetadata(String value) {
  final match = RegExp(
    r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\+'
    r'([1-9][0-9]*)$',
  ).firstMatch(value);
  if (match == null) {
    throw FormatException(
      'Release metadata must be semantic version plus a positive build number.',
      value,
    );
  }

  return (
    major: int.parse(match.group(1)!),
    minor: int.parse(match.group(2)!),
    patch: int.parse(match.group(3)!),
    build: int.parse(match.group(4)!),
  );
}
