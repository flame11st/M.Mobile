import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//
//class MColors {
//    static const PrimaryColor = Color(0xff222831);
//    static const SecondaryColor = Color(0xff393e46);
//    static const AdditionalColor = Color(0xff00adb5);
//    static const FontsColor = Color(0xffeeeeee);
//}

class MColors {
  static const PrimaryColor = Color(0xff232931);
  static const SecondaryColor = Color(0xff343a42);
  static const AdditionalColor = Color(0xff00adb5);
  static const FontsColor = Color(0xffeeeeee);
  static const SecondaryFontsColor = Color(0xff00adb5);
}

class MTextStyles {
  static const TabTitle = TextStyle(
      fontSize: 18,
      color: MColors.FontsColor);
  static const Title = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: MColors.AdditionalColor);
  static const ExpandedTitle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: MColors.AdditionalColor);
  static const BodyText = TextStyle(fontSize: 15.0, color: MColors.FontsColor);
  static const SubtitleText = TextStyle(
      fontSize: 15.0,
      color: MColors.SecondaryFontsColor,
      fontWeight: FontWeight.bold);
}

class MyGlobals {
  static GlobalKey scaffoldKey;
  static GlobalKey scaffoldSettingsKey;
  static GlobalKey scaffoldLoginKey;
  static GlobalKey scaffoldSignUpKey;
}
