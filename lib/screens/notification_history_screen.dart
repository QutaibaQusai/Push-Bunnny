import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:push_bunnny/constants/app_colors.dart';
import 'package:push_bunnny/constants/app_font.dart';
import 'package:push_bunnny/models/notification_model.dart';
import 'package:push_bunnny/screens/settings_screen%20.dart';
import 'package:push_bunnny/services/notification_service.dart';
import 'package:push_bunnny/widgets/notification_card.dart';
import 'package:push_bunnny/widgets/notification_details_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');
    final NotificationService notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Push Bunnny',
              style: AppFonts.appBarTitle.copyWith(
                fontSize: 18,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            Image.asset('assets/iconWhite.png', height: 24, width: 24),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (context) => SettingsScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),

      body: Container(
        color: AppColors.background,
        child: StreamBuilder<QuerySnapshot>(
          stream: notificationService.getUserNotifications(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return _buildErrorWidget();
            if (snapshot.connectionState == ConnectionState.waiting)
              return _buildLoadingWidget();

            final notifications = snapshot.data?.docs ?? [];
            if (notifications.isEmpty) return _buildEmptyWidget();

            return _buildNotificationList(
              context,
              notifications,
              dateFormat,
              notificationService,
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    List<QueryDocumentSnapshot> notifications,
    DateFormat dateFormat,
    NotificationService notificationService,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final doc = notifications[index];
        final notification = NotificationModel.fromFirestore(doc);

        return NotificationCard(
          notification: notification,
          dateFormat: dateFormat,
          onDelete: () => _handleDelete(context, doc.id, notificationService),
          onTap: () => _showDetailsSheet(context, notification),
        );
      },
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    String docId,
    NotificationService notificationService,
  ) async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Message',
                      style: AppFonts.sectionTitle.copyWith(
                        // Directly access static property
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'This message will be removed from this device',
                  style: AppFonts.listItemSubtitle.copyWith(
                    fontSize: 15,
                  ), // Directly access static property
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'CANCEL',
                      style: AppFonts.listItemSubtitle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'DELETE',
                      style: AppFonts.listItemSubtitle.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      await notificationService.deleteNotification(docId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message deleted',
            style: AppFonts.listItemSubtitle.copyWith(
              fontSize: 14,
            ), // Directly access static property
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(8),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDetailsSheet(BuildContext context, NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => NotificationDetailsSheet(notification: notification),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 40, color: Colors.grey.shade600),
          const SizedBox(height: 12),
          Text(
            'Unable to load messages',
            style: AppFonts.listItemSubtitle.copyWith(
              // Directly access static property
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            child: Text(
              'RETRY',
              style: AppFonts.listItemSubtitle.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
        strokeWidth: 2.5,
      ),
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
              // Directly access static property
              fontSize: 17,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Messages will appear here',
            style: AppFonts.listItemSubtitle.copyWith(
              // Directly access static property
              fontSize: 15,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
