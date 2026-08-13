import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:provider/provider.dart';

const _premiumProductId = 'premium_purchase';

class PremiumStoreProduct {
  final String id;
  final String localizedPrice;
  final Object? platformProduct;

  const PremiumStoreProduct({
    required this.id,
    required this.localizedPrice,
    this.platformProduct,
  });
}

enum PremiumPurchaseStatus {
  pending,
  purchased,
  restored,
  cancelled,
  error,
}

class PremiumPurchaseUpdate {
  final PremiumPurchaseStatus status;
  final String? message;

  const PremiumPurchaseUpdate(this.status, {this.message});
}

abstract interface class PremiumStore {
  Stream<PremiumPurchaseUpdate> get purchaseUpdates;

  Future<bool> isAvailable();

  Future<PremiumStoreProduct?> loadPremiumProduct();

  Future<bool> purchase(PremiumStoreProduct product);

  Future<void> restorePurchases();
}

class InAppPurchasePremiumStore implements PremiumStore {
  final InAppPurchase _purchase;

  InAppPurchasePremiumStore({InAppPurchase? purchase})
      : _purchase = purchase ?? InAppPurchase.instance;

  @override
  Stream<PremiumPurchaseUpdate> get purchaseUpdates =>
      _purchase.purchaseStream.expand((purchases) sync* {
        for (final purchase in purchases) {
          if (purchase.productID != _premiumProductId) {
            continue;
          }

          yield switch (purchase.status) {
            PurchaseStatus.pending => const PremiumPurchaseUpdate(
                PremiumPurchaseStatus.pending,
              ),
            PurchaseStatus.purchased => const PremiumPurchaseUpdate(
                PremiumPurchaseStatus.purchased,
              ),
            PurchaseStatus.restored => const PremiumPurchaseUpdate(
                PremiumPurchaseStatus.restored,
              ),
            PurchaseStatus.canceled => const PremiumPurchaseUpdate(
                PremiumPurchaseStatus.cancelled,
              ),
            PurchaseStatus.error => PremiumPurchaseUpdate(
                PremiumPurchaseStatus.error,
                message: purchase.error?.message,
              ),
          };
        }
      });

  @override
  Future<bool> isAvailable() => _purchase.isAvailable();

  @override
  Future<PremiumStoreProduct?> loadPremiumProduct() async {
    final response = await _purchase.queryProductDetails(
      const {_premiumProductId},
    );
    if (response.error != null) {
      throw StateError(response.error!.message);
    }
    if (response.notFoundIDs.contains(_premiumProductId) ||
        response.productDetails.isEmpty) {
      return null;
    }

    final details = response.productDetails.firstWhere(
      (product) => product.id == _premiumProductId,
      orElse: () => response.productDetails.first,
    );
    return PremiumStoreProduct(
      id: details.id,
      localizedPrice: details.price,
      platformProduct: details,
    );
  }

  @override
  Future<bool> purchase(PremiumStoreProduct product) {
    final details = product.platformProduct;
    if (details is! ProductDetails) {
      throw StateError('The app store product could not be opened.');
    }
    return _purchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @override
  Future<void> restorePurchases() => _purchase.restorePurchases();
}

class Premium extends StatefulWidget {
  final PremiumStore? store;

  const Premium({super.key, this.store});

