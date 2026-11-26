import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/lifelens_logo.dart';

import '../../auth/data/auth_service.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../scanner/presentation/scanner_screen.dart';
import '../../history/presentation/scan_history_screen.dart';

class HomeScreen extends StatelessWidget {
  final String profileName;
  final Uint8List? profilePhoto;

  const HomeScreen({super.key, this.profileName = 'User', this.profilePhoto});

  // Show message for upcoming features
  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$message - Coming Soon!')));
  }

  // Open profile screen
  void openProfile(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(uid: user.uid)),
    );
  }

  // Logout
  Future<void> logout() async {
    await AuthService().logout();
  }

  // Confirm logout
  Future<void> confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await logout();
    }
  }

  // Profile menu
  Widget buildProfileMenu(BuildContext context, ColorScheme colors) {
    return MenuAnchor(
      style: MenuStyle(
        alignment: AlignmentDirectional.bottomEnd,
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      alignmentOffset: const Offset(0, 8),

      builder: (context, controller, child) {
        return IconButton(
          tooltip: 'Profile Menu',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.purple,
            foregroundImage: profilePhoto != null
                ? MemoryImage(profilePhoto!)
                : null,
            child: profilePhoto == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        );
      },

      menuChildren: [
        // Edit Profile
        MenuItemButton(
          onPressed: () => openProfile(context),
          leadingIcon: const Icon(Icons.person),
          child: const Text('Edit Profile'),
        ),

        // Settings
        MenuItemButton(
          onPressed: () {
            showMessage(context, 'Settings');
          },
          leadingIcon: const Icon(Icons.settings),
          child: const Text('Settings'),
        ),

        // Theme switch
        SizedBox(
          width: 240,
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeController,
            builder: (context, mode, child) {
              final isDark = mode == ThemeMode.dark;

              return SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: const Text('Dark Mode', style: TextStyle(fontSize: 14)),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                value: isDark,
                onChanged: (value) {
                  themeController.value = value
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
              );
            },
          ),
        ),

        // Logout
        MenuItemButton(
          onPressed: () => confirmLogout(context),
          leadingIcon: const Icon(Icons.logout),
          child: const Text('Logout'),
        ),
      ],
    );
  }

  // Header with animated logo
  Widget buildHeader(BuildContext context, ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Original animated splash logo
        const LifeLensLogo(size: 65),

        const SizedBox(width: 12),

        // Title and tagline
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LifeLens AI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Your world, understood by AI',
                maxLines: 2,
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Profile menu
        buildProfileMenu(context, colors),
      ],
    );
  }

  // AI Vision Scanner Card
  Widget buildScannerCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScannerScreen()),
        );
      },

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Color(0xFF632ED8), Color(0xFF182C65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.25),
              blurRadius: 25,
              spreadRadius: 2,
            ),
          ],
        ),

        child: const Column(
          children: [
            Icon(Icons.center_focus_strong, size: 65, color: AppColors.cyan),

            SizedBox(height: 18),

            Text(
              'Explore with AI Vision',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Scan anything and let AI explain it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            Text(
              'TAP TO SCAN  →',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.15, end: 0);
  }

  // Feature Card
  Widget featureCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    VoidCallback? onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap ?? () => showMessage(context, title),

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),

            const SizedBox(height: 17),

            Text(
              title,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),

            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  buildHeader(context, colors),

                  const SizedBox(height: 35),

                  // WELCOME
                  Text(
                    'Hello, $profileName 👋',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'What would you like to discover today?',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),

                  const SizedBox(height: 28),

                  // AI VISION SCANNER
                  buildScannerCard(context),

                  const SizedBox(height: 30),

                  // FEATURES HEADING
                  Text(
                    'Explore Features',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // FIRST ROW
                  Row(
                    children: [
                      Expanded(
                        child: featureCard(
                          context,
                          Icons.auto_awesome,
                          'AI Learning',
                          'Learn anything',
                          AppColors.purple,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: featureCard(
                          context,
                          Icons.mic_none,
                          'AI Voice',
                          'Talk with AI',
                          AppColors.cyan,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // SECOND ROW
                  Row(
                    children: [
                      Expanded(
                        child: featureCard(
                          context,
                          Icons.build_outlined,
                          'AI Fix-It',
                          'Solve problems',
                          Colors.orangeAccent,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: featureCard(
                          context,
                          Icons.history,
                          'History',
                          'Previous scans',
                          Colors.pinkAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ScanHistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // BOTTOM INFO
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.25),
                      ),
                    ),

                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: AppColors.cyan, size: 30),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            'Discover the world with the power of AI.',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
