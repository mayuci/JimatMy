import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../models/planner_models.dart';
import '../models/price_trend.dart';
import '../l10n/l10n.dart';
import '../providers/app_location_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/planner_provider.dart';
import '../services/api_service.dart';
import '../widgets/basket_template_section_widget.dart';
import '../widgets/jimatmy_ui.dart';
import '../widgets/item_image_widget.dart';
import '../widgets/item_list_tile_widget.dart';
import '../widgets/location_onboarding_widget.dart';
import '../widgets/mobile_content.dart';
import '../widgets/promotion_carousel.dart';
import 'item_detail_screen.dart';
import 'login_screen.dart';
import 'nearby_stores_screen.dart';
import 'search_screen.dart';
import 'shopping_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({this.onOpenPlanner, super.key});
  final VoidCallback? onOpenPlanner;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _lowestPricesController = ScrollController();
  static const _categories = <_HomeCategory>[
    _HomeCategory(
      'Fresh Food',
      'fresh-food',
      Icons.set_meal_rounded,
      'assets/images/products/DadaAyam.jpg',
    ),
    _HomeCategory(
      'Vegetables',
      'vegetables',
      Icons.eco_rounded,
      'assets/images/products/brokoli.jpg',
    ),
    _HomeCategory(
      'Fruits',
      'fruits',
      Icons.apple_rounded,
      'assets/images/products/AnggurHijauBerbiji.jpg',
    ),
    _HomeCategory(
      'Eggs',
      'eggs',
      Icons.egg_alt_rounded,
      'assets/images/featured/telur_ayam_gred_a.webp',
    ),
    _HomeCategory(
      'Drinks',
      'drinks',
      Icons.local_drink_rounded,
      'assets/images/products/100Plus-1.5L.jpg',
    ),
    _HomeCategory(
      'Dry Goods',
      'dry-goods',
      Icons.rice_bowl_rounded,
      'assets/images/featured/beras_jasmine.webp',
    ),
    _HomeCategory(
      'Baby Products',
      'baby',
      Icons.child_friendly_rounded,
      'assets/images/products/dumex dugro 2 850g.jpg',
    ),
    _HomeCategory(
      'Household',
      'household',
      Icons.cleaning_services_rounded,
      'assets/images/products/berus gigi colgate twister soft.jpg',
    ),
  ];

  List<Item> _featuredItems = const [];
  bool _featuredLoaded = false;
  PriceTrend? _insightTrend;
  List<BasketTemplate> _basketTemplates = const [];
  bool _basketsLoading = true;
  int _refreshVersion = 0;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _searchLayerLink = LayerLink();
  final _searchBarKey = GlobalKey();
  Timer? _searchDebounce;
  int _searchRequestVersion = 0;
  List<Item> _searchSuggestions = const [];
  bool _searchSuggestionsLoading = false;
  String _searchQuery = '';
  double _searchBarWidth = 0;
  double _searchBarHeight = 0;
  OverlayEntry? _searchOverlayEntry;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_handleSearchFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBaskets());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchOverlayEntry?.remove();
    _searchController.dispose();
    _searchFocus.dispose();
    _lowestPricesController.dispose();
    super.dispose();
  }

  Future<void> _loadBaskets() async {
    final version = _refreshVersion;
    if (mounted) setState(() => _basketsLoading = true);
    try {
      final templates = await context.read<ApiService>().getBasketTemplates();
      if (!mounted || version != _refreshVersion) return;
      setState(() => _basketTemplates = templates);
    } catch (_) {
      if (!mounted || version != _refreshVersion) return;
      setState(() => _basketTemplates = const []);
    } finally {
      if (mounted && version == _refreshVersion) {
        setState(() => _basketsLoading = false);
      }
    }
  }

  Future<void> _previewBasket(BasketTemplate template) async {
    final create = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.name,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(context.l10n.homeBasketIntro(template.household)),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: template.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = template.items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        item.itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} x ${item.unit}',
                      ),
                      trailing: Text(
                        item.estimatedLineTotal == null
                            ? context.l10n.unavailable
                            : 'RM ${item.estimatedLineTotal!.toStringAsFixed(2)}',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(
                    context.l10n.homeCreateBasket(
                      'RM ${template.estimatedTotal.toStringAsFixed(2)}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (create != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    final planner = context.read<PlannerProvider>();
    final created = await planner.createFromTemplate(template.templateKey);
    if (!mounted) return;
    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            planner.errorMessage ?? context.l10n.homeBasketCreateFailed,
          ),
        ),
      );
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListScreen(listId: created.shoppingListId),
      ),
    );
  }

  void _openSearch({
    String? category,
    SearchDestination destination = SearchDestination.itemDetail,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SearchScreen(initialCategory: category, destination: destination),
      ),
    );
  }

  void _openItem(Item item) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ItemDetailScreen(itemCode: item.itemCode),
    ),
  );

  void _handleSearchFocusChange() {
    if (_searchFocus.hasFocus) {
      final query = _searchQuery.trim();
      if (query.isEmpty) return;
      if (_searchSuggestions.isEmpty && !_searchSuggestionsLoading) {
        _fetchHomeSearchSuggestions(query);
      } else {
        _showSearchOverlay();
      }
      if (mounted) setState(() {});
    } else {
      _dismissSearchOverlay();
      if (mounted) setState(() {});
    }
  }

  void _onHomeSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    _searchQuery = query;
    _searchRequestVersion++;
    if (query.isEmpty) {
      _searchSuggestions = const [];
      _searchSuggestionsLoading = false;
      _dismissSearchOverlay();
      if (mounted) setState(() {});
      return;
    }
    _searchSuggestions = const [];
    _searchSuggestionsLoading = true;
    _showSearchOverlay();
    if (mounted) setState(() {});
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _fetchHomeSearchSuggestions(query),
    );
  }

  Future<void> _fetchHomeSearchSuggestions(String query) async {
    final version = ++_searchRequestVersion;
    try {
      final page = await context.read<ApiService>().getItems(
        query: query,
        limit: 6,
        offset: 0,
      );
      if (!mounted || version != _searchRequestVersion) return;
      setState(() {
        _searchSuggestions = page.items;
        _searchSuggestionsLoading = false;
      });
      if (_searchQuery.trim() == query) _showSearchOverlay();
    } on ApiException {
      if (!mounted || version != _searchRequestVersion) return;
      setState(() {
        _searchSuggestions = const [];
        _searchSuggestionsLoading = false;
      });
    }
  }

  void _showSearchOverlay() {
    final query = _searchQuery.trim();
    if (query.isEmpty || !_searchFocus.hasFocus) return;
    _updateSearchBarMetrics();
    if (_searchBarWidth <= 0 || _searchBarHeight <= 0) return;
    if (_searchOverlayEntry != null) {
      _searchOverlayEntry!.markNeedsBuild();
      return;
    }
    _searchOverlayEntry = OverlayEntry(builder: (_) => _buildSearchOverlay());
    Overlay.of(context).insert(_searchOverlayEntry!);
  }

  void _updateSearchBarMetrics() {
    final box = _searchBarKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      _searchBarWidth = box.size.width;
      _searchBarHeight = box.size.height;
    }
  }

  Widget _buildSearchOverlay() => Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismissSearchOverlay,
        ),
      ),
      CompositedTransformFollower(
        link: _searchLayerLink,
        showWhenUnlinked: false,
        offset: Offset(0, _searchBarHeight + 6),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: _searchBarWidth,
            child: _HomeSearchSuggestionPanel(
              loading: _searchSuggestionsLoading,
              items: _searchSuggestions,
              onSelected: _openSearchSuggestion,
            ),
          ),
        ),
      ),
    ],
  );

  void _dismissSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  void _clearHomeSearch() {
    _searchController.clear();
    _onHomeSearchChanged('');
    _searchFocus.requestFocus();
  }

  void _openSearchSuggestion(Item item) {
    _searchDebounce?.cancel();
    _dismissSearchOverlay();
    _searchController.clear();
    _searchFocus.unfocus();
    _searchQuery = '';
    _searchSuggestions = const [];
    _searchSuggestionsLoading = false;
    if (mounted) setState(() {});
    _openItem(item);
  }

  void _submitHomeSearch(String _) {
    if (_searchSuggestions.isNotEmpty) {
      _openSearchSuggestion(_searchSuggestions.first);
    }
  }

  void _handleFeaturedItems(List<Item> items) {
    if (!mounted) return;
    final pricedItems = items
        .where((item) => item.latestPrices.isNotEmpty)
        .toList(growable: false);
    setState(() {
      _featuredItems = pricedItems;
      _featuredLoaded = true;
    });
    if (pricedItems.isNotEmpty) {
      _loadInsight(pricedItems.first.itemCode, _refreshVersion);
    }
  }

  Future<void> _loadInsight(int itemCode, int version) async {
    try {
      final trend = await context.read<ApiService>().getPriceTrend(itemCode);
      if (!mounted || version != _refreshVersion) return;
      setState(() => _insightTrend = trend.points.length >= 2 ? trend : null);
    } catch (_) {
      if (mounted && version == _refreshVersion) {
        setState(() => _insightTrend = null);
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshVersion++;
      _featuredItems = const [];
      _featuredLoaded = false;
      _insightTrend = null;
      _basketsLoading = true;
    });
    await _loadBaskets();
  }

  @override
  Widget build(BuildContext context) => LocationOnboardingHost(
    child: Scaffold(
      body: MobileContent(
        safeArea: true,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                sliver: SliverList.list(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildSearchEntry(),
                    const SizedBox(height: 18),
                    PromotionCarousel(
                      key: ValueKey(_refreshVersion),
                      apiService: context.read<ApiService>(),
                      onItemsLoaded: _handleFeaturedItems,
                    ),
                    const SizedBox(height: 22),
                    _buildQuickActions(),
                    const SizedBox(height: 26),
                    JimatMySectionTitle(
                      title: context.l10n.homeLowestPricesTitle,
                    ),
                    const SizedBox(height: 12),
                    _buildLowestPrices(),
                    if (_buildInsight() case final insight?) ...[
                      const SizedBox(height: 22),
                      insight,
                    ],
                    const SizedBox(height: 26),
                    JimatMySectionTitle(
                      title: context.l10n.homePopularCategories,
                    ),
                    const SizedBox(height: 12),
                    _buildCategories(),
                    const SizedBox(height: 26),
                    JimatMySectionTitle(
                      title: context.l10n.homeWeeklyBasketTitle,
                      action: widget.onOpenPlanner == null
                          ? null
                          : TextButton(
                              onPressed: widget.onOpenPlanner,
                              child: Text(context.l10n.navPlanner),
                            ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.l10n.homeWeeklyBasketSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    BasketTemplateSection(
                      templates: _basketTemplates,
                      isLoading: _basketsLoading,
                      onSelect: _previewBasket,
                      onRetry: _loadBaskets,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(fit: BoxFit.scaleDown, child: JimatMyMark()),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Consumer<AppLocationProvider?>(
              builder: (context, location, _) => ActionChip(
                tooltip: context.l10n.homeChooseLocation,
                avatar: Icon(
                  location?.hasDeviceLocation == true
                      ? Icons.location_on_rounded
                      : Icons.location_on_outlined,
                  size: 18,
                  color: JimatMyColors.green,
                ),
                label: Text(
                  location?.locationLabel ?? context.l10n.homeSelectLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: location == null
                    ? null
                    : () => showLocationOnboardingSheet(context),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        context.l10n.appTagline,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(color: JimatMyColors.ink, fontWeight: FontWeight.w900),
      ),
    ],
  );

  Widget _buildSearchEntry() => CompositedTransformTarget(
    key: _searchBarKey,
    link: _searchLayerLink,
    child: TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      textInputAction: TextInputAction.search,
      onChanged: _onHomeSearchChanged,
      onSubmitted: _submitHomeSearch,
      decoration: InputDecoration(
        hintText: context.l10n.homeSearchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clearHomeSearch,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    ),
  );

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        context.l10n.homeQuickCompare,
        Icons.compare_arrows_rounded,
        const Color(0xFFE0F3E8),
        () => _openSearch(destination: SearchDestination.comparison),
      ),
      _QuickAction(
        context.l10n.homeQuickPlanner,
        Icons.shopping_cart_checkout_rounded,
        const Color(0xFFFFF1C7),
        widget.onOpenPlanner ?? () {},
      ),
      _QuickAction(
        context.l10n.homeQuickTrends,
        Icons.trending_up_rounded,
        const Color(0xFFE8EEFF),
        () => _openSearch(destination: SearchDestination.trend),
      ),
      _QuickAction(
        context.l10n.homeQuickNearby,
        Icons.storefront_rounded,
        const Color(0xFFFFE8DF),
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NearbyStoresScreen()),
        ),
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: _QuickActionCard(action: actions[index])),
        ],
      ],
    );
  }

  Widget _buildLowestPrices() {
    if (_featuredItems.isEmpty) {
      if (_featuredLoaded) {
        return Container(
          height: 118,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: JimatMyColors.mint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.price_check_rounded, color: JimatMyColors.green),
              const SizedBox(width: 12),
              Expanded(child: Text(context.l10n.homeNoPrices)),
              TextButton(
                onPressed: _openSearch,
                child: Text(context.l10n.navSearch),
              ),
            ],
          ),
        );
      }
      return const SizedBox(
        height: 218,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SizedBox(
      height: 230,
      child: Scrollbar(
        controller: _lowestPricesController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 3,
        radius: const Radius.circular(8),
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ListView.separated(
            controller: _lowestPricesController,
            key: const ValueKey('lowest-prices-list'),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: math.min(_featuredItems.length, 6),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _featuredItems[index];
              return _LowestPriceCard(item: item, onTap: () => _openItem(item));
            },
          ),
        ),
      ),
    );
  }

  Widget? _buildInsight() {
    final trend = _insightTrend;
    final change = trend?.percentageChange;
    if (trend == null || change == null || !change.isFinite) return null;
    final direction = change.abs() < .05
        ? context.l10n.homeInsightStable
        : change < 0
        ? context.l10n.homeInsightDecreased(change.abs().toStringAsFixed(1))
        : context.l10n.homeInsightIncreased(change.abs().toStringAsFixed(1));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JimatMyColors.mint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: JimatMyColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeInsightTitle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: JimatMyColors.deepGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.homeInsightSentence(
                    trend.item.itemName,
                    direction,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _categories.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 10,
      childAspectRatio: .76,
    ),
    itemBuilder: (context, index) {
      final category = _categories[index];
      return _CategoryShortcut(
        category: category,
        onTap: () => _openSearch(category: category.key),
      );
    },
  );
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 104,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: action.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Icon(
                    action.icon,
                    size: 21,
                    color: JimatMyColors.deepGreen,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                action.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w800, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LowestPriceCard extends StatelessWidget {
  const _LowestPriceCard({required this.item, required this.onTap});
  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = item.latestPrices.isEmpty ? null : item.latestPrices.first;
    return SizedBox(
      width: 158,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: ItemImage(
                      itemCode: item.itemCode,
                      itemName: item.itemName,
                      category: item.itemCategory,
                      group: item.itemGroup,
                      width: 94,
                      height: 86,
                      borderRadius: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  item.unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 5),
                Text(
                  price == null
                      ? context.l10n.priceUnavailable
                      : 'RM ${price.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: JimatMyColors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  price?.premiseName ?? context.l10n.noCurrentPremise,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

String _categoryLabel(BuildContext context, _HomeCategory category) =>
    switch (category.key) {
      'fresh-food' => context.l10n.homeCategoryFreshFood,
      'vegetables' => context.l10n.homeCategoryVegetables,
      'fruits' => context.l10n.homeCategoryFruits,
      'eggs' => context.l10n.homeCategoryEggs,
      'drinks' => context.l10n.homeCategoryDrinks,
      'dry-goods' => context.l10n.homeCategoryDryGoods,
      'baby' => context.l10n.homeCategoryBaby,
      'household' => context.l10n.homeCategoryHousehold,
      _ => category.label,
    };

class _HomeSearchSuggestionPanel extends StatelessWidget {
  const _HomeSearchSuggestionPanel({
    required this.loading,
    required this.items,
    required this.onSelected,
  });

  final bool loading;
  final List<Item> items;
  final ValueChanged<Item> onSelected;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (loading) {
      content = const SizedBox(
        height: 64,
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (items.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(context.l10n.homeSearchNoResults)),
          ],
        ),
      );
    } else {
      content = ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 336),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: items.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, indent: 12, endIndent: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return ItemListTileWidget(
              item: item,
              onTap: () => onSelected(item),
            );
          },
        ),
      );
    }
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: content,
    );
  }
}

class _HomeCategory {
  const _HomeCategory(this.label, this.key, this.icon, this.asset);
  final String label;
  final String key;
  final IconData icon;
  final String asset;
}

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({required this.category, required this.onTap});
  final _HomeCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    color: JimatMyColors.mint,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    category.asset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Center(
                      child: Icon(
                        category.icon,
                        color: JimatMyColors.green,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _categoryLabel(context, category),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700, height: 1.1),
            ),
          ],
        ),
      ),
    ),
  );
}
