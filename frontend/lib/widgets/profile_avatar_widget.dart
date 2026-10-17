import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/auth_user.dart';
import 'jimatmy_ui.dart';

class AvatarPreset {
  const AvatarPreset(this.id, this.icon, this.background, this.foreground);

  final String id;
  final IconData icon;
  final Color background;
  final Color foreground;
}

const avatarPresets = <AvatarPreset>[
  AvatarPreset(
    'basket_green',
    Icons.shopping_basket_rounded,
    Color(0xFFDDF3E4),
    JimatMyColors.green,
  ),
  AvatarPreset(
    'apple_yellow',
    Icons.apple_rounded,
    Color(0xFFFFE69B),
    Color(0xFF8E5B00),
  ),
  AvatarPreset(
    'carrot_mint',
    Icons.eco_rounded,
    Color(0xFFCCEFE0),
    Color(0xFFB84E15),
  ),
  AvatarPreset(
    'drink_green',
    Icons.local_drink_rounded,
    Color(0xFFDCEEF8),
    Color(0xFF246B8E),
  ),
  AvatarPreset(
    'rice_yellow',
    Icons.rice_bowl_rounded,
    Color(0xFFFFF1CF),
    Color(0xFF795A1D),
  ),
  AvatarPreset(
    'shop_mint',
    Icons.storefront_rounded,
    Color(0xFFCFE8D5),
    Color(0xFF17633B),
  ),
  AvatarPreset(
    'leaf_green',
    Icons.spa_rounded,
    Color(0xFFE8F4B8),
    Color(0xFF4A6D18),
  ),
  AvatarPreset(
    'egg_yellow',
    Icons.egg_alt_rounded,
    Color(0xFFFFE9B0),
    Color(0xFF9B6813),
  ),
  AvatarPreset(
    'orange_mint',
    Icons.local_grocery_store_rounded,
    Color(0xFFFFE0E7),
    Color(0xFF9A3E55),
  ),
  AvatarPreset(
    'grocery_green',
    Icons.home_rounded,
    Color(0xFFD8F0E9),
    Color(0xFF216A58),
  ),
];

AvatarPreset? avatarPresetById(String? id) {
  for (final preset in avatarPresets) {
    if (preset.id == id) return preset;
  }
  return null;
}

class ProfileAvatarWidget extends StatelessWidget {
  const ProfileAvatarWidget({
    required this.user,
    this.size = 72,
    this.revision = 0,
    super.key,
  });

  final AuthUser user;
  final double size;
  final int revision;

  @override
  Widget build(BuildContext context) {
    final fallback = _fallback();
    Widget content = fallback;
    final relativeUrl = user.avatarType == 'upload' ? user.avatarValue : null;
    if (relativeUrl != null && relativeUrl.trim().isNotEmpty) {
      final rawUrl = ApiConfig.mediaUrl(relativeUrl);
      final separator = rawUrl.contains('?') ? '&' : '?';
      content = Image.network(
        '$rawUrl${separator}v=$revision',
        fit: BoxFit.cover,
        width: size,
        height: size,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Semantics(
      label: '${user.name} profile picture',
      image: true,
      child: ClipOval(
        child: SizedBox.square(dimension: size, child: content),
      ),
    );
  }

  Widget _fallback() {
    final preset = avatarPresetById(user.avatarValue);
    if (user.avatarType == 'preset' && preset != null) {
      return ColoredBox(
        color: preset.background,
        child: Icon(preset.icon, color: preset.foreground, size: size * .52),
      );
    }
    final trimmed = user.name.trim();
    return ColoredBox(
      color: JimatMyColors.mint,
      child: Center(
        child: Text(
          trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase(),
          style: TextStyle(
            color: JimatMyColors.deepGreen,
            fontSize: size * .4,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
