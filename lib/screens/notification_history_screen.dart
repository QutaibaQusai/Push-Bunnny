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

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final dateFormat = DateFormat('HH:mm');
  final NotificationService notificationService = NotificationService();
  String? selectedGroupId;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Push Bunny',
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
        child: Column(
          children: [
            // Optionally show group filter dropdown
            _buildGroupFilterSection(),
            
            // Notification list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedGroupId != null 
                    ? notificationService.getGroupNotifications(selectedGroupId!)
                    : notificationService.getUserNotifications(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildGroupFilterSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc('anonymous') // Replace with actual user ID when authentication is implemented
          .collection('subscriptions')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Don't show filter if no subscriptions
        }
        
        // Add "All notifications" option
        List<DropdownMenuItem<String?>> items = [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All notifications'),
          ),
        ];
        
        // Add each group as a dropdown option
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String groupId = doc.id;
          final String groupName = data['groupName'] ?? 'Unnamed Group';
          
          items.add(DropdownMenuItem<String?>(
            value: groupId,
            child: Text(groupName),
          ));
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                'Filter by: ',
                style: AppFonts.cardTitle.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: DropdownButton<String?>(
                  value: selectedGroupId,
                  isExpanded: true,
                  underline: Container(
                    height: 1,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedGroupId = newValue;
                    });
                  },
                  items: items,
                ),
              ),
            ],
          ),
        );
      },
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'This message will be removed from this device',
                  style: AppFonts.listItemSubtitle.copyWith(
                    fontSize: 15,
                  ),
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
            ),
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
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                // Refresh the state to trigger a rebuild
              });
            },
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
              fontSize: 17,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Messages will appear here',
            style: AppFonts.listItemSubtitle.copyWith(
              fontSize: 15,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}