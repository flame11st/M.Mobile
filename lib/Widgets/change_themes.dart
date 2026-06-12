
import 'package:flutter/material.dart';
import 'package:mmobile/Variables/themes.dart';
import 'package:provider/provider.dart';
import 'premium.dart';
import 'Providers/theme_state.dart';
import 'Providers/user_state.dart';
import 'Shared/m_button.dart';
import 'theme_presentation.dart';

class ChangeThemes extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ChangeThemesState();
  }
}

class ChangeThemesState extends State<ChangeThemes>
    with SingleTickerProviderStateMixin {
  selectTheme(BuildContext context, TabController controller) {
    var index = controller.animation!.value.round();

    final userState = Provider.of<UserState>(context, listen: false);
    final themeState = Provider.of<ThemeState>(context, listen: false);

    if (userState.isPremium || index <= 1) {
      themeState.selectTheme(Themes.allThemes[index]);
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (ctx) => Premium()));
    }
  }

  int currentTabIndex = 0;
  TabController? _tabController;
  bool scrolledToCurrent = false;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(vsync: this, length: Themes.allThemes.length);

    _tabController!.addListener(setCurrentTabIndex);
  }

  @override
  void dispose() {
    _tabController!.dispose();

    super.dispose();
  }

  void setCurrentTabIndex() {
    setState(() {
      currentTabIndex = _tabController!.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> themes = [];
    final themeState = Provider.of<ThemeState>(context);
    final userState = Provider.of<UserState>(context);

    if (!scrolledToCurrent) {
      _tabController!.animateTo(Themes.allThemes.indexOf(themeState.selectedTheme));

      scrolledToCurrent = true;
    }


    for (final theme in Themes.allThemes) {
      themes.add(ThemePresentation(
        theme: theme,
        isCurrent: theme == themeState.selectedTheme,
      ));
    }

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          'Change Theme',
          style: Theme.of(context).textTheme.headlineSmall,
        )
      ],
    );

    return Builder(builder: (BuildContext context1) {
      return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          title: headingField,
        ),
        body: Container(
            padding: const EdgeInsets.fromLTRB(50, 0, 50, 20),
            child: Column(
              children: [
                TabPageSelector(
                  controller: _tabController,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: themes,
                  ),
                )
              ],
            )),
        bottomNavigationBar: BottomAppBar(
            color: Theme.of(context).primaryColor,
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
              child: MButton(
                prependIcon: userState.isPremium || currentTabIndex < 2
                    ? null
                    : Icons.monetization_on,
                prependIconColor: userState.isPremium || currentTabIndex < 2
                    ? Theme.of(context).hintColor
                    : Colors.green,
                onPressedCallback: () =>
                    selectTheme(context, _tabController!),
                borderRadius: 25,
                height: 50,
                text:
                    'Select Theme ${userState.isPremium || currentTabIndex < 2 ? '' : ' (Premium only)'}',
                active: true,
              ),
            )),
      );
    });
  }
}

