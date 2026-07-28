import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/root_navigation_shell.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
    'five root tabs preserve state and expose selected tab semantics',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final moviesState = MoviesState();
      addTearDown(moviesState.dispose);
      await tester.pumpWidget(_testApp(moviesState));
      await tester.pump();

      expect(find.text('Discover root'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Lists'), findsOneWidget);

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('root-field-1')),
        'Matrix',
      );

      final searchSemantics = tester.getSemantics(
        find.byKey(const ValueKey('root-navigation-item-1')),
      );
      expect(
        searchSemantics.flagsCollection.isSelected,
        Tristate.isTrue,
      );

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings root'), findsOneWidget);

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(find.text('Matrix'), findsOneWidget);
      expect(find.text('Search reselected 0 times'), findsOneWidget);

      await tester.tap(find.text('Search'));
      await tester.pump();
      expect(find.text('Search reselected 1 time'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'detail back restores its root and system back returns to Discover',
    (tester) async {
      final moviesState = MoviesState();
      addTearDown(moviesState.dispose);
      await tester.pumpWidget(_testApp(moviesState));
      await tester.pump();

      await tester.tap(find.text('Lists'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('root-field-3')),
        'Weekend Picks',
      );
      await tester.tap(find.byKey(const Key('open-detail-3')));
      await tester.pumpAndSettle();

      expect(find.text('Lists detail'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('root-navigation-item-3')),
        findsNothing,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Lists root'), findsOneWidget);
      expect(find.text('Weekend Picks'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('root-navigation-item-3')),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discover root'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact text-scale layout keeps every root target at least 48 square',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final moviesState = MoviesState();
      addTearDown(moviesState.dispose);
      await tester.pumpWidget(
        _testApp(
          moviesState,
          mediaQueryData: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
        ),
      );
      await tester.pump();

      for (var index = 0; index < 5; index += 1) {
        final size = tester.getSize(
          find.byKey(ValueKey('root-navigation-item-$index')),
        );
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('content clearance includes an iPhone-style safe area',
      (tester) async {
    late double contentInset;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            viewPadding: EdgeInsets.only(bottom: 34),
          ),
          child: Builder(
            builder: (context) {
              contentInset = Md3NavigationMetrics.contentBottomInset(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(contentInset, 118);
  });
}

Widget _testApp(
  MoviesState moviesState, {
  MediaQueryData? mediaQueryData,
}) {
  return ChangeNotifierProvider<MoviesState>.value(
    value: moviesState,
    child: MaterialApp(
      home: mediaQueryData == null
          ? const _RootShellHarness()
          : MediaQuery(
              data: mediaQueryData,
              child: const _RootShellHarness(),
            ),
    ),
  );
}

class _RootShellHarness extends StatefulWidget {
  const _RootShellHarness();

  @override
  State<_RootShellHarness> createState() => _RootShellHarnessState();
}

class _RootShellHarnessState extends State<_RootShellHarness> {
  static const labels = [
    'Discover',
    'Search',
    'My Movies',
    'Lists',
    'Settings'
  ];

  int selectedIndex = 0;
  final reselectCounts = List<int>.filled(5, 0);

  void selectTab(int index) {
    setState(() {
      if (selectedIndex == index) {
        reselectCounts[index] += 1;
      } else {
        selectedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MovieDiaryRootNavigationShell(
      selectedIndex: selectedIndex,
      onTabSelected: selectTab,
      tabs: List<Widget>.generate(
        5,
        (index) => _PersistentTestTab(
          key: ValueKey('root-tab-$index'),
          index: index,
          label: labels[index],
          reselectCount: reselectCounts[index],
        ),
      ),
    );
  }
}

class _PersistentTestTab extends StatelessWidget {
  final int index;
  final String label;
  final int reselectCount;

  const _PersistentTestTab({
    super.key,
    required this.index,
    required this.label,
    required this.reselectCount,
  });

  @override
  Widget build(BuildContext context) {
    final suffix = reselectCount == 1 ? 'time' : 'times';
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            Text('$label root'),
            Text('$label reselected $reselectCount $suffix'),
            TextField(
              key: Key('root-field-$index'),
              decoration: InputDecoration(labelText: '$label state'),
            ),
            FilledButton(
              key: Key('open-detail-$index'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(),
                    body: Center(child: Text('$label detail')),
                  ),
                ),
              ),
              child: Text('Open $label detail'),
            ),
          ],
        ),
      ),
    );
  }
}
