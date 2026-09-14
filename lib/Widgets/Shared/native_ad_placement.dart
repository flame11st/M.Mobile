import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_list_type.dart';
import 'package:mmobile/Services/monetization_service.dart';
import 'package:mmobile/Widgets/Shared/md_native_ad_surface.dart';
import 'package:provider/provider.dart';

enum DiscoverNativePlacementBoundary { none, afterPopularMovies }

bool isGeneralPublicListType(MovieListType type) =>
    type == MovieListType.external;

/// Keeps the single Discover placement at the explicit Movies/TV boundary.
DiscoverNativePlacementBoundary discoverNativePlacementBoundary({
  required int popularMovieCount,
  required int popularTvCount,
}) {
  if (popularMovieCount > 0 && popularTvCount > 0) {
    return DiscoverNativePlacementBoundary.afterPopularMovies;
  }
  return DiscoverNativePlacementBoundary.none;
}

/// Maps a mixed content/ad row index back to its real movie index.
///
/// The caller supplies a bounded interval/maximum policy. Ads never
/// participate in movie counts, pagination, navigation positions, or content
/// analytics.
class NativeContentInsertionPlan {
  const NativeContentInsertionPlan._({
    required this.contentCount,
    required this.contentPositions,
  });

  factory NativeContentInsertionPlan.forContentCount(
    int contentCount, {
    int interval = 10,
    int maximum = 2,
  }) {
    assert(interval > 0);
    assert(maximum >= 0);
    return NativeContentInsertionPlan._(
      contentCount: contentCount,
      contentPositions: [
        for (var slot = 1; slot <= maximum; slot++)
          if (contentCount >= interval * slot) interval * slot,
      ],
    );
  }

  final int contentCount;
  final List<int> contentPositions;

  int get itemCount => contentCount + contentPositions.length;

  Iterable<int> get _mixedAdIndices sync* {
    for (var index = 0; index < contentPositions.length; index++) {
      yield contentPositions[index] + index;
    }
  }

  bool isAdIndex(int mixedIndex) => _mixedAdIndices.contains(mixedIndex);

  int? contentPositionForAdIndex(int mixedIndex) {
    for (var index = 0; index < contentPositions.length; index++) {
      if (mixedIndex == contentPositions[index] + index) {
        return contentPositions[index];
      }
    }
    return null;
  }

  int contentIndexForMixedIndex(int mixedIndex) {
    final adsBefore = _mixedAdIndices
        .where((index) => index < mixedIndex)
        .length;
    return mixedIndex - adsBefore;
  }
}

/// Shared screen adapter for a centralized, provider-neutral native placement.
///
/// The widget reserves no height until inventory is both eligible and ready.
class ManagedNativeAdPlacement extends StatefulWidget {
  const ManagedNativeAdPlacement({
    super.key,
    required this.placement,
    required this.surface,
    required this.contentPosition,
    this.margin,
  });

  final MonetizationPlacement placement;
  final MonetizationSurface surface;
  final int contentPosition;
  final EdgeInsets? margin;

  @override
  State<ManagedNativeAdPlacement> createState() =>
      _ManagedNativeAdPlacementState();
}

class _ManagedNativeAdPlacementState extends State<ManagedNativeAdPlacement> {
  MonetizationService? _monetization;
  NativePlacementController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final monetization = Provider.of<MonetizationService?>(
      context,
      listen: false,
    );
    if (identical(monetization, _monetization)) {
      return;
    }
    _controller?.dispose();
    _monetization = monetization;
    _controller = monetization?.createNativePlacement(
      placement: widget.placement,
      surface: widget.surface,
      contentPosition: widget.contentPosition,
    );
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.prepare());
    }
  }

  @override
  void didUpdateWidget(covariant ManagedNativeAdPlacement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement == widget.placement &&
        oldWidget.surface == widget.surface &&
        oldWidget.contentPosition == widget.contentPosition) {
      return;
    }
    _controller?.dispose();
    _controller = _monetization?.createNativePlacement(
      placement: widget.placement,
      surface: widget.surface,
      contentPosition: widget.contentPosition,
    );
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.prepare());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final resource = controller.resource;
        if (resource == null) {
          return const SizedBox.shrink();
        }
        return MdNativeAdSurface(
          resource: resource,
          providerViewHeight: widget.surface == MonetizationSurface.discover
              ? 90
              : null,
          margin:
              widget.margin ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        );
      },
    );
  }
}
