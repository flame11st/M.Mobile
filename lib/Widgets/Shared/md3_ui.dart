import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Services/service_agent.dart';

class Md3Colors {
  static const background = Color(0xfff7f8fa);
  static const surface = Color(0xffffffff);
  static const surfaceMuted = Color(0xfff0f3f6);
  static const primary = Color(0xff244f7d);
  static const primarySoft = Color(0xffe6eef7);
  static const accent = Color(0xffdca44f);
  static const text = Color(0xff172231);
  static const muted = Color(0xff667284);
  static const border = Color(0xffdfe5eb);
  static const success = Color(0xff287a50);
  static const warning = Color(0xffa96716);
  static const danger = Color(0xffb93a46);
}

class MovieDiaryTheme {
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
      error: Md3Colors.danger,
      onError: Colors.white,
      outline: Md3Colors.border,
      shadow: Color(0x14172231),
    );
    const textTheme = TextTheme(
      displayLarge: TextStyle(
        color: Md3Colors.text,
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        color: Md3Colors.text,
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        color: Md3Colors.text,
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        color: Md3Colors.text,
        fontSize: 24,
        height: 29 / 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        color: Md3Colors.text,
        fontSize: 24,
        height: 29 / 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        color: Md3Colors.text,
        fontSize: 22,
        height: 27 / 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: Md3Colors.text,
        fontSize: 20,
        height: 25 / 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: Md3Colors.text,
        fontSize: 16,
        height: 23 / 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        color: Md3Colors.text,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        color: Md3Colors.text,
        fontSize: 16,
        height: 23 / 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        color: Md3Colors.text,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        color: Md3Colors.muted,
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        color: Md3Colors.text,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        color: Md3Colors.text,
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
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
        titleTextStyle: TextStyle(
          color: Md3Colors.text,
          fontSize: 20,
          height: 25 / 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: Md3Colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: Md3Colors.primary,
          side: const BorderSide(color: Md3Colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
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
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Md3Colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Md3Colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Md3Colors.primary,
            width: 2,
          ),
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
    return MediaQuery.sizeOf(context).width >= 600 ? 24 : 16;
  }
}

class Md3NavigationMetrics {
  static const double dockHeight = 72;
  static const double minimumBottomMargin = 8;
  static const double maximumBottomMargin = 12;
  static const double contentClearance = 12;

  static double bottomMargin(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    if (safeBottom <= 0) {
      return minimumBottomMargin;
    }

    return safeBottom
        .clamp(minimumBottomMargin, maximumBottomMargin)
        .toDouble();
  }

  static double contentBottomInset(BuildContext context) {
    return dockHeight +
        MediaQuery.viewPaddingOf(context).bottom +
        contentClearance;
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
          padding: padding ??
              EdgeInsets.fromLTRB(
                Md3Layout.pageHorizontalInset(context),
                18,
                Md3Layout.pageHorizontalInset(context),
                24,
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
  final double borderRadius;

  const Md3Card({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.color = Md3Colors.surface,
    this.onTap,
    this.borderRadius = 24,
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x14172231),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: onTap,
      child: card,
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
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.blur = 28,
    this.tint = const Color(0xb8ffffff),
    this.borderColor = const Color(0xd9ffffff),
    this.shadows = const [
      BoxShadow(
        color: Color(0x160f253d),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadows,
      ),
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
}) {
  FocusManager.instance.primaryFocus?.unfocus();

  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (sheetContext) {
      final mediaQuery = MediaQuery.of(sheetContext);
      final motionDuration = mediaQuery.disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 180);
      final availableHeight = (mediaQuery.size.height -
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
    this.contentPadding = const EdgeInsets.fromLTRB(20, 16, 20, 20),
    this.showDragHandle = true,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Md3Colors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Md3Colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260f253d),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: contentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDragHandle) ...[
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Md3Colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
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
      padding: const EdgeInsets.fromLTRB(2, 32, 2, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Md3Colors.text,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionText!),
            ),
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
            : const Duration(milliseconds: 160);

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
                overflow:
                    _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: widget.style,
              ),
            ),
            if (canExpand) ...[
              const SizedBox(height: 4),
              Semantics(
                button: true,
                label: _expanded ? 'Collapse full story' : 'Expand full story',
                excludeSemantics: true,
                child: SizedBox(
                  height: 44,
                  child: TextButton.icon(
                    key: const Key('expandable-text-toggle'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
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
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final background = tonal ? const Color(0xffe8f0fb) : Md3Colors.primary;
    final foreground = tonal ? Md3Colors.primary : Colors.white;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final effectiveHeight = textScale > 1.3 ? height.clamp(64, 72) : height;

    return SizedBox(
      height: effectiveHeight.toDouble(),
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.arrow_forward_rounded, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.fade,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: isInteractive ? 44 : 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
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
    this.radius = 16,
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
      duration: const Duration(milliseconds: 1200),
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
                color: const Color(0xffedf1f5),
                borderRadius: BorderRadius.circular(widget.radius),
                gradient: _animationsDisabled
                    ? null
                    : LinearGradient(
                        begin: Alignment(slide - 1, -0.4),
                        end: Alignment(slide + 1, 0.4),
                        colors: const [
                          Color(0xffedf1f5),
                          Color(0xffedf1f5),
                          Color(0xfff8fafc),
                          Color(0xffedf1f5),
                          Color(0xffedf1f5),
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
    this.cardPadding = 12,
    this.itemSpacing = 0,
    this.showTrailing = true,
    this.trailingSize = 44,
    this.cardMargin = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    this.cardRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        children: List.generate(rows, (index) {
          return Container(
            margin: cardMargin.add(
              EdgeInsets.only(
                bottom: index == rows - 1 ? 0 : itemSpacing,
              ),
            ),
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Md3Colors.surface,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(color: Md3Colors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0f172231),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Md3SkeletonBox(
                  width: posterWidth,
                  height: posterHeight,
                  radius: 12,
                ),
                const SizedBox(width: 12),
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
                  const SizedBox(width: 12),
                  Md3SkeletonBox(
                    width: trailingSize,
                    height: trailingSize,
                    radius: 16,
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
    final cacheWidth =
        (widget.width * pixelRatio).round().clamp(1, 2048).toInt();
    final cacheHeight =
        (widget.height * pixelRatio).round().clamp(1, 3072).toInt();
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final provider = widget.imageProvider ??
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
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: 1),
              builder: (context, opacity, image) => Opacity(
                opacity: opacity,
                child: image,
              ),
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
    this.borderRadius = 16,
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
    this.borderRadius = 16,
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
          border: Border.all(
            color: Md3Colors.primary.withValues(alpha: 0.08),
          ),
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
                        const SizedBox(height: 8),
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
      borderRadius: 10,
      imageProvider: imageProvider,
      placeholder: Md3SkeletonBox(
        width: size,
        height: size,
        radius: 10,
      ),
      fallback: _ProviderFallback(
        providerName: providerName,
        size: size,
      ),
    );
  }
}

class _ProviderFallback extends StatelessWidget {
  final String providerName;
  final double size;

  const _ProviderFallback({
    required this.providerName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedName = providerName.trim();
    final initial =
        trimmedName.isEmpty ? null : trimmedName.substring(0, 1).toUpperCase();

    return Container(
      key: const Key('md3-provider-fallback'),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Md3Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Md3Colors.border),
      ),
      child: initial == null
          ? const Icon(
              Icons.live_tv_outlined,
              color: Md3Colors.muted,
              size: 20,
            )
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
            padding: EdgeInsets.only(bottom: index == rows - 1 ? 0 : 12),
            child: const Row(
              children: [
                Md3SkeletonBox(width: 40, height: 40, radius: 10),
                SizedBox(width: 12),
                Expanded(child: Md3SkeletonBox(height: 16, radius: 8)),
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
    return _requests.putIfAbsent(
      movieId,
      () async {
        try {
          final path = await loader(movieId);
          return _posterImageUrl(path) == null ? null : path;
        } catch (error) {
          debugPrint('Poster metadata hydration failed for $movieId: $error');
          return null;
        }
      },
    );
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

    return Md3Card(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Md3MoviePoster(movie: movie, width: 58, height: 86),
          const SizedBox(width: 12),
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  metadata,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                if (movie.rating > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Audience score ${movie.rating}%',
                    style: const TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
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
          Md3Colors.success,
          const Color(0xffe9f7ef)
        ),
      MovieRate.okay => (
          'Okay',
          Icons.sentiment_satisfied_alt_rounded,
          Md3Colors.warning,
          const Color(0xfffff4dc)
        ),
      MovieRate.notLiked => (
          'Disliked',
          Icons.block_rounded,
          Md3Colors.danger,
          const Color(0xffffecef)
        ),
      MovieRate.addedToWatchlist => (
          'Watchlist',
          Icons.bookmark_rounded,
          Md3Colors.primary,
          const Color(0xffe8f0fb)
        ),
      _ => ('New', Icons.add_rounded, Md3Colors.muted, const Color(0xfff3f4f6)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: data.$4,
        borderRadius: BorderRadius.circular(999),
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
