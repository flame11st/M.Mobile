import 'package:flutter/material.dart';

import 'movies_bottom_navigation_bar.dart';
import 'Shared/m_snack_bar.dart';

class MovieDiaryRootNavigationShell extends StatefulWidget {
  final int selectedIndex;
  final List<Widget> tabs;
  final ValueChanged<int> onTabSelected;
  final int backNavigationIndex;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;

  const MovieDiaryRootNavigationShell({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onTabSelected,
    this.backNavigationIndex = 0,
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

  void _selectTab(int index) {
    if (index != widget.selectedIndex) {
      MSnackBar.clearActionFeedback();
    }
    widget.onTabSelected(index);
  }

  void _handleBack(bool didPop) {
    if (didPop) {
      return;
    }

    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    if (widget.selectedIndex != 0) {
      _selectTab(widget.backNavigationIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final softwareKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      canPop: widget.selectedIndex == widget.backNavigationIndex,
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
            if (!softwareKeyboardVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MoviesBottomNavigationBar(
                  selectedIndex: widget.selectedIndex,
                  onTabSelected: _selectTab,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
