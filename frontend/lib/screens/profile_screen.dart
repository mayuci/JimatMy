import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_user.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/avatar_action_sheet_widget.dart';
import '../widgets/jimatmy_ui.dart';
import '../widgets/mobile_content.dart';
import '../widgets/profile_avatar_widget.dart';
import 'about_screen.dart';
import 'edit_profile_screen.dart';
import 'favorite_items_screen.dart';
import 'login_screen.dart';
import 'profile_settings_screen.dart';
import 'recent_activity_screen.dart';
import 'register_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({this.onOpenPlanner, this.onOpenSearch, super.key});

  final VoidCallback? onOpenPlanner;
  final VoidCallback? onOpenSearch;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: MobileContent(
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isRestoring) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = auth.user;
          if (user == null) return const _GuestProfile();
          return _AuthenticatedProfile(
            key: ValueKey(user.userId),
            user: user,
            onOpenPlanner: onOpenPlanner,
            onOpenSearch: onOpenSearch,
          );
        },
      ),
    ),
  );
}

class _AuthenticatedProfile extends StatefulWidget {
  const _AuthenticatedProfile({
    required this.user,
    required this.onOpenPlanner,
    required this.onOpenSearch,
    super.key,
  });

  final AuthUser user;
  final VoidCallback? onOpenPlanner;
  final VoidCallback? onOpenSearch;

  @override
  State<_AuthenticatedProfile> createState() => _AuthenticatedProfileState();
}

class _AuthenticatedProfileState extends State<_AuthenticatedProfile> {
  late final ProfileProvider _profile;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _profile = context.read<ProfileProvider>();
    if (_profile.summary == null && !_profile.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _profile.summary == null && !_profile.isLoading) {
          _profile.load();
        }
      });
    }
  }

  Future<void> _open(Widget screen) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => screen));

  void _browseItems() {
    if (Navigator.of(context).canPop()) Navigator.pop(context);
    widget.onOpenSearch?.call();
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.logoutQuestion),
        content: Text(context.l10n.logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _profile,
    child: Builder(
      builder: (context) {
        return Column(
          children: [
            _ProfileHeader(
              user: widget.user,
              onAvatar: () => showAvatarActionSheet(context),
              onSettings: () => _open(const ProfileSettingsScreen()),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _profile.load(force: true),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _ProfileSummaryRow(
                      onFavourites: () => _open(
                        FavoriteItemsScreen(
                          provider: _profile,
                          onBrowse: widget.onOpenSearch == null
                              ? null
                              : _browseItems,
                        ),
                      ),
                      onHistory: () =>
                          _open(RecentActivityScreen(provider: _profile)),
                      onLists: widget.onOpenPlanner,
                    ),
                    if (_profile.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _LoadError(
                        message: _profile.errorMessage!,
                        onRetry: () => _profile.load(force: true),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _MenuGroup(
                      children: [
                        _ProfileMenuRow(
                          icon: Icons.person_outline_rounded,
                          label: context.l10n.myProfile,
                          onTap: () => _open(const EditProfileScreen()),
                        ),
                        _ProfileMenuRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: context.l10n.budgetPlanner,
                          onTap: widget.onOpenPlanner,
                        ),
                        _ProfileMenuRow(
                          icon: Icons.favorite_border_rounded,
                          label: context.l10n.myFavourites,
                          onTap: () => _open(
                            FavoriteItemsScreen(
                              provider: _profile,
                              onBrowse: widget.onOpenSearch == null
                                  ? null
                                  : _browseItems,
                            ),
                          ),
                        ),
                        _ProfileMenuRow(
                          icon: Icons.history_rounded,
                          label: context.l10n.recentViewsMenu,
                          onTap: () =>
                              _open(RecentActivityScreen(provider: _profile)),
                        ),
                        _ProfileMenuRow(
                          icon: Icons.settings_outlined,
                          label: context.l10n.settings,
                          onTap: () => _open(const ProfileSettingsScreen()),
                        ),
                        _ProfileMenuRow(
                          icon: Icons.info_outline_rounded,
                          label: context.l10n.aboutJimatmy,
                          onTap: () => _open(const AboutScreen()),
                        ),
                        _ProfileMenuRow(
                          icon: Icons.logout_rounded,
                          label: _loggingOut
                              ? context.l10n.loggingOut
                              : context.l10n.logout,
                          onTap: _loggingOut ? null : _logout,
                          destructive: true,
                          showChevron: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.onAvatar,
    required this.onSettings,
  });

  final AuthUser user;
  final VoidCallback onAvatar;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ColoredBox(
      color: JimatMyColors.green,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 154,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 10, 20),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: context.l10n.changeProfilePicture,
                  child: InkWell(
                    key: const ValueKey('profile-avatar-action'),
                    onTap: auth.isLoading ? null : onAvatar,
                    customBorder: const CircleBorder(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ProfileAvatarWidget(
                            user: user,
                            size: 72,
                            revision: auth.avatarRevision,
                          ),
                        ),
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: JimatMyColors.yellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: JimatMyColors.deepGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.profileGreeting(user.name),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.l10n.profileSubtitle,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  tooltip: context.l10n.openSettings,
                  onPressed: onSettings,
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                  ),
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSummaryRow extends StatelessWidget {
  const _ProfileSummaryRow({
    required this.onFavourites,
    required this.onHistory,
    required this.onLists,
  });
  final VoidCallback onFavourites;
  final VoidCallback onHistory;
  final VoidCallback? onLists;

  @override
  Widget build(BuildContext context) => Consumer<ProfileProvider>(
    builder: (context, profile, _) {
      final summary = profile.summary;
      return Row(
        children: [
          Expanded(
            child: _SummaryTile(
              label: context.l10n.favourites,
              value: summary?.favoriteItemCount,
              isLoading: profile.isLoading && summary == null,
              icon: Icons.favorite_outline,
              onTap: onFavourites,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryTile(
              label: context.l10n.recentViews,
              value: summary?.historyCount,
              isLoading: profile.isLoading && summary == null,
              icon: Icons.history_rounded,
              onTap: onHistory,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryTile(
              label: context.l10n.shoppingLists,
              value: summary?.shoppingListCount,
              isLoading: profile.isLoading && summary == null,
              icon: Icons.list_alt_rounded,
              onTap: onLists,
            ),
          ),
        ],
      );
    },
  );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.isLoading,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final int? value;
  final bool isLoading;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 102,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: JimatMyColors.green),
              const SizedBox(height: 3),
              if (isLoading)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (value != null)
                Text(
                  value.toString(),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                )
              else
                Tooltip(
                  message: context.l10n.countUnavailable,
                  child: const Icon(Icons.error_outline_rounded, size: 18),
                ),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(children: children),
    ),
  );
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : JimatMyColors.deepGreen;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: .45),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
              if (showChevron) const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    ),
  );
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(
      20,
      MediaQuery.paddingOf(context).top + 34,
      20,
      28,
    ),
    children: [
      const CircleAvatar(
        radius: 46,
        backgroundColor: JimatMyColors.mint,
        child: Icon(
          Icons.person_outline_rounded,
          size: 46,
          color: JimatMyColors.green,
        ),
      ),
      const SizedBox(height: 18),
      Text(
        context.l10n.guestTitle,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      Text(
        context.l10n.guestMessage,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        icon: const Icon(Icons.login_rounded),
        label: Text(context.l10n.login),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        child: Text(context.l10n.createAccountShort),
      ),
      const SizedBox(height: 28),
      _MenuGroup(
        children: [
          _ProfileMenuRow(
            icon: Icons.info_outline_rounded,
            label: context.l10n.aboutJimatmy,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    ],
  );
}
