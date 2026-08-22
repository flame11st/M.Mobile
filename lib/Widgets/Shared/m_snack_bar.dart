import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

class MSnackBar {
  static showSnackBar(
    String text,
    bool isSuccess, {
    BuildContext? context,
    Duration duration = const Duration(milliseconds: 2500),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    context ??= MyGlobals.activeKey?.currentContext;

    if (context != null) {
      show(
        context,
        text,
        isSuccess,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    }
  }

  static void show(
    BuildContext context,
    String text,
    bool isSuccess, {
    Duration duration = const Duration(milliseconds: 2500),
    double bottomMargin = 12,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showWithMessenger(
      ScaffoldMessenger.of(context),
      text,
      isSuccess,
      duration: duration,
      bottomMargin: bottomMargin,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showWithMessenger(
    ScaffoldMessengerState messenger,
    String text,
    bool isSuccess, {
    Duration duration = const Duration(milliseconds: 2500),
    double bottomMargin = 12,
    String? actionLabel,
    VoidCallback? onAction,
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
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              ),
        backgroundColor: isSuccess ? Md3Colors.success : Md3Colors.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(12, 0, 12, bottomMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
