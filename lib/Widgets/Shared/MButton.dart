import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';

class MButton extends StatelessWidget {
  final String text;
  final onPressedCallback;
  final bool active;
  final double height;
  final double width;
  final double borderRadius;
  final prependIcon;
  final appendIcon;
  final prependImage;
  final Color prependIconColor;
  final BuildContext parentContext;

  MButton({
    this.text,
    this.onPressedCallback,
    this.active,
    this.height,
    this.width,
    this.prependIcon,
    this.prependImage,
    this.appendIcon,
    this.prependIconColor,
    this.borderRadius, this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final contextValue = parentContext != null ? parentContext : context;
    final color = Theme.of(contextValue).hintColor.withOpacity(active ? 1 : 0.3);

    return Container(
        width: width != null ? width : 110,
        alignment: Alignment.center,
        height: height != null ? height : 35,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              offset: Offset(0.0, 0.2),
              blurRadius: 0.4
            ),
          ],
          borderRadius: BorderRadius.circular(borderRadius != null ? borderRadius : 2.0),
          color: Theme.of(contextValue).cardColor.withOpacity(0.95),
        ),
        child: MaterialButton(
          padding: EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  borderRadius != null ? borderRadius : 8.0)),
          minWidth: MediaQuery.of(contextValue).size.width,
          height: MediaQuery.of(contextValue).size.height,
          onPressed: () => active ? onPressedCallback() : {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (prependIcon != null)
                Icon(
                  prependIcon,
                  size: 20,
                  color: prependIconColor != null ? prependIconColor : color,
                ),
              if (prependImage != null)
                Image(image: prependImage, height: 20.0),
              if (prependIcon != null || prependImage != null)
                SizedBox(
                  width: 10,
                ),
              Text(text, style: TextStyle(color: color, fontSize: 15)),
              if (appendIcon != null)
                SizedBox(
                  width: 10,
                ),
              if (appendIcon != null)
                Icon(
                  appendIcon,
                  size: 20,
                  color: color,
                ),
            ],
          ),
        ));
  }
}
