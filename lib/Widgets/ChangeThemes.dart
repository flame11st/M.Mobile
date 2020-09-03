import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Themes.dart';
import 'package:provider/provider.dart';

import 'Premium.dart';
import 'Providers/PurchaseState.dart';
import 'Providers/ThemeState.dart';
import 'Shared/MButton.dart';
import 'ThemePresentation.dart';

class ChangeThemes extends StatelessWidget {
  selectTheme(BuildContext context, int index) {
    final purchaseState = Provider.of<PurchaseState>(context);
    final themeState = Provider.of<ThemeState>(context);

    if (purchaseState.isPremium) {
      themeState.selectTheme(Themes.allThemes[index]);
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (ctx) => Premium()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themes = new List<Widget>();
    final themeState = Provider.of<ThemeState>(context);
    final purchaseState = Provider.of<PurchaseState>(context);

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
                    prependIcon: purchaseState.isPremium ? Icons.check : Icons.monetization_on,
                    prependIconColor: purchaseState.isPremium ? Theme.of(context).hintColor : Colors.green,
                    onPressedCallback: () => selectTheme(context, DefaultTabController.of(context1).index),
                    borderRadius: 25,
                    height: 50,
                    text: 'Select Theme ${purchaseState.isPremium ? '' : ' (Premium only)'}',
                    active: true,
                  ),
                )),
          );
        }));
  }
}