  @override
  State<Premium> createState() => _PremiumState();
}

class _PremiumState extends State<Premium> {
  late final PremiumStore _store;
  StreamSubscription<PremiumPurchaseUpdate>? _purchaseSubscription;
  PremiumStoreProduct? _product;
  PremiumPurchaseUpdate? _lastPurchaseUpdate;
  bool _catalogLoading = true;
  bool _storeUnavailable = false;
  bool _purchaseRequestPending = false;
  String? _restoreNote;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? InAppPurchasePremiumStore();
    _purchaseSubscription = _store.purchaseUpdates.listen(
      _handlePurchaseUpdate,
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) {
          return;
        }
        setState(() {
          _purchaseRequestPending = false;
          _lastPurchaseUpdate = PremiumPurchaseUpdate(
            PremiumPurchaseStatus.error,
            message: '$error',
          );
        });
      },
    );
    unawaited(_loadCatalog());
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    if (mounted) {
      setState(() {
        _catalogLoading = true;
        _storeUnavailable = false;
        _restoreNote = null;
      });
    }

    try {
      final available = await _store.isAvailable();
      if (!available) {
        _setCatalogUnavailable();
        return;
      }

      final product = await _store.loadPremiumProduct();
      if (product == null || product.localizedPrice.trim().isEmpty) {
        _setCatalogUnavailable();
        return;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _product = product;
        _catalogLoading = false;
        _storeUnavailable = false;
      });
    } catch (error) {
      debugPrint('Premium catalog could not be loaded: $error');
      _setCatalogUnavailable();
    }
  }

  void _setCatalogUnavailable() {
    if (!mounted) {
      return;
    }
    setState(() {
      _product = null;
      _catalogLoading = false;
      _storeUnavailable = true;
      _purchaseRequestPending = false;
    });
  }

  void _handlePurchaseUpdate(PremiumPurchaseUpdate update) {
    if (!mounted) {
      return;
    }

    setState(() {
      _lastPurchaseUpdate = update;
      _restoreNote = null;
      _purchaseRequestPending = update.status == PremiumPurchaseStatus.pending;
    });

    if (update.status == PremiumPurchaseStatus.purchased ||
        update.status == PremiumPurchaseStatus.restored) {
      unawaited(
        Provider.of<UserState>(context, listen: false).setPremium(true),
      );
    }
  }

  Future<void> _purchasePremium() async {
    final product = _product;
    if (product == null || _purchaseRequestPending) {
      return;
    }

    setState(() {
      _purchaseRequestPending = true;
      _lastPurchaseUpdate = const PremiumPurchaseUpdate(
        PremiumPurchaseStatus.pending,
      );
      _restoreNote = null;
    });

    try {
      final started = await _store.purchase(product);
      if (!started && mounted) {
        setState(() {
          _purchaseRequestPending = false;
          _lastPurchaseUpdate = const PremiumPurchaseUpdate(
            PremiumPurchaseStatus.error,
          );
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _purchaseRequestPending = false;
        _lastPurchaseUpdate = PremiumPurchaseUpdate(
          PremiumPurchaseStatus.error,
          message: '$error',
        );
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (_purchaseRequestPending) {
      return;
    }

    setState(() {
      _purchaseRequestPending = true;
      _restoreNote = 'Checking your store for a previous purchase…';
    });

    try {
      await _store.restorePurchases();
      if (!mounted) {
        return;
      }
      setState(() {
        _purchaseRequestPending = false;
        _restoreNote =
            'Restore requested. Premium will update if your store finds a purchase.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _purchaseRequestPending = false;
        _lastPurchaseUpdate = PremiumPurchaseUpdate(
          PremiumPurchaseStatus.error,
          message: '$error',
        );
        _restoreNote = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final isOwned = userState.isPremium == true;
    final globalKey = GlobalKey();
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      MyGlobals.activeKey = globalKey;
    }

    return Scaffold(
      key: globalKey,
      backgroundColor: Md3Colors.background,
      appBar: AppBar(
        title: const Text('Premium'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Md3Layout.pageHorizontalInset(context),
            8,
            Md3Layout.pageHorizontalInset(context),
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PremiumHeroCard(isOwned: isOwned),
              const SizedBox(height: 16),
              const _PremiumBenefitsCard(),
              const SizedBox(height: 16),
              _buildStoreCard(isOwned),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isOwned ? null : _buildPrimaryChrome(),
    );
  }

  Widget _buildStoreCard(bool isOwned) {
    final status = _storeCardStatus(isOwned);
    final canRestore = !isOwned &&
        !_catalogLoading &&
        !_storeUnavailable &&
        !_purchaseRequestPending &&
        _product != null;

    return Md3Card(
      key: const Key('premiumStoreCard'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: status.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(status.icon, color: status.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.title,
                      style: const TextStyle(
                        color: Md3Colors.text,
                        fontSize: 20,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status.body,
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_catalogLoading && !isOwned) ...[
            const SizedBox(height: 18),
            const LinearProgressIndicator(minHeight: 4),
          ],
          if (_restoreNote != null && !isOwned) ...[
            const SizedBox(height: 14),
            Text(
              _restoreNote!,
              key: const Key('premiumRestoreNote'),
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          if (canRestore) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('premiumRestoreAction'),
                onPressed: _restorePurchases,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Restore a previous purchase'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _PremiumStoreCardStatus _storeCardStatus(bool isOwned) {
    if (isOwned) {
      return const _PremiumStoreCardStatus(
        title: 'Premium active',
        body:
            'Ads are removed and Premium is active for this MovieDiary profile.',
        icon: Icons.check_rounded,
        color: Md3Colors.success,
        background: Color(0xffe9f7ef),
      );
    }
    if (_catalogLoading) {
      return const _PremiumStoreCardStatus(
        title: 'Checking your store',
        body: 'Loading the current Premium product and localized price.',
        icon: Icons.storefront_outlined,
        color: Md3Colors.primary,
        background: Md3Colors.primarySoft,
      );
    }
    if (_storeUnavailable || _product == null) {
      return const _PremiumStoreCardStatus(
        title: 'Store unavailable',
        body:
            'Premium could not be loaded from your app store. Check your connection, then try again.',
        icon: Icons.cloud_off_rounded,
        color: Md3Colors.warning,
        background: Color(0xfffff4dc),
      );
    }
    if (_purchaseRequestPending ||
        _lastPurchaseUpdate?.status == PremiumPurchaseStatus.pending) {
      return const _PremiumStoreCardStatus(
        title: 'Purchase pending',
        body:
            'Your app store is processing the purchase. Premium will update after confirmation.',
        icon: Icons.hourglass_top_rounded,
        color: Md3Colors.primary,
        background: Md3Colors.primarySoft,
      );
    }
    if (_lastPurchaseUpdate?.status == PremiumPurchaseStatus.error ||
        _lastPurchaseUpdate?.status == PremiumPurchaseStatus.cancelled) {
      return _PremiumStoreCardStatus(
        title: 'Purchase not completed',
        body: _purchaseFailureCopy(),
        icon: Icons.info_outline_rounded,
        color: Md3Colors.warning,
        background: const Color(0xfffff4dc),
      );
    }

    return _PremiumStoreCardStatus(
      title: 'Unlock Premium',
      body:
          '${_product!.localizedPrice} from your app store. Payment and confirmation stay with your store account.',
      icon: Icons.workspace_premium_rounded,
      color: Md3Colors.primary,
      background: Md3Colors.primarySoft,
    );
  }

  String _purchaseFailureCopy() {
    if (_lastPurchaseUpdate?.status == PremiumPurchaseStatus.cancelled) {
      return 'Nothing was charged. You can try again whenever you are ready.';
    }
    final message = _lastPurchaseUpdate?.message?.trim() ?? '';
    if (message.isEmpty) {
      return 'Your app store did not complete the purchase. Check your connection and try again.';
    }
    return 'Your app store did not complete the purchase. $message';
  }

  Widget _buildPrimaryChrome() {
    final product = _product;
    final canPurchase = !_catalogLoading &&
        !_storeUnavailable &&
        !_purchaseRequestPending &&
        product != null;
    final label = switch ((
      _catalogLoading,
      _storeUnavailable || product == null,
      _purchaseRequestPending
    )) {
      (true, _, _) => 'Checking store…',
      (_, true, _) => 'Try again',
      (_, _, true) => 'Purchase pending',
      _ => 'Unlock Premium · ${product!.localizedPrice}',
    };
    final action = _storeUnavailable || (!_catalogLoading && product == null)
        ? _loadCatalog
        : canPurchase
            ? _purchasePremium
            : null;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Md3LiquidGlass(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(10),
        child: FilledButton(
          key: const Key('premiumPrimaryAction'),
          onPressed: action,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.fade,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _PremiumHeroCard extends StatelessWidget {
  final bool isOwned;

  const _PremiumHeroCard({required this.isOwned});

  @override
  Widget build(BuildContext context) {
    return Md3Card(
      key: const Key('premiumHeroCard'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isOwned ? const Color(0xffe9f7ef) : Md3Colors.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isOwned
                  ? Icons.check_circle_rounded
                  : Icons.workspace_premium_rounded,
              color: isOwned ? Md3Colors.success : Md3Colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isOwned ? 'Premium is yours' : 'A quieter MovieDiary',
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOwned
                ? 'Thank you for supporting MovieDiary. Your supported Premium benefits are active.'
                : 'Remove ads and support the team behind MovieDiary with one clear purchase.',
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBenefitsCard extends StatelessWidget {
  const _PremiumBenefitsCard();

  @override
  Widget build(BuildContext context) {
    return const Md3Card(
      key: Key('premiumBenefitsCard'),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Premium includes',
            style: TextStyle(
              color: Md3Colors.text,
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 16),
          _PremiumBenefitRow(
            icon: Icons.block_rounded,
            title: 'Remove ads',
            body: 'Browse, rate, and track movies without in-app ads.',
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _PremiumBenefitRow(
            icon: Icons.favorite_outline_rounded,
            title: 'Support MovieDiary',
            body: 'Your purchase directly supports the MovieDiary team.',
          ),
        ],
      ),
    );
  }
}

class _PremiumBenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PremiumBenefitRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Md3Colors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Md3Colors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Md3Colors.text,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumStoreCardStatus {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final Color background;

  const _PremiumStoreCardStatus({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.background,
  });
}
