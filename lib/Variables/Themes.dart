import 'package:flutter/material.dart';
import 'package:mmobile/Objects/MColorTheme.dart';
import 'package:mmobile/Objects/MTextStyleTheme.dart';
import 'package:mmobile/Objects/MTheme.dart';

class Themes {
  static final MTheme classicDark = new MTheme(
      id: 0,
      name: 'Classic Dark',
      brightness: Brightness.dark,
      colorTheme: MColorTheme(
        primaryColor: Color(0xff232931),
        secondaryColor: Color(0xff252D37),
        additionalColor: Color(0xff00adb5),
        fontsColor: Color(0xffeeeeee),
      ),
      textStyleTheme: MTextStyleTheme(
        title: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff00adb5)),
        subtitleText: TextStyle(
            fontSize: 15.0,
            color: Color(0xff00adb5),
            fontWeight: FontWeight.bold),
        bodyText: TextStyle(
            fontSize: 15.0,
            color: Color(0xffeeeeee),
            fontWeight: FontWeight.w500),
        expandedTitle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff00adb5)),
      ));

  static final MTheme classicLight = new MTheme(
      id: 1,
      name: 'Classic Light',
      brightness: Brightness.light,
      colorTheme: MColorTheme(
        primaryColor: Color(0xff93b5e1),
        secondaryColor: Color(0xff8dadd6),
        additionalColor: Color(0xff0f4c75),
        fontsColor: Color(0xff1b262c),
      ),
      textStyleTheme: MTextStyleTheme(
        title: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff0f4c75)),
        subtitleText: TextStyle(
            fontSize: 15.0,
            color: Color(0xff0f4c75),
            fontWeight: FontWeight.bold),
        bodyText: TextStyle(fontSize: 15.0, color: Color(0xff1b262c)),
        expandedTitle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff0f4c75)),
      ));

  static final cream = new MTheme(
      id: 2,
      name: 'Cream',
      brightness: Brightness.dark,
      colorTheme: MColorTheme(
        primaryColor: Color(0xffdee3e2),
        secondaryColor: Color(0xffdfe3ea),
        additionalColor: Color(0xff3e206d),
        fontsColor: Color(0xff000000),
      ),
      textStyleTheme: MTextStyleTheme(
        title: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff3e206d)),
        subtitleText: TextStyle(
            fontSize: 15.0,
            color: Color(0xff3e206d),
            fontWeight: FontWeight.bold),
        bodyText: TextStyle(fontSize: 15.0, color: Color(0xff000000)),
        expandedTitle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff3e206d)),
      ));

  static final noir = new MTheme(
      id: 3,
      name: 'Noir',
      brightness: Brightness.dark,
      colorTheme: MColorTheme(
        primaryColor: Color(0xff111111),
        secondaryColor: Color(0xff111111),
        additionalColor: Color(0xffeeeeee),
        fontsColor: Color(0xffe8ded2),
      ),
      textStyleTheme: MTextStyleTheme(
        title: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xffeeeeee)),
        subtitleText: TextStyle(
            fontSize: 15.0,
            color: Color(0xffeeeeee),
            fontWeight: FontWeight.bold),
        bodyText: TextStyle(fontSize: 15.0, color: Color(0xffe8ded2)),
        expandedTitle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xffeeeeee)),
      ));

  static final danger = new MTheme(
      id: 4,
      name: 'Danger',
      brightness: Brightness.dark,
      colorTheme: MColorTheme(
        primaryColor: Color(0xffd92027),
        secondaryColor: Color(0xffd12027),
        additionalColor: Color(0xfff7f7f7),
        fontsColor: Color(0xffe8ded2),
      ),
      textStyleTheme: MTextStyleTheme(
        title: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xfff7f7f7)),
        subtitleText: TextStyle(
            fontSize: 15.0,
            color: Color(0xfff7f7f7),
            fontWeight: FontWeight.bold),
        bodyText: TextStyle(fontSize: 15.0, color: Color(0xffe8ded2)),
        expandedTitle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xfff7f7f7)),
      ));

  static final night = new MTheme(
      id: 5,
      name: 'Night',
      brightness: Brightness.dark,
      colorTheme: MColorTheme(
        primaryColor: Color(0xff1a1a2e),
        secondaryColor: Color(0xff161a2e),
        additionalColor: Color(0xff40a8c4),
        fontsColor: Color(0xffe8ded2),
      ),
      textStyleTheme: MTextStyleTheme(
        title: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff40a8c4)),
        subtitleText: TextStyle(
            fontSize: 15.0,
            color: Color(0xff40a8c4),
            fontWeight: FontWeight.bold),
        bodyText: TextStyle(fontSize: 15.0, color: Color(0xffe8ded2)),
        expandedTitle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff40a8c4)),
      ));

  static final nature = new MTheme(
      id: 6,
      name: 'Nature',
      brightness: Brightness.light,
      colorTheme: MColorTheme(
        primaryColor: Color(0xff206a5d),
        secondaryColor: Color(0xff20715d),
        additionalColor: Color(0xfff1f1e8),
        fontsColor: Color(0xffbfdcae),
      ),
      textStyleTheme: MTextStyleTheme(
        title: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xfff1f1e8)),
        subtitleText: TextStyle(
            fontSize: 15.0,
            color: Color(0xfff1f1e8),
            fontWeight: FontWeight.bold),
        bodyText: TextStyle(fontSize: 15.0, color: Color(0xffbfdcae)),
        expandedTitle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xfff1f1e8)),
      ));

  static final allThemes = [
    classicDark,
    classicLight,
    cream,
    noir,
    danger,
    night,
    nature
  ];
}
