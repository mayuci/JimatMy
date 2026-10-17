import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/api_service.dart';
import '../services/item_image_resolver.dart';
import '../widgets/app_state_widget.dart';
import '../widgets/item_image_widget.dart';
import '../widgets/jimatmy_ui.dart';
import '../widgets/latest_price_card_widget.dart';
import '../widgets/mobile_content.dart';
import '../widgets/price_freshness_widget.dart';
import 'login_screen.dart';
import 'price_comparison_screen.dart';
import 'price_trend_screen.dart';
import 'store_detail_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({
    required this.itemCode,
    this.imageResolver,
    super.key,
  });
  final int itemCode;
  final ItemImageResolver? imageResolver;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Future<Item> _itemFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final api = context.read<ApiService>();
    _itemFuture = api.getItem(widget.itemCode);
    unawaited(_recordHistoryWhenLoaded(api));
  }

  Future<void> _recordHistoryWhenLoaded(ApiService api) async {
    try {
      final item = await _itemFuture;
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        final profile = Provider.of<ProfileProvider?>(context, listen: false);
        if (profile != null) {
          await profile.recordView(item);
        } else {
          await api.recordItemView(item.itemCode);
        }
      }
    } catch (_) {
      // Loading failures are rendered by FutureBuilder.
    }
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.itemDetailTitle),
      actions: [
        _FavoriteIconButton(itemCode: widget.itemCode, itemFuture: _itemFuture),
      ],
    ),
    body: MobileContent(
      child: FutureBuilder<Item>(
        future: _itemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppStateWidget(
              icon: Icons.wifi_off_outlined,
              title: context.l10n.detailsUnavailable,
              message: snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : context.l10n.itemLoadFailed,
              actionLabel: context.l10n.retry,
              onAction: _retry,
            );
          }
          return _ItemDetails(
            item: snapshot.requireData,
            imageResolver: widget.imageResolver,
          );
        },
      ),
    ),
  );
}

class _ItemDetails extends StatelessWidget {
  const _ItemDetails({required this.item, this.imageResolver});
  final Item item;
  final ItemImageResolver? imageResolver;

  @override
  Widget build(BuildContext context) {
    final values = item.latestPrices.map((price) => price.price).toList();
    final lowest = values.isEmpty ? null : values.reduce(math.min);
    final average = values.isEmpty
        ? null
        : values.reduce((first, second) => first + second) / values.length;
    return ListView(
      key: const ValueKey('item-detail-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      children: [
        Center(
          child: Column(
            children: [
              if (values.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.today_rounded, size: 16),
                  label: Text(context.l10n.dailyPrice),
                  visualDensity: VisualDensity.compact,
                ),
              const SizedBox(height: 8),
              ItemImage(
                itemCode: item.itemCode,
                itemName: item.itemName,
                category: item.itemCategory,
                group: item.itemGroup,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                borderRadius: 28,
                resolver: imageResolver,
              ),
              const SizedBox(height: 18),
              Text(
                item.itemName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: JimatMyColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.unit,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(icon: Icons.category_outlined, label: item.itemCategory),
            _InfoChip(icon: Icons.inventory_2_outlined, label: item.itemGroup),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: context.l10n.summaryLowest,
                value: lowest == null ? '-' : _rm(lowest),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                label: context.l10n.summaryPremises,
                value: '${item.latestPrices.length}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                label: context.l10n.summaryAverage,
                value: average == null ? '-' : _rm(average),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _DetailActionButton(
                filled: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PriceComparisonScreen(itemCode: item.itemCode),
                  ),
                ),
                icon: Icons.compare_arrows_rounded,
                label: context.l10n.priceComparison,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DetailActionButton(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PriceTrendScreen(
                      itemCode: item.itemCode,
                      itemName: item.itemName,
                      unit: item.unit,
                      category: item.itemCategory,
                      group: item.itemGroup,
                      imageResolver: imageResolver,
                    ),
                  ),
                ),
                icon: Icons.show_chart_rounded,
                label: context.l10n.priceTrend,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          context.l10n.latestPrices,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          context.l10n.latestPricesSubtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (item.latestPrices.isEmpty)
          SizedBox(
            height: 210,
            child: AppStateWidget(
              icon: Icons.receipt_long_outlined,
              title: context.l10n.noPricesYet,
              message: context.l10n.noPricesMessage,
              compact: true,
            ),
          )
        else
          ...item.latestPrices.map((price) {
            final premiseCode = price.premiseCode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LatestPriceCardWidget(
                price: price,
                onViewStore: premiseCode == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StoreDetailScreen.fromPremiseCode(
                            premiseCode: premiseCode,
                          ),
                        ),
                      ),
              ),
            );
          }),
        const SizedBox(height: 8),
        PriceFreshnessWidget(reliability: item.reliability),
      ],
    );
  }
}

class _FavoriteIconButton extends StatefulWidget {
  const _FavoriteIconButton({required this.itemCode, required this.itemFuture});
  final int itemCode;
  final Future<Item> itemFuture;

  @override
  State<_FavoriteIconButton> createState() => _FavoriteIconButtonState();
}

class _FavoriteIconButtonState extends State<_FavoriteIconButton> {
  String? _loadedUserId;
  bool _isFavorite = false;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    if (user?.userId == _loadedUserId) return;
    _loadedUserId = user?.userId;
    _isFavorite = false;
    if (user != null) unawaited(_loadStatus());
  }

  Future<void> _loadStatus() async {
    try {
      final profile = Provider.of<ProfileProvider?>(context, listen: false);
      final value = profile == null
          ? await context.read<ApiService>().getFavoriteStatus(widget.itemCode)
          : await profile.loadFavoriteStatus(widget.itemCode);
      if (mounted) setState(() => _isFavorite = value);
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  Future<void> _toggle() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.of(context)
          .push<void>(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final previous = _isFavorite;
    final desired = !previous;
    setState(() {
      _isFavorite = desired;
      _loading = true;
    });
    try {
      final profile = Provider.of<ProfileProvider?>(context, listen: false);
      if (profile != null) {
        final item = await widget.itemFuture;
        final error = await profile.setFavorite(
          item,
          desired,
          knownCurrent: previous,
        );
        if (error != null) throw ApiException(error);
      } else if (desired) {
        await context.read<ApiService>().addFavoriteItem(widget.itemCode);
      } else {
        await context.read<ApiService>().removeFavoriteItem(widget.itemCode);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isFavorite = previous);
        _showError(error.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _isFavorite
        ? context.l10n.removeFromFavourites
        : context.l10n.addToFavourites,
    onPressed: _loading ? null : _toggle,
    icon: _loading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
  );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 82,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: JimatMyColors.green,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: filled ? colors.primary : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.primary),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: filled ? colors.onPrimary : colors.primary),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: filled ? colors.onPrimary : colors.primary,
                    fontWeight: FontWeight.w800,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 17),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

String _rm(double value) => 'RM ${value.toStringAsFixed(2)}';
