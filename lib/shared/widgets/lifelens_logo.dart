
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class LifeLensLogo extends StatefulWidget {
  final double size;

  const LifeLensLogo({
    super.key,
    this.size = 240,
  });

  @override
  State<LifeLensLogo> createState() => _LifeLensLogoState();
}

class _LifeLensLogoState extends State<LifeLensLogo>
    with TickerProviderStateMixin {
  late final AnimationController _ring;
  late final AnimationController _pulse;
  late final AnimationController _particles;

  @override
  void initState() {
    super.initState();

    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _particles = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ring.dispose();
    _pulse.dispose();
    _particles.dispose();
    super.dispose();
  }

  Widget _miniNode() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(
          color: AppColors.cyan,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 240,
          height: 240,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _ring,
              _pulse,
              _particles,
            ]),
            builder: (context, child) {
              final pulseScale =
                  0.92 + (0.16 * Curves.easeInOut.transform(
                    _pulse.value,
                  ));

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Glowing background
                  Transform.scale(
                    scale: pulseScale,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple
                                .withValues(alpha: 0.25),
                            blurRadius: 45,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: AppColors.cyan
                                .withValues(alpha: 0.18),
                            blurRadius: 55,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Outer rotating ring
                  Transform.rotate(
                    angle: _ring.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(210, 210),
                      painter: _RingPainter(
                        color: AppColors.purple,
                        strokeWidth: 3,
                        dashCount: 18,
                      ),
                    ),
                  ),

                  // Inner rotating ring
                  Transform.rotate(
                    angle: -_ring.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(170, 170),
                      painter: _RingPainter(
                        color: AppColors.cyan,
                        strokeWidth: 2.5,
                        dashCount: 14,
                      ),
                    ),
                  ),

                  // Floating particles
                  ...List.generate(8, (index) {
                    final angle = index * math.pi / 4;

                    final orbit = 88 +
                        10 * math.sin(
                          _particles.value *
                              2 *
                              math.pi +
                              index,
                        );

                    return Transform.translate(
                      offset: Offset(
                        orbit * math.cos(angle),
                        orbit * math.sin(angle),
                      ),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index.isEven
                              ? AppColors.cyan
                              : AppColors.purple,
                          boxShadow: [
                            BoxShadow(
                              color: (index.isEven
                                      ? AppColors.cyan
                                      : AppColors.purple)
                                  .withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // AI chip
                  Transform.scale(
                    scale: pulseScale,
                    child: Container(
                      width: 105,
                      height: 105,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.purple,
                            AppColors.cyan,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan
                                .withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.memory_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),

                  // Four small nodes
                  Positioned(top: 52, child: _miniNode()),
                  Positioned(bottom: 52, child: _miniNode()),
                  Positioned(left: 52, child: _miniNode()),
                  Positioned(right: 52, child: _miniNode()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  _RingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 / 1.05;

    for (int i = 0; i < dashCount; i++) {
      final startAngle =
          (2 * math.pi / dashCount) * i;

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle,
        0.18,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.color != color ||
        old.strokeWidth != strokeWidth ||
        old.dashCount != dashCount;
  }
}
