import 'package:flutter/material.dart';

import '../models/premise.dart';
import 'jimatmy_ui.dart';

class PremiseListTileWidget extends StatelessWidget {
  const PremiseListTileWidget({
    required this.premise,
    required this.onTap,
    this.selected = false,
    super.key,
  });
  final Premise premise;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final distance = premise.distanceKm;
    final hasCoordinates = premise.hasCoordinates;
    return Material(
      color: selected ? JimatMyColors.mint : Colors.white,
      child: Semantics(
        button: true,
        selected: selected,
        label: 'View ${premise.premiseName} store details',
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        premise.premiseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      if (distance != null)
                        Row(
                          children: [
                            Icon(
                              Icons.near_me_rounded,
                              size: 13,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              formatDistanceCompact(distance),
                              key: ValueKey(
                                'nearby-distance-${premise.premiseCode}',
                              ),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              '  |  ',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.outline),
                            ),
                            Expanded(
                              child: Text(
                                '${premise.district}, ${premise.state}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '${premise.district}, ${premise.state}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 1),
                      Text(
                        premise.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  hasCoordinates
                      ? Icons.directions_outlined
                      : Icons.chevron_right_rounded,
                  key: ValueKey('nearby-trailing-icon-${premise.premiseCode}'),
                  size: 20,
                  color: hasCoordinates
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
