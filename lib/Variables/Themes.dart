import 'package:flutter/material.dart';
import 'package:mmobile/Objects/m_color_theme.dart';
import 'package:mmobile/Objects/m_text_style_theme.dart';
import 'package:mmobile/Objects/m_theme.dart';

class Themes {
  static final family = MTheme(
      id: 0,
      name: 'Family',
      brightness: Brightness.light,
      colorTheme: MColorTheme(
        primaryColor: const Color(0xfff8f8f8),
        secondaryColor: const Color(0xffffffff),
        additionalColor: const Color(0xff112d4e),
        fontsColor: const Color(0xff222831),
      ),
      textStyleTheme: MTextStyleTheme(
        title: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff112d4e)),
        subtitleText: const TextStyle(
            fontSize: 15.0,
            color: Color(0xff112d4e),
            fontWeight: FontWeight.bold),
        bodyText: const TextStyle(fontSize: 15.0, color: Color(0xff222831)),
        expandedTitle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff112d4e)),
      ));

  static final MTheme scienceFiction = MTheme(
      id: 1,
      name: 'Science Fiction',
      brightness: Brightness.dark,
      colorTheme: MColorTheme(
        primaryColor: const Color(0xff232931),
        secondaryColor: const Color(0xff252d3d),
        additionalColor: const Color(0xff00adb5),
        fontsColor: const Color(0xffeeeeee),
      ),
      textStyleTheme: MTextStyleTheme(
        title: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff00adb5)),
        subtitleText: const TextStyle(
            fontSize: 15.0,
            color: Color(0xff00adb5),
            fontWeight: FontWeight.bold),
        bodyText: const TextStyle(
            fontSize: 15.0,
            color: Color(0xffeeeeee),
            fontWeight: FontWeight.w500),
        expandedTitle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff00adb5)),
      ));

  static final adventure = MTheme(
      id: 2,
      name: 'Adventure',
      brightness: Brightness.light,
      colorTheme: MColorTheme(
        primaryColor: const Color(0xff206a5d),
        secondaryColor: const Color(0xff307a6d),
        additionalColor: const Color(0xfff1f1e8),
        fontsColor: const Color(0xffbfdcae),
      ),
      textStyleTheme: MTextStyleTheme(
        title: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xfff1f1e8)),
        subtitleText: const TextStyle(
            fontSize: 15.0,
            color: Color(0xfff1f1e8),
            fontWeight: FontWeight.bold),
        bodyText: const TextStyle(fontSize: 15.0, color: Color(0xffbfdcae)),
        expandedTitle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xfff1f1e8)),
      ));

  static final MTheme comedy = MTheme(
      id: 6,
      name: 'Comedy',
      brightness: Brightness.light,
      colorTheme: MColorTheme(
        primaryColor: const Color(0xff93b5e1),
        secondaryColor: const Color(0xff8dadd6),
        additionalColor: const Color(0xff0f4c75),
        fontsColor: const Color(0xff1b262c),
      ),
      textStyleTheme: MTextStyleTheme(
        title: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff0f4c75)),
        subtitleText: const TextStyle(
            fontSize: 15.0,
            color: Color(0xff0f4c75),
            fontWeight: FontWeight.bold),
        bodyText: const TextStyle(fontSize: 15.0, color: Color(0xff1b262c)),
        expandedTitle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff0f4c75)),
      ));

  static final noir = MTheme(
      id: 4,
      name: 'Noir',
      brightness: Brightness.dark,
      colorTheme: MColorTheme(
        primaryColor: const Color(0xff111111),
        secondaryColor: const Color(0xff212121),
        additionalColor: const Color(0xff67749c),
        fontsColor: const Color(0xffe8ded2),
      ),
      textStyleTheme: MTextStyleTheme(
        title: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff67749c)),
        subtitleText: const TextStyle(
            fontSize: 15.0,
            color: Color(0xff67749c),
            fontWeight: FontWeight.bold),
        bodyText: const TextStyle(fontSize: 15.0, color: Color(0xffe8ded2)),
        expandedTitle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff67749c)),
      ));

  static final romance = MTheme(
      id: 5,
      name: 'Romance',
      brightness: Brightness.light,
      colorTheme: MColorTheme(
        primaryColor: const Color(0xffe6aec6),
        secondaryColor: const Color(0xfff6bed6),
        additionalColor: const Color(0xff0d7377),
        fontsColor: const Color(0xff132743),
      ),
      textStyleTheme: MTextStyleTheme(
        title: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xff0d7377)),
        subtitleText: const TextStyle(
            fontSize: 15.0,
            color: Color(0xff0d7377),
            fontWeight: FontWeight.bold),
        bodyText: const TextStyle(fontSize: 15.0, color: Color(0xff132743)),
        expandedTitle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff0d7377)),
      ));

  static final crime = MTheme(
      id: 3,
      name: 'Crime',
      brightness: Brightness.dark,
      colorTheme: MColorTheme(
        primaryColor: const Color(0xff161a2e),
        secondaryColor: const Color(0xff212a3e),
        additionalColor: const Color(0xffde4463),
        fontsColor: const Color(0xffe8ded2),
      ),
      textStyleTheme: MTextStyleTheme(
        title: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xffde4463)),
        subtitleText: const TextStyle(
            fontSize: 15.0,
            color: Color(0xffde4463),
            fontWeight: FontWeight.bold),
        bodyText: const TextStyle(fontSize: 15.0, color: Color(0xffe8ded2)),
        expandedTitle: const TextStyle(
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

