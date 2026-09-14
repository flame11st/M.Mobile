import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mmobile/Widgets/Shared/md3_colors.dart';

export 'package:mmobile/Widgets/Shared/md3_colors.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Services/service_agent.dart';

/// MovieDiary's 4-point-compatible spacing scale.
///
/// Prefer the semantic aliases for page, card, control, and section layout;
/// the numeric scale remains available for component-specific geometry.
class Md3Spacing {
  const Md3Spacing._();

  static const double x4 = 4;
  static const double x8 = 8;
  static const double x12 = 12;
  static const double x16 = 16;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x32 = 32;
  static const double x40 = 40;
  static const double x48 = 48;

  static const double screenCompact = x16;
  static const double screen = x24;
  static const double cardCompact = x16;
  static const double card = x20;
  static const double controlGap = x12;
  static const double sectionGap = x32;
}

/// Shape roles shared by controls and surfaces.
class Md3Radius {
  const Md3Radius._();

  static const double small = 8;
  static const double medium = 12;
  static const double input = 16;
  static const double poster = 16;
  static const double button = 20;
  static const double navigationSelection = 22;
  static const double card = 24;
  static const double navigation = 28;
  static const double sheet = 32;
  static const double pill = 999;
}

/// Minimum interactive geometry. Primary controls use 48; compact controls
/// may use 44 when their surrounding layout remains fully tappable.
class Md3Targets {
  const Md3Targets._();

  static const double minimum = 44;
  static const double primary = 48;
}

/// Type roles used by the app theme and shared components.
class Md3Typography {
  const Md3Typography._();

