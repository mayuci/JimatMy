import 'dart:async';

import 'package:flutter/material.dart';

import '../models/item.dart';
import '../services/api_service.dart';
import '../screens/item_detail_screen.dart';
import 'jimatmy_ui.dart';
import 'item_image_widget.dart';

class FeaturedPriceCarouselWidget extends StatefulWidget {
  const FeaturedPriceCarouselWidget({required this.apiService, super.key});

  final ApiService apiService;

  @override
  State<FeaturedPriceCarouselWidget> createState() =>
      _FeaturedPriceCarouselWidgetState();
}

class _FeaturedPriceCarouselWidgetState
    extends State<FeaturedPriceCarouselWidget> {
  static const _itemCodes = [1, 1559, 1109, 1582, 1440];
  final _pageController = PageController();
  Timer? _timer;
  List<Item> _items = const [];
  int _page = 0;
  bool _interacting = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final results = await Future.wait(
      _itemCodes.map((code) async {
        try {
          final item = await widget.apiService.getItem(code);
          if (item.itemGroup.trim().toUpperCase() == 'MAKANAN SIAP MASAK') {
            return null;
          }
          return item;
        } catch (_) {
          return null;
        }
      }),
    );
    if (!mounted) return;
    setState(() => _items = results.whereType<Item>().toList(growable: false));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_items.length < 2 || _interacting) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _interacting || !_pageController.hasClients) return;
      final next = (_page + 1) % _items.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  void _setInteracting(bool value) {
    if (_interacting == value) return;
    setState(() => _interacting = value);
    if (value) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _open(Item item) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ItemDetailScreen(itemCode: item.itemCode),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const SizedBox(
        height: 206,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 178,
          child: Listener(
            onPointerDown: (_) => _setInteracting(true),
            onPointerUp: (_) => _setInteracting(false),
            onPointerCancel: (_) => _setInteracting(false),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final item = _items[index];
                final price = item.latestPrices.isEmpty
                    ? null
                    : item.latestPrices.first;
                return InkWell(
                  onTap: () => _open(item),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        ItemImage(
                          itemCode: item.itemCode,
                          itemName: item.itemName,
                          category: item.itemCategory,
                          group: item.itemGroup,
                          width: 108,
                          height: 128,
                          borderRadius: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.itemName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.unit,
                                style: const TextStyle(
                                  color: Color(0xFFD9F5E2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                price == null
                                    ? 'Price unavailable'
                                    : 'From RM ${price.price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: JimatMyColors.yellow,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              if (price != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  price.premiseName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 7),
                              SizedBox(
                                height: 30,
                                child: FilledButton.tonal(
                                  onPressed: () => _open(item),
                                  child: const Text('View prices'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _items.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: index == _page ? JimatMyColors.yellow : Colors.white54,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
