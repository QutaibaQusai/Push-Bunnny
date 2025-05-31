import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:push_bunnny/features/groups/providers/group_provider.dart';
import 'package:push_bunnny/features/notifications/providers/notification_provider.dart';
import 'package:push_bunnny/ui/navigation/app_router.dart';
import 'package:push_bunnny/ui/theme/app_colors.dart';
import 'package:push_bunnny/ui/theme/text_style.dart';
import 'package:push_bunnny/ui/widgets/confirmation_dialog.dart';
import 'package:push_bunnny/ui/widgets/group_subscription_card.dart';
import 'package:push_bunnny/ui/widgets/snackbar_helper.dart';
import 'package:push_bunnny/ui/widgets/subscribe_group_dialog.dart';
import 'package:push_bunnny/ui/widgets/user_id_card.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Device Settings'),
            const UserIdCard(),
            const SizedBox(height: 24),
            _buildGroupSubscriptionsSection(context),
            const SizedBox(height: 24),
            _buildSection('Data Management'),
            _buildSettingTile(
              title: 'Clear All Notifications',
              subtitle: 'Delete all notification history',
              icon: Icons.delete_outline,
              onTap: () => _clearAllNotifications(context),
            ),
            const SizedBox(height: 24),
            _buildSection('About'),
            _buildSettingTile(
              title: 'About Push Bunny',
              subtitle: 'App version and information',
              icon: Icons.info_outline,
              onTap: () => AppRouter.navigateToAbout(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Settings', style: AppTextStyles.appBarTitle),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTextStyles.heading3.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGroupSubscriptionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Group Subscriptions',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              FloatingActionButton.small(
                onPressed: () => _showSubscribeDialog(context),
                backgroundColor: AppColors.primary,
                elevation: 2,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
        Consumer<GroupProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (provider.subscribedGroups.isEmpty) {
              return _buildEmptyGroups();
            }

            return Column(
              children: provider.subscribedGroups.map((group) {
                return GroupSubscriptionCard(
                  group: group!,
                  onUnsubscribe: () => _unsubscribeFromGroup(context, group.name!),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyGroups() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Group Subscriptions',
              style: AppTextStyles.bodyLargeStyle.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to groups to receive notifications',
              style: AppTextStyles.bodyMediumStyle.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryWithOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: AppTextStyles.cardTitle),
        subtitle: Text(subtitle, style: AppTextStyles.cardSubtitle),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSubscribeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SubscribeGroupDialog(),
    ).then((success) {
      if (success == true && context.mounted) {
        SnackbarHelper.show(
          context: context,
          message: 'Successfully subscribed to group',
          backgroundColor: AppColors.success,
        );
        // Refresh groups
        context.read<GroupProvider>().refresh();
      }
    });
  }

  Future<void> _unsubscribeFromGroup(BuildContext context, String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Unsubscribe from Group',
        content: 'You will no longer receive notifications from this group.',
        confirmText: 'Unsubscribe',
        cancelText: 'Cancel',
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<GroupProvider>().unsubscribeFromGroup(groupId);
        
        if (context.mounted) {
          SnackbarHelper.show(
            context: context,
            message: 'Unsubscribed from group',
          );
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarHelper.show(
            context: context,
            message: 'Failed to unsubscribe: $e',
            backgroundColor: AppColors.error,
          );
        }
      }
    }
  }

  Future<void> _clearAllNotifications(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Clear All Notifications',
        content: 'This will permanently delete all your notifications. This action cannot be undone.',
        confirmText: 'Clear All',
        cancelText: 'Cancel',
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<NotificationProvider>().deleteAllNotifications();
        
        if (context.mounted) {
          SnackbarHelper.show(
            context: context,
            message: 'All notifications cleared',
          );
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarHelper.show(
            context: context,
            message: 'Failed to clear notifications: $e',
            backgroundColor: AppColors.error,
          );
        }
      }
    }
  }
}