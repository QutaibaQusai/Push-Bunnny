import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:push_bunnny/features/notifications/models/notification_model.dart';
import 'package:push_bunnny/ui/theme/app_colors.dart';
import 'package:push_bunnny/ui/theme/text_style.dart';


class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Slidable(
        key: ValueKey(notification.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: notification.isRead 
                ? null 
                : Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: notification.isRead 
                    ? Colors.grey.shade200
                    : AppColors.primary.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUnreadIndicator(),
                    const SizedBox(width: 12),
                    Expanded(child: _buildContent()),
                    const SizedBox(width: 8),
                    _buildTimestamp(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadIndicator() {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: notification.isRead 
            ? Colors.grey.shade300 
            : AppColors.primary,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification.title,
          style: AppTextStyles.notificationTitle.copyWith(
            fontWeight: notification.isRead 
                ? FontWeight.normal 
                : FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          notification.body,
          style: AppTextStyles.notificationBody,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _buildMetadata(),
      ],
    );
  }

  Widget _buildMetadata() {
    final List<Widget> badges = [];

    // Group badge
    if (notification.isGroupNotification) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryWithOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group, size: 10, color: AppColors.primary),
              const SizedBox(width: 2),
              Text(
                notification.groupName ?? 'Group',
style: AppTextStyles.timestamp.copyWith(
                  color: AppColors.primary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // User notification badge
    if (notification.isUserNotification) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.secondaryWithOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.secondary.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 10, color: AppColors.secondary),
              const SizedBox(width: 2),
              Text(
                'Personal',
style: AppTextStyles.timestamp.copyWith(
                  color: AppColors.secondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Image badge
    if (notification.imageUrl != null) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image, size: 10, color: Colors.grey.shade600),
              const SizedBox(width: 2),
              Text(
                'Image',
style: AppTextStyles.timestamp.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 4,
      children: badges,
    );
  }

  Widget _buildTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(notification.timestamp);
    
    String timeText;
    if (difference.inMinutes < 1) {
      timeText = 'now';
    } else if (difference.inHours < 1) {
      timeText = '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      timeText = DateFormat('HH:mm').format(notification.timestamp);
    } else if (difference.inDays < 7) {
      timeText = DateFormat('E').format(notification.timestamp);
    } else {
      timeText = DateFormat('dd/MM').format(notification.timestamp);
    }

    return Column(
      children: [
        Text(
          timeText,
          style: AppTextStyles.timestamp,
        ),
      ],
    );
  }
}
