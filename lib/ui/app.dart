import 'package:flutter/material.dart';
import 'package:push_bunnny/ui/navigation/app_router.dart';
import 'package:push_bunnny/ui/theme/app_theme.dart';


class PushBunnyApp extends StatelessWidget {
  const PushBunnyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Push Bunny',
      theme: AppTheme.lightTheme,
      navigatorKey: AppRouter.navigatorKey,
      routes: AppRouter.routes,
      initialRoute: AppRouter.notifications,
    );
  }
}
