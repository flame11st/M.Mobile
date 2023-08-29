import 'package:flutter/cupertino.dart';

import 'MColorTheme.dart';
import 'MTextStyleTheme.dart';

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
