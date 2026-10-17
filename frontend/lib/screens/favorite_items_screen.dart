import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../widgets/app_state_widget.dart';
import '../widgets/item_image_widget.dart';
import '../widgets/mobile_content.dart';
import '../widgets/price_freshness_widget.dart';
import 'item_detail_screen.dart';

class FavoriteItemsScreen extends StatelessWidget {
  const FavoriteItemsScreen({required this.provider, this.onBrowse, super.key});

  final ProfileProvider provider;
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: provider,
    child: Scaffold(
      appBar: AppBar(title: const Text('My Favourites')),
      body: MobileContent(
        child: Consumer<ProfileProvider>(
          builder: (context, profile, _) {
            if (profile.isLoading && profile.favorites.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (profile.errorMessage != null && profile.favorites.isEmpty) {
              return AppStateWidget(
                icon: Icons.cloud_off_outlined,
                title: 'Favourites unavailable',
                message: profile.errorMessage!,
                actionLabel: 'Retry',
                onAction: () => profile.load(force: true),
              );
            }
            if (profile.favorites.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_border_rounded, size: 52),
                      const SizedBox(height: 12),
                      Text(
                        'No favourites yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Save grocery items to find them quickly here.',
                        textAlign: TextAlign.center,
                      ),
                      if (onBrowse != null) ...[
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: onBrowse,
                          child: const Text('Browse items'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => profile.load(force: true),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: profile.favorites.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = profile.favorites[index];
                  return Card(
                    child: ListTile(
                      minTileHeight: 82,
                      leading: ItemImage(
                        itemCode: item.itemCode,
                        itemName: item.itemName,
                        category: item.itemCategory,
                        group: item.itemGroup,
                        width: 56,
                        height: 56,
                        borderRadius: 14,
                      ),
                      title: Text(
                        item.itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.lowestPrice == null
                                ? '${item.unit} • Price unavailable'
                                : '${item.unit} • From RM ${item.lowestPrice!.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 4),
                          PriceFreshnessWidget(
                            reliability: item.reliability,
                            compact: true,
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Remove ${item.itemName} from favourites',
                        onPressed: () async {
                          final error = await profile.removeFavorite(
                            item.itemCode,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error ?? 'Removed from favourites.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.favorite_rounded),
                      ),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ItemDetailScreen(itemCode: item.itemCode),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    ),
  );
}
