import 'package:flutter/material.dart';
import 'package:mmobile/Helpers/ad_inventory.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

/// Shared MovieDiary-native advertising surface.
///
/// It deliberately looks adjacent to, but not identical with, movie content:
/// the muted opaque surface and always-visible disclosure keep provider media
/// from impersonating a recommendation, MovieDNA signal, or movie card.
class MdNativeAdSurface extends StatelessWidget {
  const MdNativeAdSurface({
    super.key,
    required this.resource,
    this.providerViewHeight,
    this.margin = const EdgeInsets.symmetric(
      horizontal: Md3Spacing.x12,
      vertical: 6,
    ),
  });

  final NativeAdResource resource;
  final double? providerViewHeight;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    // Movie rows are 144 pt through 390-wide viewports and 156 pt on larger
    // phones. Subtracting their 12 pt outer spacing leaves a 132/144 pt card;
    // the provider remains within Google's documented 90-200 pt small-template
    // guidance without a decorative dead zone.
    return Padding(
      key: const Key('md-native-ad-margin'),
      padding: margin,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final resolvedProviderHeight =
              providerViewHeight ??
              (constraints.maxWidth <= 366 ? 90.0 : 102.0);
          return Semantics(
            container: true,
            label: 'Sponsored advertisement',
            explicitChildNodes: true,
            child: Container(
              key: const Key('md-native-ad-card'),
              padding: const EdgeInsets.all(Md3Spacing.x8),
              decoration: BoxDecoration(
                color: Md3Colors.surfaceMuted,
                borderRadius: BorderRadius.circular(Md3Radius.card),
                border: Border.all(color: Md3Colors.border),
                boxShadow: Md3Shadows.contentCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 16,
                    child: Row(
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 16,
                          color: Md3Colors.muted,
                        ),
                        SizedBox(width: Md3Spacing.x8),
                        Text('Sponsored', style: Md3Typography.metadata),
                      ],
                    ),
                  ),
                  const SizedBox(height: Md3Spacing.x8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Md3Radius.input),
                    child: ColoredBox(
                      color: Md3Colors.surface,
                      child: SizedBox(
                        key: const Key('md-native-ad-provider-view'),
                        height: resolvedProviderHeight,
                        child: resource.buildView(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
