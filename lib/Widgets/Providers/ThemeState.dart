import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Objects/MTheme.dart';
import 'package:mmobile/Variables/Themes.dart';

class ThemeState with ChangeNotifier {
    final storage = new FlutterSecureStorage();
    MTheme selectedTheme = Themes.classicDark;

    selectTheme(MTheme theme) {
        if (theme != selectedTheme)
            selectedTheme = theme;

        notifyListeners();
    }
}