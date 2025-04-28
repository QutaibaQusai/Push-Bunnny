import 'package:flutter/material.dart';
import 'package:push_bunnny/constants/app_font.dart';

class ConnectionStatusBar extends StatelessWidget {
  final bool isOnline;

  const ConnectionStatusBar({
    super.key,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            size: 16,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline. Notifications are available in offline mode.',
              style: AppFonts.cardSubtitle.copyWith(
                fontSize: AppFonts.small,
                color: Colors.red.shade700,
                fontWeight: AppFonts.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}