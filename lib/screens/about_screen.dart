import 'package:flutter/material.dart';
import 'package:push_bunnny/constants/app_colors.dart';
import 'package:push_bunnny/constants/app_font.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeroSection(context),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    title: 'About',
                    description:
                        'Push Bunny is a simple and efficient push notification service that allows you to receive instant notifications from multiple channels.',
                    icon: Icons.info_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Version', '1.0.0', Icons.tag),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          ..._buildBackgroundDecoration(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/push_punny.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Push Bunny',
                  style: AppFonts.listItemTitle.copyWith(
                    fontSize: AppFonts.heading1, // Changed from 24 to AppFonts.heading1
                    fontWeight: AppFonts.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simple & Efficient Notifications',
                  style: AppFonts.cardSubtitle.copyWith(
                    fontSize: AppFonts.small, // Already using AppFonts.small
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundDecoration() {
    return [
      Positioned(top: 60, left: 20, child: _buildDecorativeCircle(16, 0.1)),
      Positioned(top: 120, right: 40, child: _buildDecorativeCircle(24, 0.15)),
      Positioned(
        bottom: 100,
        left: 50,
        child: _buildDecorativeCircle(20, 0.12),
      ),
      Positioned(bottom: 60, right: 30, child: _buildDecorativeCircle(16, 0.1)),
    ];
  }

  Widget _buildDecorativeCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppFonts.cardTitle.copyWith(
                  fontSize: AppFonts.bodySmall, 
                  fontWeight: AppFonts.semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppFonts.cardSubtitle.copyWith(
              fontSize: AppFonts.caption, 
              color: AppColors.textSecondary,
              height: AppFonts.lineHeightRelaxed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.secondary, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppFonts.cardTitle.copyWith(fontSize: AppFonts.bodySmall),
          ),
          const Spacer(),
          Text(
            value,
            style: AppFonts.listItemSubtitle.copyWith(
              fontSize: AppFonts.caption, 
              color: AppColors.textSecondary,
              fontWeight: AppFonts.medium,
            ),
          ),
        ],
      ),
    );
  }
}