import 'package:flutter/cupertino.dart';

import 'MColorTheme.dart';
import 'MTextStyleTheme.dart';

class MTheme {
    final MColorTheme colorTheme;
    final MTextStyleTheme textStyleTheme;
    final Brightness brightness;

    MTheme({this.colorTheme, this.textStyleTheme, this.brightness});
}