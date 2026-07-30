import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

typedef Md3DialogCallback = FutureOr<void> Function();
typedef Md3DialogValueCallback = FutureOr<void> Function(String value);

const _dialogRadius = 28.0;
const _dialogHorizontalInset = 24.0;
const _dialogContentPadding = 24.0;
const _dialogActionGap = 8.0;
const _dialogActionHeight = 48.0;

Future<bool> showMd3ConfirmationDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String confirmLabel,
  required Md3DialogCallback onConfirm,
  String cancelLabel = 'Cancel',
  bool destructive = true,
  String failureMessage =
      'Couldn’t complete this action. Check your connection and try again.',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useSafeArea: true,
    builder: (dialogContext) => _Md3ConfirmationDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      failureMessage: failureMessage,
      onConfirm: onConfirm,
    ),
  );

  return confirmed == true;
}

Future<String?> showMd3TextInputDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String fieldLabel,
  required String confirmLabel,
  required Md3DialogValueCallback onConfirm,
  String cancelLabel = 'Cancel',
  String initialValue = '',
  String? Function(String value)? validator,
  bool destructive = false,
  int maxLines = 1,
  TextInputType? keyboardType,
  String failureMessage =
      'Couldn’t complete this action. Check your connection and try again.',
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    useSafeArea: true,
    builder: (dialogContext) => _Md3TextInputDialog(
      title: title,
      body: body,
      fieldLabel: fieldLabel,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      initialValue: initialValue,
      validator: validator,
      destructive: destructive,
      maxLines: maxLines,
      keyboardType: keyboardType,
      failureMessage: failureMessage,
      onConfirm: onConfirm,
    ),
  );
}

class _Md3ConfirmationDialog extends StatefulWidget {
  const _Md3ConfirmationDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    required this.failureMessage,
    required this.onConfirm,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final String failureMessage;
  final Md3DialogCallback onConfirm;

  @override
  State<_Md3ConfirmationDialog> createState() => _Md3ConfirmationDialogState();
}

class _Md3ConfirmationDialogState extends State<_Md3ConfirmationDialog> {
  bool _isSubmitting = false;
  String? _error;

  Future<void> _confirm() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onConfirm();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = widget.failureMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: _Md3DialogFrame(
        title: widget.title,
        body: widget.body,
        error: _error,
        actions: _Md3DialogActions(
          cancelLabel: widget.cancelLabel,
          confirmLabel: widget.confirmLabel,
          destructive: widget.destructive,
          isSubmitting: _isSubmitting,
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: _confirm,
        ),
      ),
    );
  }
}

class _Md3TextInputDialog extends StatefulWidget {
  const _Md3TextInputDialog({
    required this.title,
    required this.body,
    required this.fieldLabel,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.initialValue,
    required this.validator,
    required this.destructive,
    required this.maxLines,
    required this.keyboardType,
    required this.failureMessage,
    required this.onConfirm,
  });

  final String title;
  final String body;
  final String fieldLabel;
  final String confirmLabel;
  final String cancelLabel;
  final String initialValue;
  final String? Function(String value)? validator;
  final bool destructive;
  final int maxLines;
  final TextInputType? keyboardType;
  final String failureMessage;
  final Md3DialogValueCallback onConfirm;

  @override
  State<_Md3TextInputDialog> createState() => _Md3TextInputDialogState();
}

class _Md3TextInputDialogState extends State<_Md3TextInputDialog> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;
  String? _validationError;
  String? _requestError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isSubmitting) {
      return;
    }

    final value = _controller.text.trim();
    final validationError = widget.validator?.call(value);
    if (validationError != null) {
      setState(() {
        _validationError = validationError;
        _requestError = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _validationError = null;
      _requestError = null;
    });

    try {
      await widget.onConfirm(value);
      if (mounted) {
        Navigator.of(context).pop(value);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _requestError = widget.failureMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: _Md3DialogFrame(
        title: widget.title,
        body: widget.body,
        error: _requestError,
        content: TextField(
          key: const Key('movieDiaryDialogInput'),
          controller: _controller,
          autofocus: true,
          enabled: !_isSubmitting,
          minLines: 1,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          textInputAction: widget.maxLines == 1
              ? TextInputAction.done
              : TextInputAction.newline,
          scrollPadding: const EdgeInsets.only(bottom: 120),
          onChanged: (_) {
            if (_validationError != null || _requestError != null) {
              setState(() {
                _validationError = null;
                _requestError = null;
              });
            }
          },
          onSubmitted:
              widget.maxLines == 1 && !_isSubmitting ? (_) => _confirm() : null,
          style: const TextStyle(
            color: Md3Colors.text,
            fontSize: 16,
            height: 23 / 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: widget.fieldLabel,
            errorText: _validationError,
          ),
        ),
        actions: _Md3DialogActions(
          cancelLabel: widget.cancelLabel,
          confirmLabel: widget.confirmLabel,
          destructive: widget.destructive,
          isSubmitting: _isSubmitting,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: _confirm,
        ),
      ),
    );
  }
}

