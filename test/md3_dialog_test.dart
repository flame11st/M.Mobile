import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Widgets/Shared/m_dialog.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dialog text and destructive action meet contrast requirements', () {
    expect(
      _contrastRatio(Md3Colors.text, Md3Colors.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(Md3Colors.muted, Md3Colors.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(Colors.white, Md3Colors.danger),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets(
    'confirmation dialog remains safe and readable across the target matrix',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final configurations = <(Size, double)>[
        (const Size(320, 568), 1),
        (const Size(320, 568), 1.3),
        (const Size(320, 568), 2),
        (const Size(430, 932), 1),
        (const Size(430, 932), 1.3),
        (const Size(430, 932), 2),
      ];

      for (final configuration in configurations) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(configuration.$1);
        await tester.pumpWidget(
          _dialogTestApp(
            textScale: configuration.$2,
            mediaSize: configuration.$1,
            onOpen: (context) => showMd3ConfirmationDialog(
              context: context,
              title: 'Remove “FilmClubs”?',
              body:
                  'The list will be deleted. Movies you watched will stay in Viewed.',
              confirmLabel: 'Remove list',
              onConfirm: () {},
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('openDialog')));
        await tester.pumpAndSettle();

        final dialogFinder = find.byKey(const Key('movieDiaryDialog'));
        expect(dialogFinder, findsOneWidget);
        expect(
          tester
              .getSize(find.byKey(const Key('movieDiaryDialogSurface')))
              .width,
          lessThanOrEqualTo(360),
        );
        expect(
          tester.widget<Dialog>(dialogFinder).backgroundColor,
          Md3Colors.surface,
        );

        final title = tester.widget<Text>(
          find.byKey(const Key('movieDiaryDialogTitle')),
        );
        final body = tester.widget<Text>(
          find.byKey(const Key('movieDiaryDialogBody')),
        );
        expect(title.style?.color, Md3Colors.text);
        expect(title.style?.fontSize, 22);
        expect(title.style?.fontWeight, FontWeight.w700);
        expect(body.style?.color, Md3Colors.muted);
        expect(body.style?.fontSize, 16);
        expect(body.style?.fontWeight, FontWeight.w500);

        final cancelFinder = find.byKey(const Key('movieDiaryDialogCancel'));
        final confirmFinder = find.byKey(const Key('movieDiaryDialogConfirm'));
        final dialogMediaQuery = MediaQuery.of(tester.element(confirmFinder));
        expect(tester.getSize(cancelFinder).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(confirmFinder).height, greaterThanOrEqualTo(48));
        expect(
          find.byKey(const Key('movieDiaryDialogStackedActions')),
          configuration.$1.width <= 360 || configuration.$2 >= 1.25
              ? findsOneWidget
              : findsNothing,
          reason: 'Unexpected action layout at ${configuration.$1} / '
              '${configuration.$2}x; dialog MediaQuery is '
              '${dialogMediaQuery.size} / '
              '${dialogMediaQuery.textScaler.scale(16) / 16}x.',
        );
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(confirmFinder);
        await tester.pumpAndSettle();
        final confirmRect = tester.getRect(confirmFinder);
        expect(confirmRect.top, greaterThanOrEqualTo(0));
        expect(confirmRect.bottom, lessThanOrEqualTo(configuration.$1.height));

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(dialogFinder, findsNothing);
      }
    },
  );

  testWidgets(
    'outside tap and back never execute the destructive callback',
    (tester) async {
      var confirmations = 0;
      await tester.pumpWidget(
        _dialogTestApp(
          onOpen: (context) => showMd3ConfirmationDialog(
            context: context,
            title: 'Clear your library?',
            body:
                'This removes every rating and Watchlist item. This can’t be undone.',
            confirmLabel: 'Clear library',
            onConfirm: () => confirmations += 1,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('openDialog')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pump();
      expect(find.byKey(const Key('movieDiaryDialog')), findsOneWidget);
      expect(confirmations, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('movieDiaryDialog')), findsNothing);
      expect(confirmations, 0);
    },
  );

  testWidgets(
    'in-flight action is single-fire and blocks dismissal until complete',
    (tester) async {
      final completion = Completer<void>();
      var confirmations = 0;
      await tester.pumpWidget(
        _dialogTestApp(
          onOpen: (context) => showMd3ConfirmationDialog(
            context: context,
            title: 'Delete your account?',
            body:
                'This deactivates your MovieDiary account and removes its saved ratings and Watchlist items. This can’t be undone.',
            confirmLabel: 'Delete account',
            onConfirm: () {
              confirmations += 1;
              return completion.future;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('openDialog')));
      await tester.pumpAndSettle();
      final confirmFinder = find.byKey(const Key('movieDiaryDialogConfirm'));
      await tester.tap(confirmFinder);
      await tester.pump();
      await tester.tap(confirmFinder, warnIfMissed: false);
      await tester.pump();

      expect(confirmations, 1);
      expect(
        find.byKey(const Key('movieDiaryDialogProgress')),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(confirmFinder).onPressed,
        isNull,
      );

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byKey(const Key('movieDiaryDialog')), findsOneWidget);

      completion.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('movieDiaryDialog')), findsNothing);
      expect(confirmations, 1);
    },
  );

  testWidgets(
    'input and error remain after a failed request with keyboard insets',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 568));
      var attempts = 0;

      await tester.pumpWidget(
        _dialogTestApp(
          textScale: 2,
          mediaSize: const Size(320, 568),
          viewInsets: const EdgeInsets.only(bottom: 220),
          onOpen: (context) => showMd3TextInputDialog(
            context: context,
            title: 'Rename list',
            body: 'Choose a clear name you’ll recognize in Personal lists.',
            fieldLabel: 'List name',
            initialValue: 'FilmClubs',
            confirmLabel: 'Save name',
            failureMessage: 'Couldn’t rename this list. Try again.',
            validator: (value) => value.isEmpty ? 'Enter a list name.' : null,
            onConfirm: (value) {
              attempts += 1;
              throw StateError('Simulated API failure');
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('openDialog')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('movieDiaryDialogInput')),
        'Cinema Club',
      );
      final confirmFinder = find.byKey(const Key('movieDiaryDialogConfirm'));
      await tester.ensureVisible(confirmFinder);
      await tester.pumpAndSettle();
      await tester.tap(confirmFinder);
      await tester.pumpAndSettle();

      expect(attempts, 1);
      expect(find.text('Cinema Club'), findsOneWidget);
      expect(
          find.text('Couldn’t rename this list. Try again.'), findsOneWidget);
      expect(find.byKey(const Key('movieDiaryDialog')), findsOneWidget);
      expect(tester.takeException(), isNull);

      final cancelFinder = find.byKey(const Key('movieDiaryDialogCancel'));
      await tester.ensureVisible(cancelFinder);
      await tester.pumpAndSettle();
      await tester.tap(cancelFinder);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('dialog goldens cover compact large text and standard width',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final configurations = <(Size, double, String)>[
      (
        const Size(320, 568),
        2,
        'goldens/uxr19-dialog-320x568-2x.png',
      ),
      (
        const Size(430, 932),
        1,
        'goldens/uxr19-dialog-430x932-1x.png',
      ),
    ];

    for (final configuration in configurations) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(configuration.$1);
      await tester.pumpWidget(
        _dialogTestApp(
          textScale: configuration.$2,
          mediaSize: configuration.$1,
          onOpen: (context) => showMd3ConfirmationDialog(
            context: context,
            title: 'Remove “FilmClubs”?',
            body:
                'The list will be deleted. Movies you watched will stay in Viewed.',
            confirmLabel: 'Remove list',
            onConfirm: () {},
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('openDialog')));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(configuration.$3),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
  });
}

Widget _dialogTestApp({
  required FutureOr<Object?> Function(BuildContext context) onOpen,
  double textScale = 1,
  Size? mediaSize,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  return MaterialApp(
    theme: MovieDiaryTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: mediaSize,
        textScaler: TextScaler.linear(textScale),
        viewInsets: viewInsets,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: FilledButton(
            key: const Key('openDialog'),
            onPressed: () => onOpen(context),
            child: const Text('Open dialog'),
          ),
        ),
      ),
    ),
  );
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
