import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_font.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final DateFormat dateFormat;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDelete,
    required this.onTap,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = _formatTimestamp(notification.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Slidable(
        key: ValueKey(notification.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [_buildDeleteAction()],
        ),
        child: _buildCardContent(timeString),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inHours < 24) {
      return dateFormat.format(timestamp);
    } else if (difference.inDays < 7) {
      return DateFormat('E').format(timestamp); // Day of week
    } else {
      return DateFormat('dd/MM').format(timestamp);
    }
  }

  Widget _buildDeleteAction() {
    return CustomSlidableAction(
      onPressed: (context) => onDelete(),
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      autoClose: true,
      padding: EdgeInsets.zero, // Remove padding to make it fill the space
      child: Container(
        color: Colors.red,
        alignment: Alignment.center,
        child: const Icon(Icons.delete, size: 24, color: Colors.white),
      ),
    );
  }

  Widget _buildCardContent(String timeString) {
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.card : AppColors.card.withOpacity(0.96),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
        ),
        // Add a subtle indication that the notification is unread
        boxShadow: notification.isRead 
            ? [] 
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.07),
                  blurRadius: 1,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show unread indicator
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: notification.isRead 
                        ? null 
                        : AppColors.accentGradient,
                    color: notification.isRead 
                        ? Colors.grey.shade300 
                        : null,
                  ),
                ),
                _buildNotificationContent(timeString),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationContent(String timeString) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: AppFonts.listItemTitle.copyWith(
                    fontWeight: notification.isRead 
                        ? AppFonts.medium 
                        : AppFonts.semiBold,
                    fontSize: AppFonts.bodyLarge,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Text(timeString, style: AppFonts.timeStamp),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            notification.body,
            style: AppFonts.listItemSubtitle.copyWith(
              fontSize: AppFonts.bodyMedium,
              height: AppFonts.lineHeightRelaxed,
              color: notification.isRead 
                  ? AppColors.textTertiary 
                  : AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          
          // Show group or notification metadata
          Row(
            children: [
              if (notification.groupName != null) ...[
                _buildGroupIndicator(notification.groupName!),
                const SizedBox(width: 8),
              ],
              if (notification.imageUrl != null) _buildImageIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupIndicator(String groupName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tag,
            size: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            groupName,
            style: AppFonts.listItemSubtitle.copyWith(
              fontSize: 10,
              color: AppColors.primary,
              fontWeight: AppFonts.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.photo_camera, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          'Photo',
          style: AppFonts.listItemSubtitle.copyWith(
            fontSize: AppFonts.bodySmall,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}