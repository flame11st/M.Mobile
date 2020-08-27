import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Themes.dart';
import 'package:provider/provider.dart';

import 'Providers/ThemeState.dart';
import 'Shared/MButton.dart';
import 'ThemePresentation.dart';

class ChangeThemes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themes = new List<Widget>();
    final themeState = Provider.of<ThemeState>(context);

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

    return DefaultTabController(
        length: themes.length,
        child: Builder(builder: (BuildContext context1) {
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
                    TabPageSelector(),
                    Expanded(
                      child: TabBarView(children: themes),
                    )
                  ],
                )),
            bottomNavigationBar: BottomAppBar(
                color: Theme.of(context).primaryColor,
                child: Container(
                  margin: EdgeInsets.fromLTRB(10, 0, 10, 20),
                  child: MButton(
                    onPressedCallback: () {
                      var tabIndex = DefaultTabController.of(context1).index;

                      themeState.selectTheme(Themes.allThemes[tabIndex]);
                    },
                    borderRadius: 25,
                    height: 50,
                    text: 'Select Theme',
                    active: true,
                  ),
                )),
          );
        }));
  }
}
