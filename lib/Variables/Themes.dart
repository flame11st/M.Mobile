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

  static final allThemes = [classicDark, classicLight];
}
