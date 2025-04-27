import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_bunnny/auth_service.dart';
import 'package:push_bunnny/constants/app_colors.dart';
import 'package:push_bunnny/constants/app_font.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_subscription_model.dart';
import '../services/group_subscription_service.dart';
import '../widgets/group_subscription_card.dart';
import '../widgets/group_subscription_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? deviceToken;
  bool isTokenCopied = false;
  bool notificationsEnabled = true;
  final GroupSubscriptionService _groupService = GroupSubscriptionService();
  final AuthService _authService = AuthService();
  String? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });
    
    await _loadDeviceToken();
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
        });
      }
    } catch (e) {
      debugPrint('Error loading user ID: $e');
    }
  }
Future<void> _loadDeviceToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  if (mounted) {
    setState(() {
      deviceToken = token;
    });
  }
}

Future<void> _checkNotificationStatus() async {
  final settings = await FirebaseMessaging.instance.getNotificationSettings();
  if (mounted) {
    setState(() {
      notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;
    });
  }
}
  void _handleToggle(bool value) async {
    setState(() {
      notificationsEnabled = value;
    });
    
    if (value) {
      // Request permissions if toggled on
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _copyTokenToClipboard() {
    if (deviceToken == null) return;

    Clipboard.setData(ClipboardData(text: deviceToken!)).then((_) {
      setState(() {
        isTokenCopied = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Token copied to clipboard', style: AppFonts.snackBar),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isTokenCopied = false;
          });
        }
      });
    });
  }

  void _showSubscribeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const GroupSubscriptionDialog(),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Subscribed to channel successfully',
            style: AppFonts.snackBar,
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleUnsubscribe(String groupId) async {
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
                    const Icon(Icons.unsubscribe, color: Colors.red, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Unsubscribe',
                      style: AppFonts.sectionTitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'You will stop receiving notifications from this Channel',
                  style: AppFonts.listItemSubtitle.copyWith(fontSize: 15),
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
                      'UNSUBSCRIBE',
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
      try {
        await _groupService.unsubscribeFromGroup(groupId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unsubscribed from channel',
                style: AppFonts.listItemSubtitle.copyWith(fontSize: 14),
              ),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
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
                style: AppFonts.listItemSubtitle.copyWith(fontSize: 14),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  // Add this widget to include in your build method:
  Widget _buildGroupSubscriptionSection() {
    if (userId == null) {
      return Center(child: CircularProgressIndicator());
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Channel Subscriptions'),
        _buildGroupSubscribeCard(),
        const SizedBox(height: 8),
        _buildSubscribedGroupsList(),
      ],
    );
  }

  Widget _buildGroupSubscribeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showSubscribeDialog,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Subscribe to a channel',
                    style: AppFonts.cardTitle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscribedGroupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupService.getUserSubscribedGroups(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('Could not load subscriptions');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
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

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptySubscriptions();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children:
                docs.map((doc) {
                  final subscription = GroupSubscriptionModel.fromFirestore(
                    doc,
                  );
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
            Icon(Icons.group_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No channel subscriptions yet',
              style: AppFonts.cardTitle.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to channel to receive topic notifications',
              style: AppFonts.cardSubtitle,
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
      body: isLoading 
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Device Settings'),
                  _buildTokenCard(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Notification Settings'),
                  _buildSettingCard(
                    'Enable Notifications',
                    'Receive push notifications from Push Bunny',
                    Icons.notifications_outlined,
                    isToggle: true,
                    initialToggleValue: notificationsEnabled,
                    onToggleChanged: _handleToggle,
                  ),
                  const SizedBox(height: 16),
                  _buildGroupSubscriptionSection(),

                  _buildSectionTitle('About Push Bunny'),
                  _buildSettingCard(
                    'About',
                    'App version and information',
                    Icons.info_outline,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Push Bunny',
                        applicationVersion: '1.0.0',
                        applicationIcon: Image.asset('assets/iconWhite.png', height: 50, width: 50),
                        applicationLegalese: '© 2025 Push Bunny',
                      );
                    },
                  ),
                  
                  // Add logout or clear data section if needed
                  _buildSectionTitle('Data Management'),
                  _buildSettingCard(
                    'Clear Notification History',
                    'Delete all notification history from this device',
                    Icons.delete_outline,
                    onTap: () {
                      // Show confirmation dialog and clear notifications
                      _showClearHistoryDialog();
                    },
                  ),
                ],
              ),
            ),
    );
  }
  
  void _showClearHistoryDialog() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Notification History'),
          content: const Text('This will delete all your notification history. This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('CLEAR', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
    
    if (confirm) {
      try {
        // Get the current user ID
        final String currentUserId = await _authService.getUserId();
        
        // Delete all notifications for the current user
        final notifications = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUserId)
            .get();
            
        // Delete in batches
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in notifications.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification history cleared'),
              backgroundColor: Colors.black87,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing history: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: AppFonts.sectionTitle),
    );
  }

  Widget _buildTokenCard() {
    String displayToken = deviceToken ?? 'Fetching token...';
    
    // If the token is the same as the user ID, highlight this information
    bool isUserIdentifier = userId != null && deviceToken != null && userId == deviceToken;

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
          onTap: _copyTokenToClipboard,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.vpn_key_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Device Token',
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
                            isTokenCopied
                                ? AppColors.success.withOpacity(0.12)
                                : AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isTokenCopied
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.primary.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isTokenCopied ? Icons.check : Icons.copy,
                            size: 14,
                            color:
                                isTokenCopied
                                    ? AppColors.success
                                    : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTokenCopied ? 'Copied' : 'Copy',
                            style: AppFonts.copyButton.copyWith(
                              color:
                                  isTokenCopied
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
                
                // Show token
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
                    displayToken,
                    style: AppFonts.monospace.copyWith(
                      height: 1.4,
                      color: AppColors.textPrimary.withOpacity(0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Show user ID info if needed
                if (isUserIdentifier) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Used as your device identifier',
                          style: AppFonts.tokenHint.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to copy your device token',
                      style: AppFonts.tokenHint.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
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
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppFonts.cardTitle),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppFonts.cardSubtitle),
                    ],
                  ),
                ),
                if (isToggle)
                  Switch(
                    value: initialToggleValue,
                    onChanged: onToggleChanged,
                    activeColor: AppColors.secondary,
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