import 'dart:async';

import 'package:flutter/material.dart';

import '../models/item.dart';
import '../services/api_service.dart';
import 'item_image_widget.dart';

class AddItemSheetWidget extends StatefulWidget {
  const AddItemSheetWidget({
    required this.apiService,
    required this.onAdd,
    super.key,
  });

  final ApiService apiService;
  final Future<String?> Function(Item item, double quantity) onAdd;

  @override
  State<AddItemSheetWidget> createState() => _AddItemSheetWidgetState();
}

class _AddItemSheetWidgetState extends State<AddItemSheetWidget> {
  Timer? _debounce;
  List<Item> _items = const [];
  final Set<int> _addingCodes = <int>{};
  bool _loading = false;
  String? _error;
  String? _category;
  int _requestVersion = 0;
  String _query = '';

  static const _categories = <(String, String?)>[
    ('All', null),
    ('Fresh Food', 'fresh-food'),
    ('Fruits', 'fruits'),
    ('Drinks', 'drinks'),
    ('Dry Goods', 'dry-goods'),
    ('Baby', 'baby'),
    ('Household', 'household'),
  ];

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    final requestVersion = ++_requestVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.apiService.getItems(
        query: query,
        limit: 30,
        offset: 0,
        category: _category,
      );
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _items = page.items);
      }
    } on ApiException catch (error) {
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _add(Item item) async {
    if (_addingCodes.contains(item.itemCode)) return;
    setState(() => _addingCodes.add(item.itemCode));
    final error = await widget.onAdd(item, 1);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _addingCodes.remove(item.itemCode));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add item',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              onChanged: _scheduleSearch,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search PriceCatcher items',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ChoiceChip(
                    label: Text(category.$1),
                    selected: _category == category.$2,
                    onSelected: (_) {
                      setState(() => _category = category.$2);
                      _search(_query);
                    },
                  );
                },
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? const Center(child: Text('No items found'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final adding = _addingCodes.contains(item.itemCode);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: ItemImage(
                              itemCode: item.itemCode,
                              itemName: item.itemName,
                              category: item.itemCategory,
                              group: item.itemGroup,
                              width: 46,
                              height: 46,
                              borderRadius: 12,
                            ),
                            title: Text(
                              item.itemName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${item.unit}  |  ${item.itemCategory}',
                            ),
                            trailing: FilledButton.icon(
                              onPressed: adding ? null : () => _add(item),
                              icon: adding
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
