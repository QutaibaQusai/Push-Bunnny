import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:push_bunnny/auth_service.dart';
import 'package:push_bunnny/constants/app_colors.dart';
import 'package:push_bunnny/constants/app_font.dart';
import 'package:push_bunnny/models/group_subscription_model.dart';
import 'package:push_bunnny/models/notification_model.dart';
import 'package:push_bunnny/screens/settings_screen%20.dart';
import 'package:push_bunnny/services/group_subscription_service.dart';
import 'package:push_bunnny/services/notification_service.dart';
import 'package:push_bunnny/widgets/notification_card.dart';
import 'package:push_bunnny/widgets/notification_details_sheet.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final dateFormat = DateFormat('HH:mm');
  final NotificationService notificationService = NotificationService();
  final AuthService authService = AuthService();
  final Connectivity _connectivity = Connectivity();
  String? selectedGroupId;
  String? userId;
  bool isLoading = true;
  bool isOnline = true;
  late Stream<List<NotificationModel>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    // Cancel connectivity listener
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    try {
      final id = await authService.getUserId();
      if (mounted) {
        setState(() {
          userId = id;
          isLoading = false;
          // Initialize the notifications stream
          _notificationsStream = notificationService.getUserNotifications();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      debugPrint('Error loading user ID: $e');
    }
  }

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    if (mounted) {
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      if (mounted) {
        setState(() {
          isOnline = result != ConnectivityResult.none;

          // Refresh the notifications stream when connectivity changes
          if (userId != null) {
            if (selectedGroupId != null) {
              _notificationsStream = notificationService.getGroupNotifications(
                selectedGroupId!,
              );
            } else {
              _notificationsStream = notificationService.getUserNotifications();
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        color: AppColors.background,
        child: isLoading ? _buildLoadingWidget() : _buildLayoutWithFilter(),
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

            style: AppFonts.appBarTitle.copyWith(
              fontSize: AppFonts.heading2,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w600,
            ),
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
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const SettingsScreen(),
                duration: const Duration(milliseconds: 350),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.settings, color: AppColors.background),
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutWithFilter() {
    return Column(
      children: [
        _buildGroupFilterSection(),
        Expanded(child: _buildNotificationList()),
      ],
    );
  }

  Widget _buildNotificationList() {
    if (userId == null) return _buildEmptyWidget();

    // Update the stream if needed
    if (selectedGroupId != null) {
      _notificationsStream = notificationService.getGroupNotifications(
        selectedGroupId!,
      );
    } else {
      _notificationsStream = notificationService.getUserNotifications();
    }

    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Stream error: ${snapshot.error}');
          return _buildErrorWidget();
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingWidget();
        }

        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) return _buildEmptyWidget();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 26),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];

            return NotificationCard(
              notification: notification,
              dateFormat: dateFormat,
              onDelete:
                  () => _handleDelete(
                    context,
                    notification.id,
                    notificationService,
                  ),
              onTap: () => _showDetailsSheet(context, notification),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupFilterSection() {
    if (userId == null) return const SizedBox.shrink();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  children: [
                    _buildFilterChip(
                      label: 'All Messages',
                      icon: Icons.all_inbox,
                      isSelected: selectedGroupId == null,
                      onTap: () {
                        setState(() {
                          selectedGroupId = null;
                        });
                      },
                    ),
                    ...subscriptions.map((subscription) {
                      return _buildFilterChip(
                        label: subscription.name,
                        icon: Icons.campaign,
                        isSelected: selectedGroupId == subscription.id,
                        onTap: () {
                          setState(() {
                            selectedGroupId = subscription.id;
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
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
          boxShadow:
              isSelected
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

  Future<void> _handleDelete(
    BuildContext context,
    String docId,
    NotificationService notificationService,
  ) async {
    bool confirm =
        await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Delete Dialog",
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder:
              (_, __, ___) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Delete Message',
                        style: AppFonts.sectionTitle.copyWith(
                          fontSize: AppFonts.bodyLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'This message will be removed from this device',
                        style: AppFonts.listItemSubtitle.copyWith(
                          fontSize: AppFonts.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: AppFonts.bodyMedium,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Delete',
                              style: TextStyle(fontSize: AppFonts.bodyMedium),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ) ??
        false;

    if (confirm) {
      await notificationService.deleteNotification(docId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message deleted',
            style: AppFonts.snackBar.copyWith(fontSize: AppFonts.bodyMedium),
          ),
          backgroundColor: AppColors.primary,
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

  Widget _buildErrorWidget([String? errorMessage]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 40, color: Colors.grey.shade600),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'Unable to load messages',
            style: AppFonts.listItemSubtitle.copyWith(
              fontSize: AppFonts.bodyLarge,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          if (errorMessage != null && errorMessage.contains("index")) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                "Index error detected. You may need to create a composite index in Firestore for this query to work.",
                style: AppFonts.cardSubtitle.copyWith(
                  color: Colors.orange.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextButton(
            onPressed: () {
              setState(() {
                selectedGroupId = null;
                _loadUserId();
              });
            },
            child: Text(
              'RESET FILTER',
              style: AppFonts.listItemSubtitle.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
                fontSize: AppFonts.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
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
