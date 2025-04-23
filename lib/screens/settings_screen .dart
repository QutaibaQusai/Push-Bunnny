import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_bunnny/constants/app_colors.dart';
import 'package:push_bunnny/constants/app_font.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? deviceToken;
  bool isTokenCopied = false;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceToken();
  }

  void _loadDeviceToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      deviceToken = token;
    });
  }

  void _handleToggle(bool value) {
    setState(() {
      notificationsEnabled = value;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: AppFonts.appBarTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Device Settings'),
            _buildTokenCard(),
            const SizedBox(height: 16),
            _buildSectionTitle('Notification Settings'),
            _buildSettingCard(
              'Enable Notifications',
              'Receive push notifications from Push Bunnny',
              Icons.notifications_outlined,
              isToggle: true,
              initialToggleValue: notificationsEnabled,
              onToggleChanged: _handleToggle,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('About Push Bunnny'),
            _buildSettingCard(
              'About',
              'App version and information',
              Icons.info_outline,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: AppFonts.sectionTitle),
    );
  }

  Widget _buildTokenCard() {
    return Container(
      color: AppColors.card,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _copyTokenToClipboard,
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
                      child: const Icon(
                        Icons.vpn_key_outlined,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('Device Token', style: AppFonts.cardTitle),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isTokenCopied
                                ? Colors.green.withOpacity(0.1)
                                : AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isTokenCopied ? Icons.check : Icons.copy,
                            size: 14,
                            color:
                                isTokenCopied
                                    ? Colors.green
                                    : AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTokenCopied ? 'Copied' : 'Copy',
                            style: AppFonts.copyButton.copyWith(
                              color:
                                  isTokenCopied
                                      ? Colors.green
                                      : AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    deviceToken ?? 'Fetching token...',
                    style: AppFonts.monospace,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to copy your device token',
                  style: AppFonts.tokenHint,
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
