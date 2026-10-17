import 'package:flutter/material.dart';

import '../models/planner_models.dart';
import 'jimatmy_ui.dart';

class BasketTemplateSection extends StatefulWidget {
  const BasketTemplateSection({
    required this.templates,
    required this.isLoading,
    required this.onSelect,
    this.onRetry,
    super.key,
  });

  final List<BasketTemplate> templates;
  final bool isLoading;
  final ValueChanged<BasketTemplate> onSelect;
  final VoidCallback? onRetry;

  @override
  State<BasketTemplateSection> createState() => _BasketTemplateSectionState();
}

class _BasketTemplateSectionState extends State<BasketTemplateSection> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.templates.isEmpty) {
      return const SizedBox(
        height: 166,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.templates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: JimatMyColors.mint,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.shopping_basket_outlined,
              color: JimatMyColors.green,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Weekly baskets are temporarily unavailable.'),
            ),
            if (widget.onRetry != null)
              TextButton(onPressed: widget.onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    return SizedBox(
      height: 206,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 3,
        radius: const Radius.circular(8),
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: ListView.separated(
            controller: _scrollController,
            key: const ValueKey('home-basket-templates'),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: widget.templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final template = widget.templates[index];
              final colors = <Color>[
                const Color(0xFFE1F4E9),
                const Color(0xFFFFF1C7),
                const Color(0xFFE8EEFF),
                const Color(0xFFFFE8DF),
              ];
              return SizedBox(
                width: 184,
                child: Material(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => widget.onSelect(template),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shopping_basket_rounded,
                                color: JimatMyColors.green,
                              ),
                              const Spacer(),
                              Text(
                                '${template.itemCount} items',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            template.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            template.household,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            'Estimated RM ${template.estimatedTotal.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: JimatMyColors.deepGreen,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            template.unavailableItemCount == 0
                                ? 'All prices available'
                                : '${template.unavailableItemCount} prices unavailable',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
