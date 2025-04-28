import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_font.dart';
import '../models/group_subscription_model.dart';

class GroupSubscriptionCard extends StatelessWidget {
  final GroupSubscriptionModel subscription;
  final VoidCallback onUnsubscribe;

  const GroupSubscriptionCard({
    super.key,
    required this.subscription,
    required this.onUnsubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subscription.name, style: AppFonts.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        'Subscribed ${DateFormat('MMM d, yyyy').format(subscription.subscribedAt)}',
                        style: AppFonts.cardSubtitle.copyWith(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onUnsubscribe,
                  icon: Icon(
                    Icons.cancel_outlined,
                    color: Colors.grey.shade400,
                  ),
                  tooltip: 'Unsubscribe',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
