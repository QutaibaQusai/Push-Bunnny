import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:push_bunnny/core/constants/app_colors.dart';
import 'package:push_bunnny/core/constants/app_fonts.dart';
import 'package:push_bunnny/features/notifications/models/group_subscription_model.dart';
import 'package:push_bunnny/features/notifications/providers/notification_provider.dart';
import 'package:push_bunnny/features/notifications/services/group_subscription_service.dart';
import 'package:push_bunnny/ui/routes/routes.dart';
import 'package:push_bunnny/ui/widgets/notification_card.dart';
import 'package:push_bunnny/ui/widgets/notification_details_sheet.dart';


class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');
    final provider = Provider.of<NotificationProvider>(context);
    
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        color: AppColors.background,
        child: provider.isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  _buildGroupFilterSection(context, provider),
                  Expanded(
                    child: provider.notifications.isEmpty
                        ? _buildEmptyWidget()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 26),
                            itemCount: provider.notifications.length,
                            itemBuilder: (context, index) {
                              final notification = provider.notifications[index];
                              return NotificationCard(
                                notification: notification,
                                dateFormat: dateFormat,
                                onDelete: () => _confirmDelete(context, notification.id, provider),
                                onTap: () => _showDetailsSheet(context, notification, provider),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset('assets/iconWhite.png', height: 24, width: 24),
          const SizedBox(width: 7),
          Text(
            'Push Bunny',
            style: AppFonts.appBarTitle,
          ),
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

 Widget _buildGroupFilterSection(BuildContext context, NotificationProvider provider) {
    return StreamBuilder<List<GroupSubscriptionModel>>(
      stream: GroupSubscriptionService().getUserSubscribedGroups(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final subscriptions = snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: const Offset(0, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildFilterChip(
                  label: 'All Messages',
                  icon: Icons.all_inbox,
                  isSelected: provider.selectedGroupId == null,
                  onTap: () => provider.setSelectedGroup(null),
                ),
                ...subscriptions.map((subscription) {
                  return _buildFilterChip(
                    label: subscription.name,
                    icon: Icons.campaign,
                    isSelected: provider.selectedGroupId == subscription.id,
                    onTap: () => provider.setSelectedGroup(subscription.id),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.accentGradient : null,
          color: isSelected ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.listItemSubtitle.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String notificationId, NotificationProvider provider) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Message', style: AppFonts.sectionTitle),
            content: Text(
              'This message will be removed from this device.',
              style: AppFonts.listItemSubtitle,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;

    if (confirmed) {
      await provider.deleteNotification(notificationId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message deleted', style: AppFonts.snackBar),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDetailsSheet(BuildContext context, dynamic notification, NotificationProvider provider) {
    // Mark as read when opened
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationDetailsSheet(notification: notification),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No messages yet',
            style: AppFonts.listItemTitle.copyWith(
              fontSize: AppFonts.heading3,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Messages will appear here',
            style: AppFonts.listItemSubtitle.copyWith(
              fontSize: AppFonts.bodyLarge,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}