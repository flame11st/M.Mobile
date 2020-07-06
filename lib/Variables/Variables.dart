import 'package:flutter/cupertino.dart';

class MColors {
    static const PrimaryColor = Color(0xff222831);
    static const SecondaryColor = Color(0xff393e46);
    static const AdditionalColor = Color(0xff00adb5);
    static const FontsColor = Color(0xffeeeeee);
}

class MTextStyles {
    static const Title = TextStyle(fontSize: 15, fontWeight: FontWeight.bold,color: MColors.AdditionalColor);
    static const ExpandedTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: MColors.AdditionalColor);
    static const BodyText = TextStyle(fontSize: 14.0, color: MColors.FontsColor);
}