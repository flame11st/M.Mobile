import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mmobile/Services/rewarded_allowance_flow.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

enum RewardedAllowanceAction { generate, premium, premiumActivated, notNow }

Future<RewardedAllowanceAction?> showRewardedAllowanceSheet({
  required BuildContext context,
  required RewardedAllowanceFlowController controller,
  required String userId,
  required int freeDecksPerDay,
  Future<void> Function()? onPlaybackStarted,
  Listenable? entitlementListenable,
  bool Function()? isPremium,
}) {
  return showModalBottomSheet<RewardedAllowanceAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    barrierColor: Md3Colors.scrim,
    backgroundColor: Colors.transparent,
    builder: (context) => RewardedAllowanceSheet(
      controller: controller,
      userId: userId,
      freeDecksPerDay: freeDecksPerDay,
      onPlaybackStarted: onPlaybackStarted,
      entitlementListenable: entitlementListenable,
      isPremium: isPremium,
    ),
  );
}

class RewardedAllowanceSheet extends StatefulWidget {
  const RewardedAllowanceSheet({
    super.key,
    required this.controller,
    required this.userId,
    required this.freeDecksPerDay,
    this.onPlaybackStarted,
    this.entitlementListenable,
    this.isPremium,
  });

  final RewardedAllowanceFlowController controller;
  final String userId;
  final int freeDecksPerDay;
  final Future<void> Function()? onPlaybackStarted;
  final Listenable? entitlementListenable;
  final bool Function()? isPremium;

  @override
  State<RewardedAllowanceSheet> createState() => _RewardedAllowanceSheetState();
}

class _RewardedAllowanceSheetState extends State<RewardedAllowanceSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_flowChanged);
    widget.entitlementListenable?.addListener(_entitlementChanged);
    if (!widget.controller.isAvailable && !widget.controller.isBusy) {
      unawaited(widget.controller.prepare());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_flowChanged);
    widget.entitlementListenable?.removeListener(_entitlementChanged);
    super.dispose();
  }

  void _flowChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _entitlementChanged() {
    if (!mounted || widget.isPremium?.call() != true) {
      return;
    }
    Navigator.of(context).pop(RewardedAllowanceAction.premiumActivated);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final media = MediaQuery.of(context);
    final bottomPadding =
        media.viewInsets.bottom + media.padding.bottom + Md3Spacing.x16;

    return Material(
      key: const Key('rewarded-allowance-sheet'),
      color: Md3Colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Md3Radius.sheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * .88),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Md3Spacing.x24,
            Md3Spacing.x12,
            Md3Spacing.x24,
            bottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Md3Colors.border,
                    borderRadius: BorderRadius.circular(Md3Radius.pill),
                  ),
                ),
              ),
              const SizedBox(height: Md3Spacing.x20),
              const _RewardedIllustration(),
              const SizedBox(height: Md3Spacing.x16),
              const Text(
                'More recommendations',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Md3Colors.text,
                  fontSize: 26,
                  height: 32 / 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: Md3Spacing.x8),
              Text(
                "You've used today's ${widget.freeDecksPerDay} free discovery decks. Watch a short ad to unlock another 10 recommendations.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 16,
                  height: 23 / 16,
                ),
              ),
              const SizedBox(height: Md3Spacing.x16),
              _RewardedStateNotice(state: state),
              const SizedBox(height: Md3Spacing.x20),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  key: const Key('rewarded-primary-action'),
                  onPressed: _primaryEnabled(state)
                      ? () => _runPrimaryAction(state)
                      : null,
                  icon: _primaryIcon(state),
                  label: Text(_primaryLabel(state)),
                ),
              ),
              const SizedBox(height: Md3Spacing.x12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  key: const Key('rewarded-premium-action'),
                  onPressed: () => Navigator.of(context).pop(
                    RewardedAllowanceAction.premium,
                  ),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                  label: const Text('Get Premium'),
                ),
              ),
              const SizedBox(height: Md3Spacing.x8),
              SizedBox(
                height: 48,
                child: TextButton(
                  key: const Key('rewarded-not-now-action'),
                  onPressed: () => Navigator.of(context).pop(
                    RewardedAllowanceAction.notNow,
                  ),
                  child: const Text('Not now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _primaryEnabled(RewardedAllowanceFlowState state) => switch (state) {
        RewardedAllowanceFlowState.loading ||
        RewardedAllowanceFlowState.playing ||
        RewardedAllowanceFlowState.rewardLimitReached =>
          false,
        _ => true,
      };

  String _primaryLabel(RewardedAllowanceFlowState state) => switch (state) {
        RewardedAllowanceFlowState.available => 'Watch ad & continue',
        RewardedAllowanceFlowState.loading => 'Finding a short ad…',
        RewardedAllowanceFlowState.playing => 'Ad playing…',
        RewardedAllowanceFlowState.completed => 'Build recommendation deck',
        RewardedAllowanceFlowState.dismissedWithoutReward => 'Try ad again',
        RewardedAllowanceFlowState.failedToLoad ||
        RewardedAllowanceFlowState.failedDuringPlayback =>
          'Try ad again',
        RewardedAllowanceFlowState.rewardLimitReached =>
          'Extra decks reset tomorrow',
      };

  Widget _primaryIcon(RewardedAllowanceFlowState state) {
    if (state == RewardedAllowanceFlowState.loading ||
        state == RewardedAllowanceFlowState.playing) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Md3Colors.primary,
        ),
      );
    }
    return Icon(
      state == RewardedAllowanceFlowState.completed
          ? Icons.auto_awesome_rounded
          : Icons.play_circle_fill_rounded,
      size: 21,
    );
  }

  Future<void> _runPrimaryAction(
    RewardedAllowanceFlowState state,
  ) async {
    if (state == RewardedAllowanceFlowState.completed) {
      Navigator.of(context).pop(RewardedAllowanceAction.generate);
      return;
    }
    if (state == RewardedAllowanceFlowState.available) {
      await widget.controller.play(userId: widget.userId);
      if (widget.controller.state == RewardedAllowanceFlowState.playing ||
          widget.controller.state == RewardedAllowanceFlowState.completed) {
        await widget.onPlaybackStarted?.call();
      }
      return;
    }
    await widget.controller.prepare();
  }
}

