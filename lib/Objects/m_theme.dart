import 'package:flutter/cupertino.dart';

import 'm_color_theme.dart';
import 'm_text_style_theme.dart';

class MTheme {
  final MColorTheme colorTheme;
  final MTextStyleTheme textStyleTheme;
  final Brightness brightness;
  final String name;
  final int id;

  MTheme(
      {required this.id,
      required this.name,
      required this.colorTheme,
      required this.textStyleTheme,
      required this.brightness});
}

