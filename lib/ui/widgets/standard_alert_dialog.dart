import 'package:flutter/material.dart';
import 'package:push_bunnny/core/constants/app_colors.dart';
import 'package:push_bunnny/core/constants/app_fonts.dart';

class StandardAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final Color? confirmButtonColor;

  const StandardAlertDialog({
    Key? key,
    required this.title,
    required this.content,
    this.cancelText = 'Cancel',
    this.confirmText = 'Confirm',
    this.onCancel,
    this.onConfirm,
    this.confirmButtonColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity, // Ensure the dialog takes full width
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
              title,
              style: AppFonts.sectionTitle.copyWith(
                fontSize: AppFonts.bodyLarge,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 20),
            Text(
              content,
              style: AppFonts.listItemSubtitle.copyWith(
                height: AppFonts.lineHeightNormal,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onCancel ?? () => Navigator.pop(context, false),
                  child: Text(
                    cancelText,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: AppFonts.bodyMedium,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: onConfirm ?? () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: confirmButtonColor ?? AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    confirmText,
                    style: TextStyle(fontSize: AppFonts.bodyMedium),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
