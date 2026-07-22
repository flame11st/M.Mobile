import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/movie.dart';

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

class Md3NavigationMetrics {
  static const double dockHeight = 72;
  static const double minimumBottomMargin = 8;
  static const double maximumBottomMargin = 12;
  static const double contentClearance = 16;

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
    return dockHeight + bottomMargin(context) + contentClearance;
  }
}

class Md3Page extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool includeBottomSafeArea;

  const Md3Page({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 24),
    this.includeBottomSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Md3Colors.background,
      child: SafeArea(
        bottom: includeBottomSafeArea,
        child: SingleChildScrollView(
          padding: padding,
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

  const Md3Card({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.color = Md3Colors.surface,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Md3Colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
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

class Md3PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool tonal;

  const Md3PrimaryButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.tonal = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = tonal ? const Color(0xffe8f0fb) : Md3Colors.primary;
    final foreground = tonal ? Md3Colors.primary : Colors.white;

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 20),
        label: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 34,
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
      duration: const Duration(milliseconds: 1250),
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
                color: Md3Colors.surfaceMuted,
                borderRadius: BorderRadius.circular(widget.radius),
                gradient: _animationsDisabled
                    ? null
                    : LinearGradient(
                        begin: Alignment(slide - 1, -0.4),
                        end: Alignment(slide + 1, 0.4),
                        colors: const [
                          Md3Colors.surfaceMuted,
                          Color(0xffe8edf2),
                          Color(0xfff6f8fa),
                          Color(0xffe8edf2),
                          Md3Colors.surfaceMuted,
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

  const Md3ListSkeletonCard({
    super.key,
    this.rows = 3,
    this.posterWidth = 64,
    this.posterHeight = 96,
    this.cardPadding = 10,
    this.itemSpacing = 10,
    this.showTrailing = true,
    this.trailingSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        children: List.generate(rows, (index) {
          return Md3Card(
            margin: EdgeInsets.only(
              bottom: index == rows - 1 ? 0 : itemSpacing,
            ),
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              children: [
                Md3SkeletonBox(
                  width: posterWidth,
                  height: posterHeight,
                  radius: 14,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Md3SkeletonBox(height: 16, radius: 8),
                      SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.72,
                        child: Md3SkeletonBox(height: 12, radius: 8),
                      ),
                      SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.46,
                        child: Md3SkeletonBox(height: 12, radius: 8),
                      ),
                    ],
                  ),
                ),
                if (showTrailing) ...[
                  const SizedBox(width: 12),
                  Md3SkeletonBox(
                    width: trailingSize,
                    height: trailingSize,
                    radius: trailingSize / 2,
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

class Md3MoviePoster extends StatelessWidget {
  final Movie movie;
  final double width;
  final double height;

  const Md3MoviePoster({
    super.key,
    required this.movie,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final posterPath = movie.posterPath.trim();

    if (posterPath.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _PosterFallback(
          width: width,
          height: height,
          title: movie.title,
        ),
      );
    }

    final imageUrl =
        'https://moviediarystorage.blob.core.windows.net/movies$posterPath';
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          memCacheWidth: (width * pixelRatio).round(),
          memCacheHeight: (height * pixelRatio).round(),
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 180),
          fadeOutDuration: const Duration(milliseconds: 100),
          placeholder: (context, url) => _PosterFallback(
            width: width,
            height: height,
            title: movie.title,
            isLoading: true,
          ),
          errorWidget: (context, url, error) => _PosterFallback(
            width: width,
            height: height,
            title: movie.title,
          ),
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  final double width;
  final double height;
  final String title;
  final bool isLoading;

  const _PosterFallback({
    required this.width,
    required this.height,
    required this.title,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final showLabel = width >= 58 && height >= 86;
    final trimmedTitle = title.trim();
    final posterInitial = trimmedTitle.isNotEmpty
        ? trimmedTitle.substring(0, 1).toUpperCase()
        : '?';

    return Semantics(
      label: isLoading ? 'Loading poster' : 'Poster unavailable',
      image: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isLoading)
              Md3SkeletonBox(width: width, height: height, radius: 16)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xffedf2f6),
                      Color(0xffd9e3ec),
                    ],
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: showLabel ? 38 : 30,
                    height: showLabel ? 38 : 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        isLoading ? 0.46 : 0.72,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    child: isLoading
                        ? const Icon(
                            Icons.image_outlined,
                            color: Md3Colors.muted,
                            size: 20,
                          )
                        : Text(
                            posterInitial,
                            style: const TextStyle(
                              color: Md3Colors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                  ),
                  if (!isLoading && showLabel) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'No poster',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    );
  }
}