  static const pageTitle = TextStyle(
    color: Md3Colors.text,
    fontSize: 34,
    height: 41 / 34,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static const pageTitleCompact = TextStyle(
    color: Md3Colors.text,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static const sectionTitle = TextStyle(
    color: Md3Colors.text,
    fontSize: 24,
    height: 29 / 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static const sectionTitleCompact = TextStyle(
    color: Md3Colors.text,
    fontSize: 22,
    height: 27 / 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static const cardTitle = TextStyle(
    color: Md3Colors.text,
    fontSize: 20,
    height: 25 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const title = TextStyle(
    color: Md3Colors.text,
    fontSize: 16,
    height: 23 / 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const titleCompact = TextStyle(
    color: Md3Colors.text,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const body = TextStyle(
    color: Md3Colors.text,
    fontSize: 16,
    height: 23 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const bodyCompact = TextStyle(
    color: Md3Colors.text,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const metadata = TextStyle(
    color: Md3Colors.muted,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const label = TextStyle(
    color: Md3Colors.text,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const labelCompact = TextStyle(
    color: Md3Colors.text,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const navigationLabel = TextStyle(
    color: Md3Colors.muted,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
}

/// Restrained depth roles. Content cards stay opaque and use `contentCard`;
/// glass shadows are reserved for navigation, filters, and sticky actions.
class Md3Shadows {
  const Md3Shadows._();

  static const contentCardColor = Color(0x14172231);
  static const contentCard = <BoxShadow>[
    BoxShadow(color: contentCardColor, blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const sheet = <BoxShadow>[
    BoxShadow(color: Color(0x260f253d), blurRadius: 24, offset: Offset(0, 12)),
  ];
  static const glass = <BoxShadow>[
    BoxShadow(color: Color(0x160f253d), blurRadius: 24, offset: Offset(0, 10)),
  ];
  static const navigation = <BoxShadow>[
    BoxShadow(color: Color(0x18102a43), blurRadius: 22, offset: Offset(0, 10)),
  ];
  static const navigationSelection = <BoxShadow>[
    BoxShadow(color: Color(0x0f4d55d9), blurRadius: 8, offset: Offset(0, 3)),
  ];
}

/// Motion timing roles. Components must resolve these to [Duration.zero]
/// when reduced motion is requested.
class Md3Durations {
  const Md3Durations._();

  static const quick = Duration(milliseconds: 120);
  static const feedback = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 180);
  static const emphasis = Duration(milliseconds: 240);
  static const shimmer = Duration(milliseconds: 1200);
}

class MovieDiaryTheme {
  // Reserved for future dark-theme support. Theme switching stays disabled;
  // the app mounts light() regardless of the system brightness.
  static const darkColorScheme = ColorScheme.dark(
    primary: Color(0xffaeb3ff),
    onPrimary: Color(0xff20246c),
    primaryContainer: Color(0xff383faf),
    onPrimaryContainer: Color(0xffeeefff),
    secondary: Md3Colors.accent,
    onSecondary: Md3Colors.text,
    surface: Color(0xff181b28),
    onSurface: Color(0xffeef0f8),
    onSurfaceVariant: Color(0xffb9c1d4),
    error: Color(0xffffa7a7),
    onError: Color(0xff5b1515),
    outline: Color(0xff8993ac),
  );

  static ButtonStyle primaryButtonStyle({bool tonal = false}) => ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return Md3Colors.primaryDisabled;
      }
      if (states.contains(WidgetState.pressed)) {
        return tonal ? Md3Colors.primarySoftStrong : Md3Colors.primaryStrong;
      }
      return tonal ? Md3Colors.primarySoft : Md3Colors.primary;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return Md3Colors.muted;
      return tonal ? Md3Colors.primaryStrong : Colors.white;
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused) ||
          states.contains(WidgetState.hovered)) {
        return (tonal ? Md3Colors.primary : Colors.white).withValues(
          alpha: .08,
        );
      }
      return Colors.transparent;
    }),
  );

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: Md3Colors.primary,
      onPrimary: Colors.white,
      primaryContainer: Md3Colors.primarySoft,
      onPrimaryContainer: Md3Colors.primary,
      secondary: Md3Colors.accent,
      onSecondary: Md3Colors.text,
      surface: Md3Colors.surface,
      onSurface: Md3Colors.text,
      onSurfaceVariant: Md3Colors.muted,
      error: Md3Colors.error,
      onError: Colors.white,
      outline: Md3Colors.border,
      shadow: Md3Shadows.contentCardColor,
    );
    const textTheme = TextTheme(
      displayLarge: Md3Typography.pageTitle,
      displayMedium: Md3Typography.pageTitle,
      displaySmall: Md3Typography.pageTitleCompact,
      headlineLarge: Md3Typography.sectionTitle,
      headlineMedium: Md3Typography.sectionTitle,
      headlineSmall: Md3Typography.sectionTitleCompact,
      titleLarge: Md3Typography.cardTitle,
      titleMedium: Md3Typography.title,
      titleSmall: Md3Typography.titleCompact,
      bodyLarge: Md3Typography.body,
      bodyMedium: Md3Typography.bodyCompact,
      bodySmall: Md3Typography.metadata,
      labelLarge: Md3Typography.label,
      labelMedium: Md3Typography.labelCompact,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Md3Colors.background,
      canvasColor: Md3Colors.background,
      cardColor: Md3Colors.surface,
      dividerColor: Md3Colors.border,
      splashFactory: InkRipple.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: Md3Colors.text),
      appBarTheme: const AppBarTheme(
        backgroundColor: Md3Colors.background,
        foregroundColor: Md3Colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: Md3Typography.cardTitle,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.square(Md3Targets.primary),
          backgroundColor: Md3Colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Md3Radius.button),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ).merge(primaryButtonStyle()),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.square(Md3Targets.primary),
          foregroundColor: Md3Colors.primary,
          side: const BorderSide(color: Md3Colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Md3Radius.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.square(Md3Targets.minimum),
          foregroundColor: Md3Colors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Md3Colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Md3Spacing.x16,
          vertical: Md3Spacing.x12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Md3Radius.input),
          borderSide: const BorderSide(color: Md3Colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Md3Radius.input),
          borderSide: const BorderSide(color: Md3Colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Md3Radius.input),
          borderSide: const BorderSide(color: Md3Colors.primary, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Md3Colors.border,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Md3Colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Md3Colors.primary,
        linearTrackColor: Md3Colors.surfaceMuted,
        circularTrackColor: Md3Colors.surfaceMuted,
      ),
    );
  }
}

class Md3Layout {
  static double pageHorizontalInset(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 600
        ? Md3Spacing.screen
        : Md3Spacing.screenCompact;
  }
}

class Md3NavigationMetrics {
  static const double dockHeight = 64;
  static const double visibleDockHeight = dockHeight + 2;
  static const double minimumBottomMargin = Md3Spacing.x8;
  static const double contentClearance = Md3Spacing.x12;
  static const double horizontalMargin = Md3Spacing.x20;
  static const double compactHorizontalMargin = Md3Spacing.x12;
  static const double itemHorizontalPadding = 2;
  static const double itemVerticalPadding = Md3Spacing.x4;
  static const double itemMinimumHeight = 56;
  static const double iconSize = 24;
  static const double labelGap = Md3Spacing.x4;
  static const double labelSize = 13;
  static const double glassBlur = 28;
  static const double compactGlassBlur = 20;

  static double horizontalMarginFor(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 390
        ? horizontalMargin
        : compactHorizontalMargin;
  }

  static double bottomMargin(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return safeBottom > 0 ? safeBottom : minimumBottomMargin;
  }

  static double contentBottomInset(BuildContext context) {
    return visibleDockHeight + bottomMargin(context) + contentClearance;
  }
}

class Md3Page extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool includeBottomSafeArea;
  final ScrollController? scrollController;

  const Md3Page({
    super.key,
    required this.child,
    this.padding,
    this.includeBottomSafeArea = true,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Md3Colors.background,
      child: SafeArea(
        bottom: includeBottomSafeArea,
        child: SingleChildScrollView(
          controller: scrollController,
          padding:
              padding ??
              EdgeInsets.fromLTRB(
                Md3Layout.pageHorizontalInset(context),
                Md3Spacing.x20,
                Md3Layout.pageHorizontalInset(context),
                Md3Spacing.x24,
              ),
          child: child,
        ),
      ),
    );
  }
}

class Md3Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color color;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final double borderRadius;

  const Md3Card({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Md3Spacing.card),
    this.margin = EdgeInsets.zero,
    this.color = Md3Colors.surface,
    this.onTap,
    this.semanticsLabel,
    this.borderRadius = Md3Radius.card,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Md3Colors.border),
        boxShadow: Md3Shadows.contentCard,
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      button: true,
      label: semanticsLabel,
      onTap: onTap,
      child: InkWell(
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class Md3LiquidGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final double blur;
  final Color tint;
  final Color borderColor;
  final List<BoxShadow> shadows;

  const Md3LiquidGlass({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(Md3Radius.navigation),
    ),
    this.blur = Md3NavigationMetrics.glassBlur,
    this.tint = Md3Colors.glassTint,
    this.borderColor = Md3Colors.glassBorder,
    this.shadows = Md3Shadows.glass,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

Future<T?> showMd3BottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = true,
}) {
  FocusManager.instance.primaryFocus?.unfocus();

  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: useSafeArea,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: Md3Colors.scrim,
    builder: (sheetContext) {
      final mediaQuery = MediaQuery.of(sheetContext);
      final motionDuration = mediaQuery.disableAnimations
          ? Duration.zero
          : Md3Durations.standard;
      final availableHeight =
          (mediaQuery.size.height -
                  mediaQuery.viewInsets.bottom -
                  mediaQuery.viewPadding.top -
                  mediaQuery.viewPadding.bottom)
              .clamp(0.0, mediaQuery.size.height)
              .toDouble();

      return AnimatedPadding(
        duration: motionDuration,
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: availableHeight * 0.9,
            ),
            child: builder(sheetContext),
          ),
        ),
      );
    },
  );
}

