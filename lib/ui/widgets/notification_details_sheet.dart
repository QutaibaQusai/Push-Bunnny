import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:push_bunnny/core/constants/app_colors.dart';
import 'package:push_bunnny/core/constants/app_fonts.dart';
import 'package:push_bunnny/features/notifications/models/notification_model.dart';

class NotificationDetailsSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailsSheet({
    Key? key,
    required this.notification,
  }) : super(key: key);

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) return;
    
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch URL: $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

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
            height: MediaQuery.of(context).size.height * 0.35,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            height: MediaQuery.of(context).size.height * 0.2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('Could not load image', style: AppFonts.cardSubtitle),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 5),
            _buildBodyText(),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildTimestamp(),
                const Spacer(),
                if (notification.groupId != null &&
                    notification.groupName != null)
                  _buildGroupInfo(),
              ],
            ),
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

  Widget _buildGroupInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign, size: 12, color: AppColors.background),
          const SizedBox(width: 4),
          Text(
            notification.groupName!,
            style: AppFonts.cardTitle.copyWith(
              color: AppColors.background,
              fontSize: AppFonts.small,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add link button if link exists
          if (notification.link != null && notification.link!.isNotEmpty)
            InkWell(
              onTap: () => _launchURL(notification.link),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Open Link',
                      style: AppFonts.listItemSubtitle.copyWith(
                        fontSize: AppFonts.caption,
                        color: AppColors.primary,
                        fontWeight: AppFonts.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd MMM yyyy • HH:mm').format(notification.timestamp),
                style: AppFonts.timeStamp.copyWith(fontSize: AppFonts.caption),
              ),
            ],
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