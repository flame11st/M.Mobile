import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Themes.dart';
import 'package:provider/provider.dart';
import 'Premium.dart';
import 'Providers/ThemeState.dart';
import 'Providers/UserState.dart';
import 'Shared/MButton.dart';
import 'ThemePresentation.dart';

class ChangeThemes extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ChangeThemesState();
  }
}

class ChangeThemesState extends State<ChangeThemes>
    with SingleTickerProviderStateMixin {
  selectTheme(BuildContext context, int index) {
    final userState = Provider.of<UserState>(context);
    final themeState = Provider.of<ThemeState>(context);

    if (userState.isPremium || currentTabIndex < 2) {
      themeState.selectTheme(Themes.allThemes[index]);
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (ctx) => Premium()));
    }
  }

  int currentTabIndex = 0;
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        new TabController(vsync: this, length: Themes.allThemes.length);

    _tabController.addListener(setCurrentTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  void setCurrentTabIndex() {
    setState(() {
      currentTabIndex = _tabController.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themes = new List<Widget>();
    final themeState = Provider.of<ThemeState>(context);
    final userState = Provider.of<UserState>(context);

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
          style: Theme.of(context).textTheme.headline5,
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
            padding: EdgeInsets.fromLTRB(50, 0, 50, 20),
//                  key: MyGlobals.scaffoldSettingsKey,
            child: Column(
              children: [
                TabPageSelector(
                  controller: _tabController,
                ),
                Expanded(
                  child: TabBarView(
                    children: themes,
                    controller: _tabController,
                  ),
                )
              ],
            )),
        bottomNavigationBar: BottomAppBar(
            color: Theme.of(context).primaryColor,
            child: Container(
              margin: EdgeInsets.fromLTRB(10, 0, 10, 20),
              child: MButton(
                prependIcon: userState.isPremium || currentTabIndex < 2
                    ? null
                    : Icons.monetization_on,
                prependIconColor: userState.isPremium || currentTabIndex < 2
                    ? Theme.of(context).hintColor
                    : Colors.green,
                onPressedCallback: () =>
                    selectTheme(context, _tabController.index),
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
