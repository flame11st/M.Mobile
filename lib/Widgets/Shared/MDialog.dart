import 'package:flutter/material.dart';
import 'MButton.dart';

class MDialog {
  final BuildContext context;
  final Widget content;
  final firstButtonText;
  final firstButtonCallback;
  final secondButtonText;
  final secondButtonCallback;

  MDialog(
      {this.firstButtonText,
      this.firstButtonCallback,
      this.secondButtonText,
      this.secondButtonCallback,
      required this.content,
      required this.context});

  openDialog() {
    showDialog<String>(
        context: context,
        builder: (BuildContext context1) => AlertDialog(
              backgroundColor: Theme.of(context).primaryColor,
              contentTextStyle: Theme.of(context).textTheme.headline5,
              content: content,
              actions: [
                MButton(
                  active: true,
                  text: firstButtonText,
                  parentContext: context,
                  onPressedCallback: () {
                    firstButtonCallback();

                    Navigator.of(context1).pop();
                  },
                ),
                SizedBox(
                  width: 10,
                ),
                if(secondButtonText != null)
                MButton(
                  active: true,
                  text: secondButtonText,
                  parentContext: context,
                  onPressedCallback: () {
                    secondButtonCallback();

                    Navigator.of(context1).pop();
                  },
                )
              ],
            ));
  }
}
