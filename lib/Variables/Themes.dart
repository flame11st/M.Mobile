import 'package:flutter/material.dart';
import 'package:mmobile/Objects/MColorTheme.dart';
import 'package:mmobile/Objects/MTextStyleTheme.dart';
import 'package:mmobile/Objects/MTheme.dart';

class Themes {
  static final family = new MTheme(
      id: 0,
      name: 'Family',
      brightness: Brightness.light,
      colorTheme: MColorTheme(
        primaryColor: Color(0xfff8f8f8),
        secondaryColor: Color(0xffffffff),
        additionalColor: Color(0xff112d4e),
        fontsColor: Color(0xff222831),
      ),
      textStyleTheme: MTextStyleTheme(
        title: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff112d4e)),
        subtitleText: TextStyle(
            fontSize: 15.0,
            color: Color(0xff112d4e),
            fontWeight: FontWeight.bold),
        bodyText: TextStyle(fontSize: 15.0, color: Color(0xff222831)),
        expandedTitle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff112d4e)),
      ));

  static final MTheme scienceFiction = new MTheme(
      id: 1,
      name: 'Science Fiction',
      brightness: Brightness.dark,
      colorTheme: MColorTheme(
        primaryColor: Color(0xff232931),
        secondaryColor: Color(0xff252d3d),
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

  static final adventure = new MTheme(
      id: 2,
      name: 'Adventure',
      brightness: Brightness.light,
      colorTheme: MColorTheme(
        primaryColor: Color(0xff206a5d),
        secondaryColor: Color(0xff307a6d),
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

  static final MTheme comedy = new MTheme(
      id: 6,
      name: 'Comedy',
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

  static final noir = new MTheme(
      id: 4,
      name: 'Noir',
      brightness: Brightness.dark,
      colorTheme: MColorTheme(
        primaryColor: Color(0xff111111),
        secondaryColor: Color(0xff212121),
        additionalColor: Color(0xff67749c),
        fontsColor: Color(0xffe8ded2),
      ),
      textStyleTheme: MTextStyleTheme(
        title: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff67749c)),
        subtitleText: TextStyle(
            fontSize: 15.0,
            color: Color(0xff67749c),
            fontWeight: FontWeight.bold),
        bodyText: TextStyle(fontSize: 15.0, color: Color(0xffe8ded2)),
        expandedTitle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff67749c)),
      ));

  static final romance = new MTheme(
      id: 5,
      name: 'Romance',
      brightness: Brightness.light,
      colorTheme: MColorTheme(
        primaryColor: Color(0xffe6aec6),
        secondaryColor: Color(0xfff6bed6),
        additionalColor: Color(0xff0d7377),
        fontsColor: Color(0xff132743),
      ),
      textStyleTheme: MTextStyleTheme(
        title: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff0d7377)),
        subtitleText: TextStyle(
            fontSize: 15.0,
            color: Color(0xff0d7377),
            fontWeight: FontWeight.bold),
        bodyText: TextStyle(fontSize: 15.0, color: Color(0xff132743)),
        expandedTitle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff0d7377)),
      ));

  static final crime = new MTheme(
      id: 3,
      name: 'Crime',
      brightness: Brightness.dark,
      colorTheme: MColorTheme(
        primaryColor: Color(0xff161a2e),
        secondaryColor: Color(0xff212a3e),
        additionalColor: Color(0xffde4463),
        fontsColor: Color(0xffe8ded2),
      ),
      textStyleTheme: MTextStyleTheme(
        title: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xffde4463)),
        subtitleText: TextStyle(
            fontSize: 15.0,
            color: Color(0xffde4463),
            fontWeight: FontWeight.bold),
        bodyText: TextStyle(fontSize: 15.0, color: Color(0xffe8ded2)),
        expandedTitle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xffde4463)),
      ));

  static final allThemes = [
    family,
    scienceFiction,
    adventure,
    crime,
    noir,
    romance,
    comedy,
  ];
}
