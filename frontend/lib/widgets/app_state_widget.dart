import 'package:flutter/material.dart';

class AppStateWidget extends StatelessWidget {
  const AppStateWidget({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompact =
            compact ||
            (constraints.hasBoundedHeight && constraints.maxHeight < 280);
        final label = actionLabel;
        final action = onAction;
        final content = Padding(
          padding: EdgeInsets.all(useCompact ? 10 : 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: useCompact ? 28 : 42, color: colors.primary),
                SizedBox(height: useCompact ? 6 : 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: useCompact
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: useCompact ? 4 : 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style:
                      (useCompact
                              ? Theme.of(context).textTheme.bodySmall
                              : Theme.of(context).textTheme.bodyMedium)
                          ?.copyWith(color: colors.onSurfaceVariant),
                ),
                if (label != null && action != null) ...[
                  SizedBox(height: useCompact ? 8 : 20),
                  FilledButton.icon(
                    onPressed: action,
                    style: useCompact
                        ? FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            minimumSize: const Size(0, 36),
                          )
                        : null,
                    icon: Icon(Icons.refresh, size: useCompact ? 18 : 24),
                    label: Text(label),
                  ),
                ],
              ],
            ),
          ),
        );
        if (useCompact) return Center(child: content);
        return Center(child: SingleChildScrollView(child: content));
      },
    );
  }
}