class Md3BottomSheetSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets contentPadding;
  final bool showDragHandle;
  final double borderRadius;

  const Md3BottomSheetSurface({
    super.key,
    required this.child,
    this.contentPadding = const EdgeInsets.fromLTRB(
      Md3Spacing.x20,
      Md3Spacing.x16,
      Md3Spacing.x20,
      Md3Spacing.x20,
    ),
    this.showDragHandle = true,
    this.borderRadius = Md3Radius.sheet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        Md3Spacing.x12,
        0,
        Md3Spacing.x12,
        Md3Spacing.x12,
      ),
      decoration: BoxDecoration(
        color: Md3Colors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Md3Colors.border),
        boxShadow: Md3Shadows.sheet,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: contentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDragHandle) ...[
                const _Md3BottomSheetDragHandle(),
                const SizedBox(height: Md3Spacing.x16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Md3BottomSheetDragHandle extends StatefulWidget {
  const _Md3BottomSheetDragHandle();

  @override
  State<_Md3BottomSheetDragHandle> createState() =>
      _Md3BottomSheetDragHandleState();
}

class _Md3BottomSheetDragHandleState extends State<_Md3BottomSheetDragHandle> {
  static const _dismissDistance = 56.0;
  double _downwardDrag = 0;
  bool _dismissed = false;

  void _handleDragStart(DragStartDetails details) {
    _downwardDrag = 0;
    _dismissed = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _downwardDrag = (_downwardDrag + details.delta.dy).clamp(
      0,
      double.infinity,
    );
    if (_downwardDrag >= _dismissDistance) {
      _dismiss();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if ((details.primaryVelocity ?? 0) > 350) {
      _dismiss();
    }
    _downwardDrag = 0;
  }

  void _dismiss() {
    if (_dismissed || !mounted) {
      return;
    }
    _dismissed = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Drag down to close',
      child: GestureDetector(
        key: const Key('md3-bottom-sheet-drag-handle'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _handleDragStart,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: SizedBox(
          width: 64,
          height: 5,
          child: Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Md3Colors.border,
                borderRadius: BorderRadius.circular(Md3Radius.pill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Md3SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const Md3SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        2,
        Md3Spacing.sectionGap,
        2,
        Md3Spacing.x12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Md3Typography.sectionTitle.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (actionText != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionText!)),
        ],
      ),
    );
  }
}

class Md3ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int collapsedMaxLines;
  final String expandLabel;
  final String collapseLabel;

  const Md3ExpandableText({
    super.key,
    required this.text,
    required this.style,
    this.collapsedMaxLines = 5,
    this.expandLabel = 'Show more',
    this.collapseLabel = 'Show less',
  });

  @override
  State<Md3ExpandableText> createState() => _Md3ExpandableTextState();
}

class _Md3ExpandableTextState extends State<Md3ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: widget.collapsedMaxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final canExpand = textPainter.didExceedMaxLines;
        final duration = MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : Md3Durations.feedback;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: Text(
                widget.text,
                maxLines: _expanded ? null : widget.collapsedMaxLines,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: widget.style,
              ),
            ),
            if (canExpand) ...[
              const SizedBox(height: Md3Spacing.x4),
              Semantics(
                button: true,
                label: _expanded ? 'Collapse full story' : 'Expand full story',
                excludeSemantics: true,
                child: SizedBox(
                  height: Md3Targets.minimum,
                  child: TextButton.icon(
                    key: const Key('expandable-text-toggle'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.square(Md3Targets.minimum),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () {
                      setState(() => _expanded = !_expanded);
                    },
                    icon: Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _expanded ? widget.collapseLabel : widget.expandLabel,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class Md3PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool tonal;
  final double height;

  const Md3PrimaryButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.tonal = false,
    this.height = Md3Targets.primary,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = onPressed == null
        ? Md3Colors.muted
        : tonal
        ? Md3Colors.primaryStrong
        : Colors.white;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final effectiveHeight = textScale > 1.3 ? height.clamp(64, 72) : height;

    return SizedBox(
      height: effectiveHeight.toDouble(),
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Md3Radius.button),
          ),
        ).merge(MovieDiaryTheme.primaryButtonStyle(tonal: tonal)),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.arrow_forward_rounded, size: 20),
            const SizedBox(width: Md3Spacing.x8),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.fade,
                textAlign: TextAlign.center,
                style: Md3Typography.title.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Md3Chip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool active;
  final VoidCallback? onTap;

  const Md3Chip({
    super.key,
    required this.text,
    this.icon,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = active ? Md3Colors.primary : Md3Colors.surface;
    final foreground = active ? Colors.white : Md3Colors.text;
    final isInteractive = onTap != null;

    return Semantics(
      button: isInteractive,
      selected: isInteractive ? active : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(Md3Radius.pill),
        onTap: onTap,
        child: Container(
          height: isInteractive ? Md3Targets.minimum : 34,
          padding: const EdgeInsets.symmetric(horizontal: Md3Spacing.x12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(Md3Radius.pill),
            border: Border.all(
              color: active ? Md3Colors.primary : Md3Colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Md3SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;
  final EdgeInsets margin;

  const Md3SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = Md3Radius.input,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<Md3SkeletonBox> createState() => _Md3SkeletonBoxState();
}

class _Md3SkeletonBoxState extends State<Md3SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animationsDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Md3Durations.shimmer,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (animationsDisabled == _animationsDisabled &&
        (_controller.isAnimating || animationsDisabled)) {
      return;
    }

    _animationsDisabled = animationsDisabled;
    if (_animationsDisabled) {
      _controller.stop();
      _controller.value = 0.5;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final slide = -1.2 + (_controller.value * 2.4);

            return Container(
              width: widget.width,
              height: widget.height,
              margin: widget.margin,
              decoration: BoxDecoration(
                color: Md3Colors.skeleton,
                borderRadius: BorderRadius.circular(widget.radius),
                gradient: _animationsDisabled
                    ? null
                    : LinearGradient(
                        begin: Alignment(slide - 1, -0.4),
                        end: Alignment(slide + 1, 0.4),
                        colors: const [
                          Md3Colors.skeleton,
                          Md3Colors.skeleton,
                          Md3Colors.skeletonHighlight,
                          Md3Colors.skeleton,
                          Md3Colors.skeleton,
                        ],
                        stops: const [0, 0.34, 0.5, 0.66, 1],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class Md3ListSkeletonCard extends StatelessWidget {
  final int rows;
  final double posterWidth;
  final double posterHeight;
  final double cardPadding;
  final double itemSpacing;
  final bool showTrailing;
  final double trailingSize;
  final EdgeInsets cardMargin;
  final double cardRadius;

  const Md3ListSkeletonCard({
    super.key,
    this.rows = 3,
    this.posterWidth = 72,
    this.posterHeight = 108,
    this.cardPadding = Md3Spacing.x12,
    this.itemSpacing = 0,
    this.showTrailing = true,
    this.trailingSize = Md3Targets.minimum,
    this.cardMargin = const EdgeInsets.symmetric(
      horizontal: Md3Spacing.x12,
      vertical: 6,
    ),
    this.cardRadius = Md3Radius.button,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        children: List.generate(rows, (index) {
          return Container(
            margin: cardMargin.add(
              EdgeInsets.only(bottom: index == rows - 1 ? 0 : itemSpacing),
            ),
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Md3Colors.surface,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(color: Md3Colors.border),
              boxShadow: Md3Shadows.contentCard,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Md3SkeletonBox(
                  width: posterWidth,
                  height: posterHeight,
                  radius: Md3Radius.medium,
                ),
                const SizedBox(width: Md3Spacing.x12),
                Expanded(
                  child: SizedBox(
                    height: posterHeight,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Md3SkeletonBox(height: 16, radius: 8),
                        SizedBox(height: 8),
                        FractionallySizedBox(
                          widthFactor: 0.62,
                          child: Md3SkeletonBox(height: 14, radius: 8),
                        ),
                        Spacer(),
                        FractionallySizedBox(
                          widthFactor: 0.72,
                          child: Md3SkeletonBox(height: 12, radius: 8),
                        ),
                        SizedBox(height: 8),
                        FractionallySizedBox(
                          widthFactor: 0.46,
                          child: Md3SkeletonBox(height: 12, radius: 8),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showTrailing) ...[
                  const SizedBox(width: Md3Spacing.x12),
                  Md3SkeletonBox(
                    width: trailingSize,
                    height: trailingSize,
                    radius: Md3Radius.input,
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class Md3ProgressiveNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final Widget placeholder;
  final Widget fallback;
  final bool excludeFromSemantics;
  final ImageProvider<Object>? imageProvider;
  final Duration loadingTimeout;

  const Md3ProgressiveNetworkImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.placeholder,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.excludeFromSemantics = true,
    this.imageProvider,
    this.loadingTimeout = const Duration(seconds: 8),
  });

  @override
  State<Md3ProgressiveNetworkImage> createState() =>
      _Md3ProgressiveNetworkImageState();
}

class _Md3ProgressiveNetworkImageState
    extends State<Md3ProgressiveNetworkImage> {
  Timer? _loadingTimer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _restartLoadingTimeout();
  }

  @override
  void didUpdateWidget(covariant Md3ProgressiveNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageProvider != widget.imageProvider ||
        oldWidget.loadingTimeout != widget.loadingTimeout) {
      _restartLoadingTimeout();
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _restartLoadingTimeout() {
    _loadingTimer?.cancel();
    _timedOut = false;
    if ((_validatedNetworkUrl(widget.imageUrl) == null &&
            widget.imageProvider == null) ||
        widget.loadingTimeout <= Duration.zero) {
      return;
    }

    _loadingTimer = Timer(widget.loadingTimeout, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _timedOut = true;
      });
    });
  }

  void _markImageComplete() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final validatedUrl = _validatedNetworkUrl(widget.imageUrl);
    if ((validatedUrl == null && widget.imageProvider == null) || _timedOut) {
      _markImageComplete();
      return SizedBox(
        key: const Key('md3-progressive-image-fallback'),
        width: widget.width,
        height: widget.height,
        child: widget.fallback,
      );
    }

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (widget.width * pixelRatio)
        .round()
        .clamp(1, 2048)
        .toInt();
    final cacheHeight = (widget.height * pixelRatio)
        .round()
        .clamp(1, 3072)
        .toInt();
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final provider =
        widget.imageProvider ??
        CachedNetworkImageProvider(
          validatedUrl!,
          maxWidth: cacheWidth,
          maxHeight: cacheHeight,
        );

    Widget result = SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image(
          image: provider,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              _markImageComplete();
              return child;
            }
            if (frame == null) {
              return SizedBox(
                key: const Key('md3-progressive-image-loading'),
                width: widget.width,
                height: widget.height,
                child: widget.placeholder,
              );
            }
            _markImageComplete();
            if (animationsDisabled) {
              return child;
            }
            return TweenAnimationBuilder<double>(
              key: const Key('md3-progressive-image-loaded'),
              duration: Md3Durations.feedback,
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: 1),
              builder: (context, opacity, image) =>
                  Opacity(opacity: opacity, child: image),
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            _markImageComplete();
            return SizedBox(
              key: const Key('md3-progressive-image-error'),
              width: widget.width,
              height: widget.height,
              child: widget.fallback,
            );
          },
        ),
      ),
    );

    if (widget.excludeFromSemantics) {
      result = ExcludeSemantics(child: result);
    }
    return RepaintBoundary(child: result);
  }
}

typedef Md3PosterPrefetchProviderBuilder =
    ImageProvider<Object> Function(
      String imageUrl,
      int cacheWidth,
      int cacheHeight,
    );

/// Keeps exactly one next-poster decode warm without retaining stale decks.
class Md3PosterPrefetchController {
  Md3PosterPrefetchController({
    Md3PosterPrefetchProviderBuilder? providerBuilder,
  }) : _providerBuilder = providerBuilder ?? _defaultProviderBuilder;

  final Md3PosterPrefetchProviderBuilder _providerBuilder;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  String? _targetKey;
  bool _disposed = false;

  void prefetchNext(
    BuildContext context, {
    required List<Movie> movies,
    required int currentIndex,
    required String deckKey,
    double logicalWidth = 112,
    double logicalHeight = 168,
  }) {
    if (_disposed ||
        !context.mounted ||
        currentIndex < 0 ||
        currentIndex + 1 >= movies.length) {
      cancel();
      return;
    }

    final movie = movies[currentIndex + 1];
    final imageUrl = _posterImageUrl(movie.posterPath);
    if (imageUrl == null) {
      cancel();
      return;
    }

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (logicalWidth * pixelRatio)
        .round()
        .clamp(1, 2048)
        .toInt();
    final cacheHeight = (logicalHeight * pixelRatio)
        .round()
        .clamp(1, 3072)
        .toInt();
    final nextTarget =
        '$deckKey|${movie.id}|$imageUrl|$cacheWidth:$cacheHeight';
    if (_targetKey == nextTarget) {
      return;
    }

    cancel();
    _targetKey = nextTarget;
    final provider = _providerBuilder(imageUrl, cacheWidth, cacheHeight);
    final stream = provider.resolve(
      createLocalImageConfiguration(
        context,
        size: Size(logicalWidth, logicalHeight),
      ),
    );
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronousCall) => _complete(stream, listener),
      onError: (error, stackTrace) => _complete(stream, listener),
    );
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _complete(ImageStream stream, ImageStreamListener listener) {
    stream.removeListener(listener);
    if (identical(_stream, stream)) {
      _stream = null;
      _listener = null;
    }
  }

  void cancel() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _stream = null;
    _listener = null;
    _targetKey = null;
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    cancel();
    _disposed = true;
  }

  static ImageProvider<Object> _defaultProviderBuilder(
    String imageUrl,
    int cacheWidth,
    int cacheHeight,
  ) {
    return CachedNetworkImageProvider(
      imageUrl,
      maxWidth: cacheWidth,
      maxHeight: cacheHeight,
    );
  }
}

class Md3MoviePoster extends StatefulWidget {
  final Movie movie;
  final double width;
  final double height;
  final double borderRadius;
  final bool hydrateMissingPoster;
  final Future<String?> Function(String movieId)? metadataLoader;
  final ImageProvider<Object>? imageProvider;

  const Md3MoviePoster({
    super.key,
    required this.movie,
    required this.width,
    required this.height,
    this.borderRadius = Md3Radius.poster,
    this.hydrateMissingPoster = true,
    this.metadataLoader,
    this.imageProvider,
  });

  @override
  State<Md3MoviePoster> createState() => _Md3MoviePosterState();
}

class _Md3MoviePosterState extends State<Md3MoviePoster> {
  String? _hydratedPosterPath;
  int _hydrationGeneration = 0;

  @override
  void initState() {
    super.initState();
    _hydrateIfNeeded();
  }

  @override
  void didUpdateWidget(covariant Md3MoviePoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movie.id != widget.movie.id ||
        oldWidget.movie.posterPath != widget.movie.posterPath ||
        oldWidget.hydrateMissingPoster != widget.hydrateMissingPoster) {
      _hydratedPosterPath = null;
      _hydrationGeneration++;
      _hydrateIfNeeded();
    }
  }

  void _hydrateIfNeeded() {
    if (!widget.hydrateMissingPoster ||
        _posterImageUrl(widget.movie.posterPath) != null ||
        widget.movie.id.trim().isEmpty) {
      return;
    }

    final generation = ++_hydrationGeneration;
    final loader = widget.metadataLoader ?? _loadPosterMetadata;
    _Md3PosterHydrationCache.resolve(widget.movie.id, loader).then((path) {
      if (!mounted || generation != _hydrationGeneration || path == null) {
        return;
      }
      setState(() {
        _hydratedPosterPath = path;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final posterPath = _posterImageUrl(widget.movie.posterPath) == null
        ? _hydratedPosterPath
        : widget.movie.posterPath;

    return Md3ProgressiveNetworkImage(
      imageUrl: _posterImageUrl(posterPath),
      width: widget.width,
      height: widget.height,
      borderRadius: widget.borderRadius,
      imageProvider: widget.imageProvider,
      placeholder: Md3SkeletonBox(
        width: widget.width,
        height: widget.height,
        radius: widget.borderRadius,
      ),
      fallback: _PosterFallback(
        width: widget.width,
        height: widget.height,
        title: widget.movie.title,
        borderRadius: widget.borderRadius,
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  final double width;
  final double height;
  final String title;
  final double borderRadius;

  const _PosterFallback({
    required this.width,
    required this.height,
    required this.title,
    this.borderRadius = Md3Radius.poster,
  });

  @override
  Widget build(BuildContext context) {
    final showLargeLabel = width >= 100 && height >= 150;
    final showMonogram = !showLargeLabel && width >= 58 && height >= 86;
    final compactIconSize = width < 58 || height < 86 ? 20.0 : 28.0;
    final trimmedTitle = title.trim();
    final posterInitial = trimmedTitle.isNotEmpty
        ? trimmedTitle.substring(0, 1).toUpperCase()
        : '?';

    return SizedBox(
      key: const Key('md3-poster-fallback'),
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Md3Colors.primarySoft,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Md3Colors.primary.withValues(alpha: 0.08)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: showLargeLabel
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Md3Colors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            posterInitial,
                            textScaler: TextScaler.noScaling,
                            style: const TextStyle(
                              color: Md3Colors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: Md3Spacing.x8),
                        const Text(
                          'No poster',
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: Md3Colors.muted,
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      Icons.movie_outlined,
                      color: Md3Colors.primary,
                      size: compactIconSize,
                    ),
            ),
            if (showMonogram)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Text(
                  'MD',
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 11,
                    height: 14 / 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Md3ProviderLogo extends StatelessWidget {
  final String providerName;
  final String? logoPath;
  final double size;
  final ImageProvider<Object>? imageProvider;

  const Md3ProviderLogo({
    super.key,
    required this.providerName,
    required this.logoPath,
    this.size = 40,
    this.imageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Md3ProgressiveNetworkImage(
      imageUrl: _providerImageUrl(logoPath),
      width: size,
      height: size,
      borderRadius: Md3Radius.medium,
      imageProvider: imageProvider,
      placeholder: Md3SkeletonBox(
        width: size,
        height: size,
        radius: Md3Radius.medium,
      ),
      fallback: _ProviderFallback(providerName: providerName, size: size),
    );
  }
}

class _ProviderFallback extends StatelessWidget {
  final String providerName;
  final double size;

  const _ProviderFallback({required this.providerName, required this.size});

  @override
  Widget build(BuildContext context) {
    final trimmedName = providerName.trim();
    final initial = trimmedName.isEmpty
        ? null
        : trimmedName.substring(0, 1).toUpperCase();

    return Container(
      key: const Key('md3-provider-fallback'),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Md3Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(Md3Radius.medium),
        border: Border.all(color: Md3Colors.border),
      ),
      child: initial == null
          ? const Icon(Icons.live_tv_outlined, color: Md3Colors.muted, size: 20)
          : Text(
              initial,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                color: Md3Colors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class Md3ProviderSkeletonList extends StatelessWidget {
  final int rows;

  const Md3ProviderSkeletonList({super.key, this.rows = 2});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        children: List.generate(
          rows,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index == rows - 1 ? 0 : Md3Spacing.x12,
            ),
            child: const Row(
              children: [
                Md3SkeletonBox(width: 40, height: 40, radius: Md3Radius.medium),
                SizedBox(width: Md3Spacing.x12),
                Expanded(
                  child: Md3SkeletonBox(
                    height: Md3Spacing.x16,
                    radius: Md3Radius.small,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Md3PosterHydrationCache {
  static final Map<String, Future<String?>> _requests = {};

  static Future<String?> resolve(
    String movieId,
    Future<String?> Function(String movieId) loader,
  ) {
    return _requests.putIfAbsent(movieId, () async {
      try {
        final path = await loader(movieId);
        return _posterImageUrl(path) == null ? null : path;
      } catch (error) {
        debugPrint('Poster metadata hydration failed for $movieId: $error');
        return null;
      }
    });
  }
}

Future<String?> _loadPosterMetadata(String movieId) async {
  final response = await ServiceAgent()
      .getMovie(movieId)
      .timeout(const Duration(seconds: 8));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    return null;
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    return null;
  }
  return '${decoded['posterPath'] ?? ''}'.trim();
}

String? _validatedNetworkUrl(String? rawUrl) {
  final value = rawUrl?.trim() ?? '';
  if (value.isEmpty ||
      value.toLowerCase() == 'null' ||
      value.contains(RegExp(r'[\s\x00-\x1f]'))) {
    return null;
  }

  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasScheme ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty) {
    return null;
  }
  return uri.toString();
}

String? _posterImageUrl(String? rawPath) {
  final value = rawPath?.trim() ?? '';
  if (value.isEmpty || value.toLowerCase() == 'null') {
    return null;
  }

  final absoluteUrl = _validatedNetworkUrl(value);
  if (absoluteUrl != null) {
    return absoluteUrl;
  }
  if (Uri.tryParse(value)?.hasScheme ?? false) {
    return null;
  }
  if (value.contains(RegExp(r'[\s\x00-\x1f]'))) {
    return null;
  }

  final path = value.startsWith('/') ? value : '/$value';
  return Uri.https(
    'moviediarystorage.blob.core.windows.net',
    '/movies$path',
  ).toString();
}

String? _providerImageUrl(String? rawPath) {
  final value = rawPath?.trim() ?? '';
  if (value.isEmpty || value.toLowerCase() == 'null') {
    return null;
  }

  final absoluteUrl = _validatedNetworkUrl(value);
  if (absoluteUrl != null) {
    return absoluteUrl;
  }
  if (Uri.tryParse(value)?.hasScheme ?? false) {
    return null;
  }
  if (value.contains(RegExp(r'[\s\x00-\x1f]'))) {
    return null;
  }

  final path = value.startsWith('/') ? value : '/$value';
  return Uri.https('image.tmdb.org', '/t/p/w92$path').toString();
}

class Md3HorizontalMovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final Widget? trailing;

  const Md3HorizontalMovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final year = DateFormat('yyyy').format(movie.releaseDate);
    final metadata = [
      year,
      if (movie.duration > 0) '${movie.duration} min',
      if (movie.genres.isNotEmpty) movie.genres.take(2).join(', '),
    ].join('  /  ');
    final scoreLabel = movieScoreLabel(movie);

    return Md3Card(
      onTap: onTap,
      semanticsLabel: onTap == null ? null : 'Open ${movie.title} details',
      padding: const EdgeInsets.all(Md3Spacing.x12),
      margin: const EdgeInsets.only(bottom: Md3Spacing.x12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Md3MoviePoster(
            movie: movie,
            width: 92,
            height: 108,
            borderRadius: 14,
          ),
          const SizedBox(width: Md3Spacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Md3Colors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 21 / 18,
                  ),
                ),
                const SizedBox(height: Md3Spacing.x4),
                Text(
                  metadata,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 14,
                    height: 17 / 14,
                  ),
                ),
                if (scoreLabel != null) ...[
                  const SizedBox(height: Md3Spacing.x4),
                  Text(
                    scoreLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 13,
                      height: 16 / 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Md3Spacing.x8),
            trailing!,
          ],
          if (onTap != null) ...[
            SizedBox(width: trailing == null ? Md3Spacing.x8 : Md3Spacing.x4),
            const ExcludeSemantics(
              child: Icon(Icons.chevron_right_rounded, color: Md3Colors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

String? movieScoreLabel(Movie movie) {
  final source = movie.scoreSource?.trim();
  final value = movie.scoreValue;
  if (source == null || source.isEmpty || value == null || value <= 0) {
    return null;
  }

  final scale = movie.scoreScale?.trim().toLowerCase();
  final formattedValue = switch (scale) {
    'percent' || 'percentage' || '100' => '${value.round()}%',
    '10' || 'ten' => value.toStringAsFixed(1),
    _ =>
      value == value.roundToDouble()
          ? value.round().toString()
          : value.toStringAsFixed(1),
  };
  final count = movie.scoreCount;
  if (count == null || count <= 0) {
    return '$source $formattedValue';
  }

  final countLabel = NumberFormat.decimalPattern('en_US').format(count);
  return '$source $formattedValue · $countLabel '
      '${count == 1 ? 'rating' : 'ratings'}';
}

class Md3OpinionBadge extends StatelessWidget {
  final int movieRate;

  const Md3OpinionBadge({super.key, required this.movieRate});

  @override
  Widget build(BuildContext context) {
    final data = switch (movieRate) {
      MovieRate.liked => (
        'Liked',
        Icons.favorite_rounded,
        Md3Colors.liked,
        Md3Colors.likedSoft,
      ),
      MovieRate.okay => (
        'Okay',
        Icons.sentiment_satisfied_alt_rounded,
        Md3Colors.okay,
        Md3Colors.okaySoft,
      ),
      MovieRate.notLiked => (
        'Disliked',
        Icons.block_rounded,
        Md3Colors.disliked,
        Md3Colors.dislikedSoft,
      ),
      MovieRate.addedToWatchlist => (
        'Watchlist',
        Icons.bookmark_rounded,
        Md3Colors.primary,
        Md3Colors.watchlistSoft,
      ),
      _ => ('New', Icons.add_rounded, Md3Colors.muted, Md3Colors.neutralSoft),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: data.$4,
        borderRadius: BorderRadius.circular(Md3Radius.pill),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.$2, size: 14, color: data.$3),
            const SizedBox(width: 5),
            Text(
              data.$1,
              style: TextStyle(
                color: data.$3,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
