import 'dart:async';

import 'package:flutter/material.dart';

import '../models/item.dart';
import '../screens/item_detail_screen.dart';
import '../services/api_service.dart';
import 'item_image_widget.dart';

class _PromotionItemConfig {
  const _PromotionItemConfig(this.itemCode);

  final int itemCode;
}

class _LoadedPromotion {
  const _LoadedPromotion({required this.config, required this.item});

  final _PromotionItemConfig config;
  final Item item;
}

class PromotionCarousel extends StatefulWidget {
  const PromotionCarousel({
    required this.apiService,
    this.onItemsLoaded,
    super.key,
  });

  final ApiService apiService;
  final ValueChanged<List<Item>>? onItemsLoaded;

  @override
  State<PromotionCarousel> createState() => _PromotionCarouselState();
}

class _PromotionCarouselState extends State<PromotionCarousel> {
  static const _configs = [
    _PromotionItemConfig(1),
    _PromotionItemConfig(1559),
    _PromotionItemConfig(1109),
    _PromotionItemConfig(1582),
    _PromotionItemConfig(1440),
  ];

  final _pageController = PageController();
  late Future<List<_LoadedPromotion>> _promotionsFuture;
  Timer? _timer;
  int _currentPage = 0;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _promotionsFuture = _loadPromotions();
  }

  Future<List<_LoadedPromotion>> _loadPromotions() async {
    final promotions = await Future.wait(
      _configs.map((config) async {
        try {
          final item = await widget.apiService.getItem(config.itemCode);
          if (item.itemGroup.trim().toUpperCase() == 'MAKANAN SIAP MASAK') {
            return null;
          }
          return _LoadedPromotion(config: config, item: item);
        } catch (_) {
          return null;
        }
      }),
    );
    final loaded = promotions.whereType<_LoadedPromotion>().toList();
    if (mounted) {
      widget.onItemsLoaded?.call(
        loaded.map((promotion) => promotion.item).toList(growable: false),
      );
    }
    if (loaded.isNotEmpty && mounted) {
      _startAutoAdvance(loaded.length);
    }
    return loaded;
  }

  void _startAutoAdvance(int itemCount) {
    _timer?.cancel();
    if (itemCount < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _isInteracting || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % itemCount;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  void _setInteraction(bool value, int itemCount) {
    _isInteracting = value;
    if (value) {
      _timer?.cancel();
    } else {
      _startAutoAdvance(itemCount);
    }
  }

  void _openItem(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ItemDetailScreen(itemCode: item.itemCode),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 212,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF167D55), Color(0xFF0D6848)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: FutureBuilder<List<_LoadedPromotion>>(
        future: _promotionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          final promotions = snapshot.data ?? const <_LoadedPromotion>[];
          if (promotions.isEmpty) {
            return const Center(
              child: Icon(
                Icons.shopping_basket_rounded,
                color: Color(0xFFF4C95D),
                size: 60,
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: Listener(
                  onPointerDown: (_) =>
                      _setInteraction(true, promotions.length),
                  onPointerUp: (_) => _setInteraction(false, promotions.length),
                  onPointerCancel: (_) =>
                      _setInteraction(false, promotions.length),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: promotions.length,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    itemBuilder: (context, index) {
                      final promotion = promotions[index];
                      return _PromotionSlideCard(
                        promotion: promotion,
                        onOpen: () => _openItem(promotion.item),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  promotions.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _currentPage ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? const Color(0xFFF4C95D)
                          : Colors.white54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PromotionSlideCard extends StatelessWidget {
  const _PromotionSlideCard({required this.promotion, required this.onOpen});

  final _LoadedPromotion promotion;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final item = promotion.item;
    final cheapest = item.latestPrices.isEmpty ? null : item.latestPrices.first;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      cheapest == null
                          ? 'Price unavailable'
                          : 'From RM ${cheapest.price.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF4C95D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (cheapest != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        cheapest.premiseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 30,
                      child: FilledButton.tonal(
                        onPressed: onOpen,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Compare now'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ItemImage(
                itemCode: item.itemCode,
                itemName: item.itemName,
                category: item.itemCategory,
                group: item.itemGroup,
                width: 116,
                height: 132,
                borderRadius: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
