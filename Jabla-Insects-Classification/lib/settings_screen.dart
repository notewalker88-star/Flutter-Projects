import 'package:flutter/material.dart';
import 'services/database_helper.dart';

import 'prediction_graph_screen.dart';

const Color kDarkBackground = Color(0xFF10091E);
const Color kPrimaryColor = Color(0xFF5D3DFD);
const Color kTextColor = Colors.white;
const Color kLightTextColor = Color(0xFFD6D6D6);
const Color kAccentBorderColor = Color(0xFF332749);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showClearHistoryDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1436),
        title: const Text('Clear History', style: TextStyle(color: kTextColor)),
        content: const Text(
          'Are you sure you want to delete all classification history? This action cannot be undone.',
          style: TextStyle(color: kLightTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kLightTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseHelper().clearHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('History cleared successfully'),
                    backgroundColor: kPrimaryColor,
                  ),
                );
              }
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1436),
        title: const Text('About', style: TextStyle(color: kTextColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Insect Identifier v1.0.0',
              style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'A powerful tool to identify insects using AI. Simply take a photo or choose one from your gallery to get started.',
              style: TextStyle(color: kLightTextColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1436),
        title: const Text('Help', style: TextStyle(color: kTextColor)),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to use:',
                style: TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1. Tap the camera button to take a photo of an insect.\n'
                '2. Or pick an existing photo from your gallery.\n'
                '3. Wait for the AI to analyze the image.\n'
                '4. View the result and tap on it for more details.',
                style: TextStyle(color: kLightTextColor),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        backgroundColor: kDarkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(
            icon: Icons.bar_chart,
            title: 'Prediction Frequency Graph',
            subtitle: 'Visualize your classification history',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PredictionGraphScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear History',
            subtitle: 'Remove all saved classifications',
            onTap: () => _showClearHistoryDialog(context),
            isDestructive: true,
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help',
            subtitle: 'How to use the app',
            onTap: () => _showHelpDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1436),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAccentBorderColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.1)
                : kPrimaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.redAccent : kPrimaryColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.redAccent : kTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: kLightTextColor, fontSize: 13),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: kLightTextColor,
          size: 16,
        ),
      ),
    );
  }
}
