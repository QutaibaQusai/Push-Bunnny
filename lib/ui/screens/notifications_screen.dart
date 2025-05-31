import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:push_bunnny/features/groups/providers/group_provider.dart';
import 'package:push_bunnny/features/notifications/providers/notification_provider.dart';
import 'package:push_bunnny/ui/navigation/app_router.dart';
import 'package:push_bunnny/ui/theme/app_colors.dart';
import 'package:push_bunnny/ui/theme/text_style.dart';
import 'package:push_bunnny/ui/widgets/confirmation_dialog.dart';
import 'package:push_bunnny/ui/widgets/group_filter_chip.dart';
import 'package:push_bunnny/ui/widgets/notification_card.dart';
import 'package:push_bunnny/ui/widgets/notification_details_sheet.dart';
import 'package:push_bunnny/ui/widgets/snackbar_helper.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildGroupFilters(),
          Expanded(child: _buildNotificationsList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset('assets/iconWhite.png', height: 24, width: 24),
          const SizedBox(width: 7),
          Text('Push Bunny', style: AppTextStyles.appBarTitle),
        ],
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 0,
      centerTitle: false,
      actions: [
        InkWell(
          onTap: () => AppRouter.navigateToSettings(),
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.settings, color: AppColors.background),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupFilters() {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, _) {
        if (groupProvider.subscribedGroups.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  GroupFilterChip(
                    label: 'All Messages',
                    icon: Icons.all_inbox,
                    isSelected: notificationProvider.selectedGroupId == null,
                    onTap: () => notificationProvider.selectGroup(null),
                  ),
                  ...groupProvider.subscribedGroups.map((group) {
                    final groupId = group.name; // Use group name as ID
                    return GroupFilterChip(
                      label: group.name,
                      icon: Icons.campaign,
                      isSelected:
                          notificationProvider.selectedGroupId == groupId,
                      onTap: () => notificationProvider.selectGroup(groupId),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.notifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: provider.notifications.length,
          itemBuilder: (context, index) {
            final notification = provider.notifications[index];
            return NotificationCard(
              notification: notification,
              onTap: () => _showNotificationDetails(context, notification),
              onDelete: () => _confirmDelete(context, notification.id),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: AppTextStyles.heading3.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifications will appear here when you receive them',
            style: AppTextStyles.bodyMediumStyle.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(BuildContext context, notification) {
    // Mark as read
    if (!notification.isRead) {
      context.read<NotificationProvider>().markAsRead(notification.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => NotificationDetailsSheet(notification: notification),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String notificationId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => const ConfirmationDialog(
            title: 'Delete Notification',
            content: 'This notification will be permanently deleted.',
            confirmText: 'Delete',
            cancelText: 'Cancel',
          ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<NotificationProvider>().deleteNotification(
        notificationId,
      );

      if (context.mounted) {
        SnackbarHelper.show(context: context, message: 'Notification deleted');
      }
    }
  }
}
