import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/price_trend_provider.dart';
import '../services/api_service.dart';
import '../services/item_image_resolver.dart';
import '../widgets/app_state_widget.dart';
import '../widgets/item_image_widget.dart';
import '../widgets/mobile_content.dart';
import '../widgets/price_trend_chart_widget.dart';
import '../widgets/trend_summary_widget.dart';

class PriceTrendScreen extends StatelessWidget {
  const PriceTrendScreen({
    required this.itemCode,
    this.itemName,
    this.unit,
    this.category,
    this.group,
    this.imageResolver,
    this.apiService,
    super.key,
  });
  final int itemCode;
  final String? itemName;
  final String? unit;
  final String? category;
  final String? group;
  final ItemImageResolver? imageResolver;
  final ApiService? apiService;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        PriceTrendProvider(apiService ?? context.read<ApiService>(), itemCode)
          ..load(),
    child: _PriceTrendView(
      itemCode: itemCode,
      itemName: itemName,
      unit: unit,
      category: category,
      group: group,
      imageResolver: imageResolver,
    ),
  );
}

class _PriceTrendView extends StatelessWidget {
  const _PriceTrendView({
    required this.itemCode,
    this.itemName,
    this.unit,
    this.category,
    this.group,
    this.imageResolver,
  });

  final int itemCode;
  final String? itemName;
  final String? unit;
  final String? category;
  final String? group;
  final ItemImageResolver? imageResolver;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.priceTrendTitle)),
    body: MobileContent(
      child: Consumer<PriceTrendProvider>(
        builder: (context, provider, _) => Column(
          children: [
            _PeriodSelector(provider: provider),
            Expanded(child: _buildContent(context, provider)),
          ],
        ),
      ),
    ),
  );

  Widget _buildContent(BuildContext context, PriceTrendProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return AppStateWidget(
        icon: Icons.wifi_off_outlined,
        title: context.l10n.trendUnavailable,
        message: provider.errorMessage!,
        actionLabel: context.l10n.retry,
        onAction: provider.retry,
      );
    }
    final trend = provider.trend;
    if (trend == null || trend.points.isEmpty) {
      return AppStateWidget(
        icon: Icons.query_stats_outlined,
        title: context.l10n.noTrendData,
        message: context.l10n.noTrendMessage,
      );
    }
    if (trend.points.length < 2) {
      return AppStateWidget(
        icon: Icons.timeline_outlined,
        title: context.l10n.moreHistoryTitle,
        message: context.l10n.moreHistoryMessage,
      );
    }

    return ListView(
      key: const ValueKey('price-trend-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
      children: [
        Row(
          children: [
            ItemImage(
              itemCode: itemCode,
              itemName: itemName ?? trend.item.itemName,
              category: category ?? trend.item.itemCategory,
              group: group ?? trend.item.itemGroup,
              width: 58,
              height: 58,
              fit: BoxFit.contain,
              resolver: imageResolver,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName ?? trend.item.itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(unit ?? trend.item.unit),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PriceTrendChartWidget(points: trend.points),
        const SizedBox(height: 22),
        TrendSummaryWidget(trend: trend),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.provider});
  final PriceTrendProvider provider;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      scrollDirection: Axis.horizontal,
      itemCount: TrendRange.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final range = TrendRange.values[index];
        final available = provider.isRangeAvailable(range);
        return ChoiceChip(
          key: ValueKey('trend-range-${range.name}'),
          label: Text(range.label),
          selected: provider.selectedRange == range,
          onSelected: provider.isLoading || !available
              ? null
              : (_) => provider.selectRange(range),
        );
      },
    ),
  );
}
