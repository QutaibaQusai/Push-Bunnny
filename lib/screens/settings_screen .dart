import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:page_transition/page_transition.dart';
import 'package:push_bunnny/auth_service.dart';
import 'package:push_bunnny/constants/app_colors.dart';
import 'package:push_bunnny/constants/app_font.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:push_bunnny/screens/about_screen.dart';
import 'package:push_bunnny/services/hive_database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/group_subscription_model.dart';
import '../services/group_subscription_service.dart';
import '../widgets/group_subscription_card.dart';
import '../widgets/group_subscription_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  String? deviceUuid;
  bool isUuidCopied = false;
  bool notificationsEnabled = true;
  bool isOnline = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final GroupSubscriptionService _groupService = GroupSubscriptionService();
  final AuthService _authService = AuthService();
  final HiveDatabaseService _hiveService = HiveDatabaseService();
  final Connectivity _connectivity = Connectivity();
  String? userId;
  bool isLoading = true;

  // Animation controller for plus icon
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeData();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

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
        });
      }
    });
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });

    await _loadDeviceUuid();
    await _loadUserId();
    await _checkNotificationStatus();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserId() async {
    try {
      final id = await _authService.getUserId();
      if (mounted) {
        setState(() {
          userId = id;
          deviceUuid = id; // Set the UUID to the user ID
        });
      }
    } catch (e) {
      debugPrint('Error loading user ID: $e');
    }
  }

  Future<void> _loadDeviceUuid() async {
    try {
      final uuid = await _authService.getUserId();
      if (mounted) {
        setState(() {
          deviceUuid = uuid;
        });
      }
    } catch (e) {
      debugPrint('Error loading device UUID: $e');
    }
  }

  Future<void> _checkNotificationStatus() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (mounted) {
      setState(() {
        notificationsEnabled =
            settings.authorizationStatus == AuthorizationStatus.authorized;
      });
    }
  }

  void _handleToggle(bool value) async {
    setState(() {
      notificationsEnabled = value;
    });

    if (value) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _copyUuidToClipboard() {
    if (deviceUuid == null) return;

    Clipboard.setData(ClipboardData(text: deviceUuid!)).then((_) {
      setState(() {
        isUuidCopied = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('UUID copied to clipboard', style: AppFonts.snackBar),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isUuidCopied = false;
          });
        }
      });
    });
  }

  void _showSubscribeDialog() async {
    _animationController.forward().then((_) => _animationController.reverse());
    HapticFeedback.lightImpact();

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Subscribe Dialog",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const GroupSubscriptionDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Subscribed to channel successfully',
                style: AppFonts.snackBar,
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _handleUnsubscribe(String groupId) async {
    bool confirm =
        await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Unsubscribe Dialog",
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
                        'Unsubscribe',
                        style: AppFonts.sectionTitle.copyWith(
                          fontSize: AppFonts.bodyLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You will stop receiving notifications from this Channel',
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
                              'Unsubscribe',
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
      try {
        await _groupService.unsubscribeFromGroup(groupId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unsubscribed from channel',
                style: AppFonts.snackBar.copyWith(
                  fontSize: AppFonts.bodyMedium,
                ),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error unsubscribing: ${e.toString()}',
                style: AppFonts.snackBar.copyWith(
                  fontSize: AppFonts.bodyMedium,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Widget _buildGroupSubscriptionSection() {
    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Channel Subscriptions', showAddButton: true),
        const SizedBox(height: 12),
        _buildSubscribedGroupsList(),
      ],
    );
  }

  Widget _buildSubscribedGroupsList() {
    return StreamBuilder<List<GroupSubscriptionModel>>(
      stream: _groupService.getUserSubscribedGroups(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('Could not load subscriptions');
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                strokeWidth: 2.0,
              ),
            ),
          );
        }

        final subscriptions = snapshot.data ?? [];
        if (subscriptions.isEmpty) {
          return _buildEmptySubscriptions();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children:
                subscriptions.map((subscription) {
                  return GroupSubscriptionCard(
                    subscription: subscription,
                    onUnsubscribe: () => _handleUnsubscribe(subscription.id),
                  );
                }).toList(),
          ),
        );
      },
    );
  }
