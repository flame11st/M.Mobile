import 'package:flutter/material.dart';

class FilterIcon extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final onPressedCallback;
  final bool? isActive;
  final double? textSize;
  final Color? iconColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const FilterIcon(
      {this.icon,
      this.text,
      this.onPressedCallback,
      this.isActive,
      this.textSize,
      this.iconColor,
      this.width,
      this.height,
      this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final color = isActive == true
        ? Theme.of(context).indicatorColor
        : Theme.of(context).cardColor;
    final fontColor = isActive == true
        ? Theme.of(context).primaryColor
        : Theme.of(context).hintColor;
    return GestureDetector(
        onTap: () => onPressedCallback(),
        child: Container(
            height: height ?? 50,
            width: width ?? 160,
            decoration: BoxDecoration(
              color: color,
              borderRadius: borderRadius ?? BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    offset: const Offset(0.0, 0.1),
                    blurRadius: 0.25),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                if (icon != null)
                  Icon(
                    icon,
                    size: 25,
                    color: iconColor ?? fontColor,
                  ),
                Text(
                  text!,
                  style: TextStyle(
                      color: fontColor,
                      fontSize: textSize ?? 15),
                )
              ],
            )));
  }
}