class _Md3DialogFrame extends StatelessWidget {
  const _Md3DialogFrame({
    required this.title,
    required this.body,
    required this.actions,
    this.content,
    this.error,
  });

  final String title;
  final String body;
  final Widget actions;
  final Widget? content;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maximumHeight = math.max(
      240.0,
      mediaQuery.size.height -
          mediaQuery.padding.vertical -
          mediaQuery.viewInsets.bottom -
          48,
    );

    return Dialog(
      key: const Key('movieDiaryDialog'),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: _dialogHorizontalInset,
        vertical: 24,
      ),
      elevation: 6,
      shadowColor: const Color(0x14172231),
      surfaceTintColor: Colors.transparent,
      backgroundColor: Md3Colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_dialogRadius),
        side: const BorderSide(color: Md3Colors.border),
      ),
      child: ConstrainedBox(
        key: const Key('movieDiaryDialogSurface'),
        constraints: BoxConstraints(
          maxWidth: 360,
          maxHeight: maximumHeight,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_dialogContentPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                namesRoute: true,
                header: true,
                child: Text(
                  title,
                  key: const Key('movieDiaryDialogTitle'),
                  style: const TextStyle(
                    color: Md3Colors.text,
                    fontSize: 22,
                    height: 27 / 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                key: const Key('movieDiaryDialogBody'),
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 16,
                  height: 23 / 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (content != null) ...[
                const SizedBox(height: 16),
                content!,
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error!,
                    key: const Key('movieDiaryDialogError'),
                    style: const TextStyle(
                      color: Md3Colors.danger,
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _Md3DialogActions extends StatelessWidget {
  const _Md3DialogActions({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.destructive,
    required this.isSubmitting,
    required this.onCancel,
    required this.onConfirm,
  });

  final String cancelLabel;
  final String confirmLabel;
  final bool destructive;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final effectiveTextScale = mediaQuery.textScaler.scale(16) / 16;
    final stackActions =
        mediaQuery.size.width <= 360 || effectiveTextScale >= 1.25;
    final cancel = OutlinedButton(
      key: const Key('movieDiaryDialogCancel'),
      onPressed: isSubmitting ? null : onCancel,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, _dialogActionHeight),
        foregroundColor: Md3Colors.primary,
        disabledForegroundColor: Md3Colors.muted,
        side: const BorderSide(color: Md3Colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(cancelLabel),
    );
    final confirm = FilledButton(
      key: const Key('movieDiaryDialogConfirm'),
      onPressed: isSubmitting ? null : onConfirm,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(44, _dialogActionHeight),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Md3Colors.border;
          }
          return destructive ? Md3Colors.danger : Md3Colors.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Md3Colors.muted;
          }
          return Colors.white;
        }),
        overlayColor: const WidgetStatePropertyAll(Color(0x1f000000)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: isSubmitting
            ? Semantics(
                key: const Key('movieDiaryDialogProgress'),
                liveRegion: true,
                label: '$confirmLabel in progress',
                child: const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Md3Colors.muted,
                  ),
                ),
              )
            : Text(
                confirmLabel,
                key: const Key('movieDiaryDialogConfirmLabel'),
              ),
      ),
    );

    if (stackActions) {
      return Column(
        key: const Key('movieDiaryDialogStackedActions'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cancel,
          const SizedBox(height: _dialogActionGap),
          confirm,
        ],
      );
    }

    return Row(
      key: const Key('movieDiaryDialogInlineActions'),
      children: [
        Expanded(child: cancel),
        const SizedBox(width: _dialogActionGap),
        Expanded(child: confirm),
      ],
    );
  }
}
