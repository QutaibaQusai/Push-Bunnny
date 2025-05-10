import 'package:flutter/material.dart';
import 'package:push_bunnny/core/constants/app_fonts.dart';

class SnackbarHelper {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showSnackBar({
    required BuildContext context,
    required String message,
    Color backgroundColor = const Color(0xFFFF8000), 
    Duration duration = const Duration(milliseconds: 2000),
    SnackBarAction? action,
  }) {
    final ScaffoldMessengerState messenger =
        scaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: _AnimatedSnackBarContent(
        message: message,
        textStyle: AppFonts.snackBar,
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      margin: const EdgeInsets.all(10),
      duration: duration,
      action: action != null ? _removeButtonShadow(action) : null,
      elevation: 0,
      animation: null, 
    );

    messenger.showSnackBar(snackBar);
  }

  static SnackBarAction _removeButtonShadow(SnackBarAction action) {
    return SnackBarAction(
      label: action.label,
      onPressed: action.onPressed,
      textColor: action.textColor,
      disabledTextColor: action.disabledTextColor,
      key: action.key,
    );
  }

  static void showSnackBarWithAction({
    required BuildContext context,
    required String message,
    required String actionLabel,
    required VoidCallback onPressed,
    Color backgroundColor = const Color(0xFFFF8000), 
    Color actionTextColor = Colors.white,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    final action = SnackBarAction(
      label: actionLabel,
      onPressed: onPressed,
      textColor: actionTextColor,
    );

    showSnackBar(
      context: context,
      message: message,
      backgroundColor: backgroundColor,
      duration: duration,
      action: action,
    );
  }
}

class _AnimatedSnackBarContent extends StatefulWidget {
  final String message;
  final TextStyle? textStyle;

  const _AnimatedSnackBarContent({required this.message, this.textStyle});

  @override
  State<_AnimatedSnackBarContent> createState() =>
      _AnimatedSnackBarContentState();
}

class _AnimatedSnackBarContentState extends State<_AnimatedSnackBarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Text(widget.message, style: widget.textStyle),
      ),
    );
  }
}
