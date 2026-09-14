import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

class MSnackBar {
  static const actionDuration = Duration(seconds: 4);
  static const actionBottomMargin = 18.0;
  static const _accessibleActionDuration = Duration(days: 1);

  static ScaffoldMessengerState? _activeActionMessenger;
  static int? _activeActionGeneration;
  static int _generation = 0;

  static NavigatorObserver createNavigationObserver() {
    return _ActionFeedbackNavigationObserver();
  }

  static void clearActionFeedback() {
    final messenger = _activeActionMessenger;
    _activeActionMessenger = null;
    _activeActionGeneration = null;
    _generation += 1;
    if (messenger?.mounted ?? false) {
      messenger!.removeCurrentSnackBar(
        reason: SnackBarClosedReason.remove,
      );
    }
  }

  static double aboveRootNavigation(BuildContext context) {
    return Md3NavigationMetrics.contentBottomInset(context) + Md3Spacing.x16;
  }

  static showSnackBar(
    String text,
    bool isSuccess, {
    BuildContext? context,
    Duration duration = const Duration(milliseconds: 2500),
    String? actionLabel,
    VoidCallback? onAction,
    IconData? feedbackIcon,
    Color? feedbackIconColor,
    Color? feedbackIconBackgroundColor,
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
        feedbackIcon: feedbackIcon,
        feedbackIconColor: feedbackIconColor,
        feedbackIconBackgroundColor: feedbackIconBackgroundColor,
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
    IconData? feedbackIcon,
    Color? feedbackIconColor,
    Color? feedbackIconBackgroundColor,
  }) {
    showWithMessenger(
      ScaffoldMessenger.of(context),
      text,
      isSuccess,
      duration: duration,
      bottomMargin: bottomMargin,
      actionLabel: actionLabel,
      onAction: onAction,
      feedbackIcon: feedbackIcon,
      feedbackIconColor: feedbackIconColor,
      feedbackIconBackgroundColor: feedbackIconBackgroundColor,
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
    IconData? feedbackIcon,
    Color? feedbackIconColor,
    Color? feedbackIconBackgroundColor,
  }) {
    final hasAction = actionLabel != null && onAction != null;
    if (hasAction) {
      _showActionFeedback(
        messenger,
        text,
        duration: duration,
        bottomMargin: bottomMargin == 12 ? actionBottomMargin : bottomMargin,
        actionLabel: actionLabel,
        onAction: onAction,
        feedbackIcon: feedbackIcon,
        feedbackIconColor: feedbackIconColor,
        feedbackIconBackgroundColor: feedbackIconBackgroundColor,
      );
      return;
    }

    clearActionFeedback();
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
        backgroundColor: isSuccess ? Md3Colors.success : Md3Colors.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(12, 0, 12, bottomMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  static void _showActionFeedback(
    ScaffoldMessengerState messenger,
    String text, {
    required Duration duration,
    required double bottomMargin,
    required String actionLabel,
    required VoidCallback onAction,
    IconData? feedbackIcon,
    Color? feedbackIconColor,
    Color? feedbackIconBackgroundColor,
  }) {
    clearActionFeedback();
    messenger.removeCurrentSnackBar();

    final generation = ++_generation;
    var actionHandled = false;
    final accessibleNavigation =
        MediaQuery.maybeOf(messenger.context)?.accessibleNavigation ?? false;

    void close(
        {required bool immediate, required SnackBarClosedReason reason}) {
      if (_activeActionGeneration != generation) {
        return;
      }
      _activeActionMessenger = null;
      _activeActionGeneration = null;
      if (!messenger.mounted) {
        return;
      }
      if (immediate) {
        messenger.removeCurrentSnackBar(reason: reason);
      } else {
        messenger.hideCurrentSnackBar(reason: reason);
      }
    }

    final controller = messenger.showSnackBar(
      SnackBar(
        key: const Key('movie-diary-action-snackbar'),
        content: _ActionFeedbackContent(
          text: text,
          actionLabel: actionLabel,
          feedbackIcon: feedbackIcon,
          feedbackIconColor: feedbackIconColor,
          feedbackIconBackgroundColor: feedbackIconBackgroundColor,
          onAction: () {
            if (actionHandled) {
              return;
            }
            actionHandled = true;
            close(immediate: false, reason: SnackBarClosedReason.action);
            onAction();
          },
          onDismiss: () {
            close(immediate: false, reason: SnackBarClosedReason.dismiss);
          },
        ),
        duration: accessibleNavigation ? _accessibleActionDuration : duration,
        backgroundColor: Md3Colors.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: EdgeInsets.fromLTRB(20, 0, 20, bottomMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        dismissDirection: DismissDirection.horizontal,
      ),
    );

    _activeActionMessenger = messenger;
    _activeActionGeneration = generation;
    controller.closed.whenComplete(() {
      if (_activeActionGeneration == generation) {
        _activeActionMessenger = null;
        _activeActionGeneration = null;
      }
    });
  }
}

class _ActionFeedbackNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      MSnackBar.clearActionFeedback();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    MSnackBar.clearActionFeedback();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    MSnackBar.clearActionFeedback();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    MSnackBar.clearActionFeedback();
  }
}

class _ActionFeedbackContent extends StatelessWidget {
  const _ActionFeedbackContent({
    required this.text,
    required this.actionLabel,
    required this.onAction,
    required this.onDismiss,
    this.feedbackIcon,
    this.feedbackIconColor,
    this.feedbackIconBackgroundColor,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onDismiss;
  final IconData? feedbackIcon;
  final Color? feedbackIconColor;
  final Color? feedbackIconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: const Key('movie-diary-action-snackbar-content'),
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (feedbackIcon != null) ...[
            Container(
              key: const Key('movie-diary-action-snackbar-icon'),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: feedbackIconBackgroundColor ?? Md3Colors.primarySoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                feedbackIcon,
                size: 19,
                color: feedbackIconColor ?? Md3Colors.primary,
              ),
            ),
            const SizedBox(width: Md3Spacing.x8),
          ],
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: Md3Spacing.x4),
          TextButton(
            key: const Key('movie-diary-action-snackbar-undo'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: Md3Spacing.x8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
          Semantics(
            container: true,
            button: true,
            label: 'Dismiss notification',
            excludeSemantics: true,
            child: IconButton(
              key: const Key('movie-diary-action-snackbar-dismiss'),
              tooltip: 'Dismiss notification',
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              padding: EdgeInsets.zero,
              color: Colors.white,
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
