import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

class MSnackBar {
  static showSnackBar(
    String text,
    bool isSuccess, {
    BuildContext? context,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    context ??= MyGlobals.activeKey?.currentContext;

    if (context != null) {
      show(context, text, isSuccess, duration: duration);
    }
  }

  static void show(
    BuildContext context,
    String text,
    bool isSuccess, {
    Duration duration = const Duration(milliseconds: 2500),
    double bottomMargin = 12,
  }) {
    showWithMessenger(
      ScaffoldMessenger.of(context),
      text,
      isSuccess,
      duration: duration,
      bottomMargin: bottomMargin,
    );
  }

  static void showWithMessenger(
    ScaffoldMessengerState messenger,
    String text,
    bool isSuccess, {
    Duration duration = const Duration(milliseconds: 2500),
    double bottomMargin = 12,
  }) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 40,
            maxWidth: 560,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        duration: duration,
        backgroundColor: isSuccess ? Md3Colors.success : Md3Colors.danger,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(12, 0, 12, bottomMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
