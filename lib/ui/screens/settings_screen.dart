import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:push_bunnny/core/constants/app_colors.dart';
import 'package:push_bunnny/core/constants/app_fonts.dart';
import 'package:push_bunnny/features/auth/services/auth_service.dart';
import 'package:push_bunnny/features/notifications/models/group_subscription_model.dart';
import 'package:push_bunnny/features/notifications/providers/notification_provider.dart';
import 'package:push_bunnny/features/notifications/services/group_subscription_service.dart';
import 'package:push_bunnny/features/notifications/services/notification_service.dart';
import 'package:push_bunnny/ui/routes/routes.dart';
import 'package:push_bunnny/ui/widgets/group_subscription_card.dart';
import 'package:push_bunnny/ui/widgets/group_subscription_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final GroupSubscriptionService _groupService = GroupSubscriptionService();

  String? _deviceToken;
  bool _isTokenCopied = false;
  bool _notificationsEnabled = true;

  // Animation controller for plus icon
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadDeviceToken();
    _checkNotificationStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceToken() async {
    final token = await _notificationService.getToken();
    if (mounted) {
      setState(() {
        _deviceToken = token;
      });
    }
  }

  Future<void> _checkNotificationStatus() async {
    // This would normally check the FCM permission status
    // For simplicity, we'll just set it to true
    setState(() {
      _notificationsEnabled = true;
    });
  }

  void _copyTokenToClipboard() {
    if (_deviceToken == null) return;

    Clipboard.setData(ClipboardData(text: _deviceToken!)).then((_) {
      setState(() {
        _isTokenCopied = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Device token copied to clipboard',
            style: AppFonts.snackBar,
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isTokenCopied = false;
          });
        }
      });
    });
  }

  void _showSubscribeDialog() {
    _animationController.forward().then((_) => _animationController.reverse());
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => const GroupSubscriptionDialog(),
    ).then((result) {
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
          ),
        );
      }
    });
  }

  Future<void> _handleUnsubscribe(String groupId) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Unsubscribe', style: AppFonts.sectionTitle),
                content: Text(
                  'You will stop receiving notifications from this channel',
                  style: AppFonts.listItemSubtitle,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Unsubscribe'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      try {
        await _groupService.unsubscribeFromGroup(groupId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unsubscribed from channel',
                style: AppFonts.snackBar,
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error unsubscribing: $e',
                style: AppFonts.snackBar,
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearNotificationHistory() async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  'Clear Notification History',
                  style: AppFonts.sectionTitle,
                ),
                content: Text(
                  'This will delete all your notification history. This action cannot be undone.',
                  style: AppFonts.listItemSubtitle,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      try {
        final provider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        await provider.deleteAllNotifications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notification history cleared',
                style: AppFonts.snackBar,
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error clearing history: $e',
                style: AppFonts.snackBar,
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Device Settings'),
            _buildDeviceTokenCard(),
            const SizedBox(height: 16),
            _buildSectionTitle('Notification Settings'),
            _buildSettingCard(
              'Enable Notifications',
              'Get Push Bunny notifications',
              Icons.notifications_outlined,
              isToggle: true,
              initialToggleValue: _notificationsEnabled,
              onToggleChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildGroupSubscriptionSection(),
            _buildSectionTitle('Data Management'),
            _buildSettingCard(
              'Clear Notification History',
              'Delete all notification history from this device',
              Icons.delete_outline,
              onTap: _clearNotificationHistory,
            ),
            _buildSectionTitle('About'),
            _buildSettingCard(
              'About Push Bunny',
              'App version and information',
              Icons.info_outline,
              onTap: () => AppRouter.navigateToAbout(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showAddButton = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppFonts.sectionTitle),
          if (title == 'Channel Subscriptions')
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

  Widget _buildDeviceTokenCard() {
    // Get the user's UUID from the AuthService instead of the device token
    final userId = _authService.userId ?? 'Loading user ID...';

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
          onTap: () {
            // Copy UUID to clipboard
            Clipboard.setData(ClipboardData(text: userId)).then((_) {
              setState(() {
                _isTokenCopied = true;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'User ID copied to clipboard',
                    style: AppFonts.snackBar,
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _isTokenCopied = false;
                  });
                }
              });
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        Icons
                            .person_outline, // Changed icon to represent user ID
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'User ID', // Changed title to User ID
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
                            _isTokenCopied
                                ? AppColors.success.withOpacity(0.12)
                                : AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              _isTokenCopied
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.primary.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isTokenCopied ? Icons.check : Icons.copy,
                            size: 14,
                            color:
                                _isTokenCopied
                                    ? AppColors.success
                                    : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isTokenCopied ? 'Copied' : 'Copy',
                            style: AppFonts.copyButton.copyWith(
                              color:
                                  _isTokenCopied
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
                    userId,
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

  Widget _buildGroupSubscriptionSection() {
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
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
              'Subscribe to channels to receive topic notifications',
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
                  Icon(
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
