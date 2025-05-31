import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:push_bunnny/core/services/auth_service.dart';
import 'package:push_bunnny/ui/theme/app_colors.dart';
import 'package:push_bunnny/ui/theme/text_style.dart';
import 'package:push_bunnny/ui/widgets/snackbar_helper.dart';


class UserIdCard extends StatefulWidget {
  const UserIdCard({super.key});

  @override
  State<UserIdCard> createState() => _UserIdCardState();
}

class _UserIdCardState extends State<UserIdCard> {
  bool _isCopied = false;

  void _copyUserId() {
    final userId = AuthService.instance.userId;
    if (userId == null) return;

    Clipboard.setData(ClipboardData(text: userId)).then((_) {
      setState(() {
        _isCopied = true;
      });

      SnackbarHelper.show(
        context: context,
        message: 'User ID copied to clipboard',
      );

      // Reset the copied state after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isCopied = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.userId ?? 'Loading...';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.subtleGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _copyUserId,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Your User ID',
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isCopied
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.primaryWithOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isCopied
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCopied ? Icons.check : Icons.copy,
                            size: 14,
                            color: _isCopied ? AppColors.success : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isCopied ? 'Copied' : 'Copy',
style: AppTextStyles.timestamp.copyWith(
                              color: _isCopied ? AppColors.success : AppColors.primary,
                              fontWeight: FontWeight.w600,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    userId,
                    style: AppTextStyles.monospace.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to copy your unique user identifier',
style: AppTextStyles.timestamp.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}