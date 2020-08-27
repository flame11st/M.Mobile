import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Objects/MTheme.dart';
import 'package:mmobile/Variables/Themes.dart';

class ThemeState with ChangeNotifier {
    final storage = new FlutterSecureStorage();
    MTheme selectedTheme = Themes.classicDark;

    ThemeState() {
      initialSelectTheme();
    }

    initialSelectTheme() async {
      var storedThemeId;
      try{
        storedThemeId = await storage.read(key: 'themeId');
      } catch(on, ex) {
        await clearStorage();
      }

      if (storedThemeId != null && storedThemeId.isNotEmpty) {
        var theme = Themes.allThemes[int.parse(storedThemeId)];

        selectTheme(theme);
      }
    }

    selectTheme(MTheme theme) async {
        if (theme != selectedTheme)
            selectedTheme = theme;

        notifyListeners();

        await storage.write(key: 'themeId', value: theme.id.toString());
    }

    logout() async {
      await clearStorage();
      selectedTheme = Themes.classicDark;
    }

    clearStorage() async {
      await storage.delete(key: 'themeId');
    }
}