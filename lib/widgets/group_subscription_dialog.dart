// In group_subscription_dialog.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_font.dart';
import '../services/group_subscription_service.dart';

class GroupSubscriptionDialog extends StatefulWidget {
  const GroupSubscriptionDialog({super.key});

  @override
  State<GroupSubscriptionDialog> createState() =>
      _GroupSubscriptionDialogState();
}

class _GroupSubscriptionDialogState extends State<GroupSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _groupSubscriptionService = GroupSubscriptionService();
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _subscribeToGroup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Use the group name as both ID and name
        final groupName = _groupNameController.text.trim();
        await _groupSubscriptionService.subscribeToGroup(groupName, groupName);

        if (mounted) {
          Navigator.of(context).pop(true); // Return success
        }
      } catch (e) {
        debugPrint('Error subscribing to group: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to subscribe to group',
                style: AppFonts.snackBar,
              ),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  labelText: 'Channel Name',
                  hintText: 'Enter channel name to subscribe',
                  prefixIcon: Icon(Icons.campaign, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a channel name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _subscribeToGroup,
                    style: ElevatedButton.styleFrom(
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
                              style: TextStyle(color: Colors.white),
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
