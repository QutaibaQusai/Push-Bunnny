import 'package:flutter/material.dart';
import 'package:push_bunnny/core/constants/app_colors.dart';
import 'package:push_bunnny/core/constants/app_fonts.dart';
import 'package:push_bunnny/core/utils/snackbar_helper.dart';
import 'package:push_bunnny/features/notifications/services/group_subscription_service.dart';

class GroupSubscriptionDialog extends StatefulWidget {
  const GroupSubscriptionDialog({Key? key}) : super(key: key);

  @override
  State<GroupSubscriptionDialog> createState() => _GroupSubscriptionDialogState();
}

class _GroupSubscriptionDialogState extends State<GroupSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _groupSubscriptionService = GroupSubscriptionService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _subscribeToGroup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final groupName = _groupNameController.text.trim();

        bool isAlreadySubscribed = await _groupSubscriptionService
            .isSubscribedToGroup(groupName);
        if (isAlreadySubscribed) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'You are already subscribed to this channel';
          });
          return;
        }

        await _groupSubscriptionService.subscribeToGroup(groupName, groupName);

        if (mounted) {
          Navigator.of(context).pop(true); 
        }
      } catch (e) {
        debugPrint('Error subscribing to group: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to subscribe: ${e.toString()}';
          });
          
          SnackbarHelper.showSnackBar(
            context: context,
            message: 'Error subscribing to channel',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Subscribe to Channel',
                style: AppFonts.sectionTitle.copyWith(
                  fontSize: AppFonts.bodyLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  labelText: 'Channel Name',
                  labelStyle: TextStyle(fontSize: AppFonts.bodyMedium),
                  hintText: 'Enter channel name to subscribe',
                  prefixIcon: Icon(Icons.campaign, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red.shade300),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a channel name';
                  }

                  // Only allow alphanumeric characters and underscores
                  final validCharacters = RegExp(r'^[a-zA-Z0-9_]+$');

                  if (!validCharacters.hasMatch(value)) {
                    return 'Only letters, numbers, and underscores are allowed';
                  }

                  return null;
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: AppFonts.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: AppFonts.bodyMedium,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _subscribeToGroup,
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
                    child:
                        _isLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              'Subscribe',
                              style: TextStyle(fontSize: AppFonts.bodyMedium),
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}