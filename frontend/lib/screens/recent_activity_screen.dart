import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../widgets/item_image_widget.dart';
import '../widgets/mobile_content.dart';
import 'item_detail_screen.dart';

class RecentActivityScreen extends StatelessWidget {
  const RecentActivityScreen({required this.provider, super.key});

  final ProfileProvider provider;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: provider,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Recent Views'),
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, profile, _) => IconButton(
              tooltip: 'Clear history',
              onPressed: profile.history.isEmpty
                  ? null
                  : () => _confirmClear(context, profile),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ),
        ],
      ),
      body: MobileContent(
        child: Consumer<ProfileProvider>(
          builder: (context, profile, _) {
            final entries = profile.history;
            if (profile.isLoading && entries.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (entries.isEmpty) {
              return const Center(child: Text('No recently viewed items yet.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  minTileHeight: 76,
                  leading: ItemImage(
                    itemCode: entry.itemCode,
                    itemName: entry.itemName,
                    category: entry.itemCategory,
                    group: entry.itemGroup,
                    width: 56,
                    height: 56,
                    borderRadius: 14,
                  ),
                  title: Text(entry.itemName),
                  subtitle: Text(
                    '${entry.unit}  |  ${_formatDate(entry.lastViewedAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ItemDetailScreen(itemCode: entry.itemCode),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _confirmClear(
  BuildContext context,
  ProfileProvider profile,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Clear recent views?'),
      content: const Text('This removes your viewed-item history.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Clear history'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final error = await profile.clearHistory();
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return 'Viewed recently';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day}/${local.month}/${local.year} at $hour:$minute';
}
