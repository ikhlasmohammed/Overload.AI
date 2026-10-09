import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import 'change_password_screen.dart';
import 'premium_plan_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(ref),
              const SizedBox(height: 24),
              _buildPremiumCard(context, ref),
              const SizedBox(height: 24),
              _buildThemeColorCard(ref),
              const SizedBox(height: 24),
              _buildMenuOptions(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Athlete';
    final subtitle = user?.email ?? '';

    return Row(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.surfaceLight,
          child: Icon(Icons.person, size: 40, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumCard(BuildContext context, WidgetRef ref) {
    final isPremium =
        ref.watch(userProfileProvider).value?.isPremium ?? false;

    return AppCard(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PremiumPlanScreen()));
      },
      child: Row(
        children: [
          Icon(
            isPremium ? Icons.workspace_premium : Icons.diamond,
            color: isPremium ? AppColors.success : AppColors.primary,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'View Premium Plan' : 'Buy Premium Plan',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium
                      ? "You're unlocked - view your custom training program."
                      : 'Scan a NETS QR code to unlock your full training program.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  // Lets the user pick from 5 preset accent colours - see
  // providers/theme_provider.dart. Applied app-wide via AppTheme.darkTheme()
  // to buttons, focused input borders, and the bottom nav's selected icon;
  // persisted so it survives app restarts.
  Widget _buildThemeColorCard(WidgetRef ref) {
    final selected = ref.watch(themeColorProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theme Colour',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: kThemeColorOptions.map((color) {
              final isSelected = color.toARGB32() == selected.toARGB32();
              return GestureDetector(
                onTap: () =>
                    ref.read(themeColorProvider.notifier).setColor(color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: AppColors.textPrimary, width: 2.5)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context, WidgetRef ref) {
    final menuItems = [
      {'icon': Icons.history, 'title': 'Workout History'},
      {'icon': Icons.accessibility_new, 'title': 'Body Measurements'},
      {'icon': Icons.payment, 'title': 'Payment & Subscription'},
      {'icon': Icons.notifications_none, 'title': 'Notifications'},
      {'icon': Icons.lock_outline, 'title': 'Change Password'},
      {'icon': Icons.logout, 'title': 'Log out'},
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: menuItems.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          final title = item['title'] as String;
          return ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color: AppColors.textPrimary,
            ),
            title: Text(
              title,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            onTap: () => _handleMenuTap(context, ref, title),
          );
        },
      ),
    );
  }

  void _handleMenuTap(BuildContext context, WidgetRef ref, String title) {
    switch (title) {
      case 'Change Password':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
        break;
      case 'Log out':
        _confirmLogout(context, ref);
        break;
      default:
        // Workout History / Body Measurements / Payment / Notifications

        break;
    }
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Log out?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'You will need to sign in again to access your workouts.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authServiceProvider).signOut();
            },
            child: const Text(
              'Log out',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
