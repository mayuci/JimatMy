import 'package:flutter/material.dart';

class JimatMyColors {
  static const green = Color(0xFF167D55);
  static const deepGreen = Color(0xFF0D5B3D);
  static const mint = Color(0xFFE5F5EA);
  static const cream = Color(0xFFFFFCF4);
  static const yellow = Color(0xFFF4C95D);
  static const ink = Color(0xFF16342A);
}

class JimatMyBrandAssets {
  static const mark = 'assets/images/branding/jimatmy_mark.png';
  static const wordmark = 'assets/images/branding/jimatmy_wordmark.png';
}

class JimatMyLogoBadge extends StatelessWidget {
  const JimatMyLogoBadge({this.size = 88, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'JimatMY logo',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .22),
        child: Image.asset(
          JimatMyBrandAssets.mark,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => ColoredBox(
            color: JimatMyColors.green,
            child: Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: size * .58,
            ),
          ),
        ),
      ),
    ),
  );
}

class JimatMyMark extends StatelessWidget {
  const JimatMyMark({this.compact = false, super.key});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 48.0;
    return Semantics(
      label: 'JimatMY',
      image: true,
      child: SizedBox(
        width: size * 2.5,
        height: size,
        child: Image.asset(
          JimatMyBrandAssets.wordmark,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: JimatMyColors.green,
                size: size * .8,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'JimatMY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: JimatMyColors.deepGreen,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JimatMySectionTitle extends StatelessWidget {
  const JimatMySectionTitle({required this.title, this.action, super.key});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      ...?(action == null ? null : <Widget>[action as Widget]),
    ],
  );
}

class JimatMyQuickAction extends StatelessWidget {
  const JimatMyQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: JimatMyColors.mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: JimatMyColors.green, size: 21),
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}
