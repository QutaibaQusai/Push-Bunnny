import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_font.dart';
import '../models/notification_model.dart';

class NotificationDetailsSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailsSheet({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (notification.imageUrl != null) _buildImageSection(context),
          _buildDragHandle(),
          Flexible(child: _buildContentSection()),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          height: 4,
          width: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Image.network(
        notification.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.35,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildBodyText(),
            _buildTimestamp(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      notification.title,
      style: AppFonts.listItemTitle.copyWith(
        fontSize: AppFonts.heading3,
        fontWeight: AppFonts.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildBodyText() {
    return Text(
      notification.body,
      style: AppFonts.listItemSubtitle.copyWith(
        fontSize: AppFonts.bodyMedium,
        height: AppFonts.lineHeightRelaxed,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            DateFormat('dd MMM yyyy • HH:mm').format(notification.timestamp),
            style: AppFonts.timeStamp.copyWith(fontSize: AppFonts.caption),
          ),
        ],
      ),
    );
  }
Widget _buildCloseButton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Close',
                  style: AppFonts.listItemTitle.copyWith(
                    fontSize: AppFonts.bodyLarge,
                    fontWeight: AppFonts.semiBold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