class _RewardedIllustration extends StatelessWidget {
  const _RewardedIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Md3Colors.primarySoft,
          borderRadius: BorderRadius.circular(Md3Radius.card),
        ),
        child: const Icon(
          Icons.movie_filter_rounded,
          color: Md3Colors.primary,
          size: 30,
        ),
      ),
    );
  }
}

class _RewardedStateNotice extends StatelessWidget {
  const _RewardedStateNotice({required this.state});

  final RewardedAllowanceFlowState state;

  @override
  Widget build(BuildContext context) {
    final (icon, text, color, background) = switch (state) {
      RewardedAllowanceFlowState.available => (
          Icons.check_circle_outline_rounded,
          'A short ad is ready. Your extra deck is saved before MovieDiary builds anything.',
          Md3Colors.success,
          Md3Colors.likedSoft,
        ),
      RewardedAllowanceFlowState.loading => (
          Icons.hourglass_top_rounded,
          'Checking for an ad. You can choose Premium or come back later without waiting.',
          Md3Colors.primary,
          Md3Colors.primarySoft,
        ),
      RewardedAllowanceFlowState.playing => (
          Icons.play_circle_outline_rounded,
          'Finish the ad to unlock one extra deck.',
          Md3Colors.primary,
          Md3Colors.primarySoft,
        ),
      RewardedAllowanceFlowState.completed => (
          Icons.check_circle_rounded,
          'Your extra deck is ready. Start it when you choose—nothing was generated automatically.',
          Md3Colors.success,
          Md3Colors.likedSoft,
        ),
      RewardedAllowanceFlowState.dismissedWithoutReward => (
          Icons.info_outline_rounded,
          'No extra deck was added. You can retry or come back later.',
          Md3Colors.warning,
          Md3Colors.okaySoft,
        ),
      RewardedAllowanceFlowState.failedToLoad => (
          Icons.wifi_off_rounded,
          'A short ad is not available right now. MovieDiary remains fully usable.',
          Md3Colors.warning,
          Md3Colors.okaySoft,
        ),
      RewardedAllowanceFlowState.failedDuringPlayback => (
          Icons.refresh_rounded,
          'The ad could not be completed or saved. No credit was used; try again later.',
          Md3Colors.warning,
          Md3Colors.okaySoft,
        ),
      RewardedAllowanceFlowState.rewardLimitReached => (
          Icons.today_rounded,
          'You have used today’s extra decks. Saved recommendations remain available, and extra decks reset at 00:00 UTC.',
          Md3Colors.muted,
          Md3Colors.surfaceMuted,
        ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key('rewarded-state-${state.name}'),
        padding: const EdgeInsets.all(Md3Spacing.x12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Md3Radius.input),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: Md3Spacing.x8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Md3Colors.text,
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
