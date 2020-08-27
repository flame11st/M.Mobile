import 'package:flutter/cupertino.dart';

import 'MColorTheme.dart';
import 'MTextStyleTheme.dart';

class MTheme {
    final MColorTheme colorTheme;
    final MTextStyleTheme textStyleTheme;
    final Brightness brightness;
    final String name;
    final int id;

    MTheme({this.id, this.name, this.colorTheme, this.textStyleTheme, this.brightness});
}