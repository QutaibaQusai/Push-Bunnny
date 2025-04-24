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
    final isToday = DateTime.now().difference(timestamp).inHours < 24;
    return isToday
        ? dateFormat.format(timestamp)
        : DateFormat('dd/MM').format(timestamp);
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
        child: Icon(Icons.delete, size: 24, color: Colors.white),
      ),
    );
  }

  Widget _buildCardContent(String timeString) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
        ),
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
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient,
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
                    fontWeight: AppFonts.semiBold,
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
              color: AppColors.textTertiary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (notification.imageUrl != null) _buildImageIndicator(),
        ],
      ),
    );
  }

  Widget _buildImageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
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
      ),
    );
  }
}