Widget _buildEmptySubscriptions() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No channel subscriptions yet',
            style: AppFonts.cardTitle.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Subscribe to channel to receive topic notifications',
            style: AppFonts.cardSubtitle,  // This remains smaller as it's already using cardSubtitle
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
  Widget _buildErrorWidget(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 32, color: Colors.red.shade300),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppFonts.cardSubtitle.copyWith(color: Colors.red.shade300),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        leadingWidth: 40,
        title: Text('Settings', style: AppFonts.appBarTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.secondary, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 1,
        centerTitle: false,
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.secondary,
                  ),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Device Settings'),
                          _buildUuidCard(),
                          const SizedBox(height: 16),
                          _buildSectionTitle('Notification Settings'),
                          _buildSettingCard(
                            'Enable Notifications',
                            'Get Push Bunny notifications',
                            Icons.notifications_outlined,
                            isToggle: true,
                            initialToggleValue: notificationsEnabled,
                            onToggleChanged: _handleToggle,
                          ),
                          const SizedBox(height: 16),
                          _buildGroupSubscriptionSection(),

                          _buildSectionTitle('Data Management'),
                          _buildSettingCard(
                            'Clear Notification History',
                            'Delete all notification history from this device',
                            Icons.delete_outline,
                            onTap: () {
                              _showClearHistoryDialog();
                            },
                          ),
                          _buildSectionTitle('About Push Bunny'),

                          _buildSettingCard(
                            'About',
                            'App version and information',
                            Icons.info_outline,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: const AboutScreen(),
                                  duration: const Duration(milliseconds: 350),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  void _showClearHistoryDialog() async {
    bool confirm =
        await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Clear History Dialog",
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
                        'Clear Notification History',
                        style: AppFonts.sectionTitle.copyWith(
                          fontSize: AppFonts.bodyLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'This will delete all your notification history. This action cannot be undone.',
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
                              'Clear',
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
      try {
        final String currentUserId = await _authService.getUserId();

        await _hiveService.deleteAllNotifications(currentUserId);

        if (isOnline) {
          final notifications =
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: currentUserId)
                  .get();

          final batch = FirebaseFirestore.instance.batch();
          for (var doc in notifications.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOnline
                    ? 'Notification history cleared'
                    : 'Local notification history cleared',
                style: AppFonts.snackBar.copyWith(
                  fontSize: AppFonts.bodyMedium,
                ),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error clearing history: ${e.toString()}',
                style: AppFonts.snackBar.copyWith(
                  fontSize: AppFonts.bodyMedium,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Widget _buildSectionTitle(String title, {bool showAddButton = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppFonts.sectionTitle),
          if (showAddButton)
            GestureDetector(
              onTap: _showSubscribeDialog,
              child: ScaleTransition(
                scale: Tween(begin: 1.0, end: 0.9).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUuidCard() {
    String displayUuid = deviceUuid ?? 'Fetching UUID...';

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.subtleGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _copyUuidToClipboard,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.vpn_key_outlined,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Device UUID',
                      style: AppFonts.cardTitle.copyWith(
                        letterSpacing: 0.2,
                        fontWeight: AppFonts.semiBold,
                      ),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isUuidCopied
                                ? AppColors.success.withOpacity(0.12)
                                : AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isUuidCopied
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.primary.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isUuidCopied ? Icons.check : Icons.copy,
                            size: 14,
                            color:
                                isUuidCopied
                                    ? AppColors.success
                                    : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isUuidCopied ? 'Copied' : 'Copy',
                            style: AppFonts.copyButton.copyWith(
                              color:
                                  isUuidCopied
                                      ? AppColors.success
                                      : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade50,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    displayUuid,
                    style: AppFonts.monospace.copyWith(
                      height: 1.4,
                      color: AppColors.textPrimary.withOpacity(0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    bool isToggle = false,
    bool initialToggleValue = false,
    ValueChanged<bool>? onToggleChanged,
    bool isOfflineAction = false,
  }) {
    return Container(
      color: AppColors.card,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isToggle ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isOfflineAction && !isOnline
                            ? Colors.grey.shade200
                            : AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color:
                        isOfflineAction && !isOnline
                            ? Colors.grey.shade500
                            : AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.cardTitle.copyWith(
                          color:
                              isOfflineAction && !isOnline
                                  ? Colors.grey.shade500
                                  : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppFonts.cardSubtitle.copyWith(
                          color:
                              isOfflineAction && !isOnline
                                  ? Colors.grey.shade400
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isToggle)
                  Switch(
                    value: initialToggleValue,
                    onChanged: onToggleChanged,
                    activeColor: AppColors.secondary,
                  )
                else if (isOfflineAction && !isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'Offline',
                      style: AppFonts.cardSubtitle.copyWith(
                        fontSize: AppFonts.small,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
