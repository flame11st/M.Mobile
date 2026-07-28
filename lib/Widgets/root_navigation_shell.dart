import 'package:flutter/material.dart';

import 'movies_bottom_navigation_bar.dart';

class MovieDiaryRootNavigationShell extends StatefulWidget {
  final int selectedIndex;
  final List<Widget> tabs;
  final ValueChanged<int> onTabSelected;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;

  const MovieDiaryRootNavigationShell({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onTabSelected,
    this.appBar,
    this.resizeToAvoidBottomInset = false,
  }) : assert(tabs.length == 5);

  @override
  State<MovieDiaryRootNavigationShell> createState() =>
      _MovieDiaryRootNavigationShellState();
}

class _MovieDiaryRootNavigationShellState
    extends State<MovieDiaryRootNavigationShell> {
  final _pageStorageBucket = PageStorageBucket();

  void _handleBack(bool didPop) {
    if (didPop) {
      return;
    }

    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    if (widget.selectedIndex != 0) {
      widget.onTabSelected(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) => _handleBack(didPop),
      child: Scaffold(
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
        appBar: widget.appBar,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageStorage(
              bucket: _pageStorageBucket,
              child: IndexedStack(
                index: widget.selectedIndex,
                sizing: StackFit.expand,
                children: widget.tabs,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MoviesBottomNavigationBar(
                selectedIndex: widget.selectedIndex,
                onTabSelected: widget.onTabSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
