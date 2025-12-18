import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'UI_design.dart'; // Import constants

class LoadingScreen extends StatefulWidget {
  final ValueNotifier<double> progressNotifier;
  final VoidCallback onCancel;

  const LoadingScreen({
    super.key,
    required this.progressNotifier,
    required this.onCancel,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Scanner Animation Section
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer concentric circles (static or subtle pulse could be added)
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kPrimaryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  // The "Insect" placeholder or image
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.bug_report,
                      size: 80,
                      color: kPrimaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                  // Rotating Scanner Line
                  AnimatedBuilder(
                    animation: _scannerController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _scannerController.value * 2 * math.pi,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                kPrimaryColor.withValues(alpha: 0.1),
                                kPrimaryColor,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 0.75, 1.0],
                              startAngle: 0.0,
                              endAngle: 0.5 * math.pi,
                              transform: const GradientRotation(0),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Search Icon Overlay
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 40,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),

            // Text Feedback
            const Text(
              'Classifying your insect...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Analyzing wing patterns and body structure',
              textAlign: TextAlign.center,
              style: TextStyle(color: kLightTextColor, fontSize: 16),
            ),

            const SizedBox(height: 48),

            // Progress Bar Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: ValueListenableBuilder<double>(
                valueListenable: widget.progressNotifier,
                builder: (context, targetProgress, child) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: targetProgress),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, _) {
                      final percent = (value * 100).toInt();
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Scanning',
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: const TextStyle(
                                  color: kLightTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: value,
                            backgroundColor: const Color(0xFF332749),
                            color: kPrimaryColor,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const Spacer(flex: 2),

            // Cancel Button
            TextButton(
              onPressed: widget.onCancel,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: kLightTextColor.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
