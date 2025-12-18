import 'package:flutter/material.dart';
import 'insert.dart' if (dart.library.html) 'insert_web.dart';

class InsectIDScreen extends StatelessWidget {
  const InsectIDScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/other_images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Top Spacer for status bar and top padding
                SizedBox(height: screenHeight * 0.08),

                // App Logo/Name
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    // Gear/settings icon as seen in the design
                    Icon(
                      Icons.settings,
                      color: Color(0xFF6B93F3), // A light blue/purple color
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Insect Identifier',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Spacer to push the main content to the bottom
                const Spacer(),

                // "AI Powered" Chip (or simulated chip)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'AI POWERED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Main Title
                const Text(
                  'Explore the\nMicro World',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    // Line height to replicate the tight stacking
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 20),

                // Description Text
                const Text(
                  'Identify insects with ease using AI-powered recognition. Your pocket entomologist is ready.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),

                // Primary Button
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    // Use a gradient to match the design's vibrant blue button
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4C6DFF), // Brighter blue
                        Color(0xFF6B93F3), // Lighter blue/purple
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4C6DFF).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors
                        .transparent, // Important for the gradient to show
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Start Classifying',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Spacer/Padding (for safe area on devices with a notch/bar)
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
