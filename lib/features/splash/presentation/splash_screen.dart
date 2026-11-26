
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/lifelens_logo.dart';
import '../../auth/presentation/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(
      const Duration(seconds: 4),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthGate(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Reusable animated logo
              const LifeLensLogo(size: 240),

              const SizedBox(height: 38),

              const Text(
                'LifeLens AI',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Initializing Intelligence...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey.withValues(
                    alpha: 0.95,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Color(0xFF1A2238),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      AppColors.cyan,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Booting AI modules...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey.withValues(
                    alpha: 0.85,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
