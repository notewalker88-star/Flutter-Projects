import 'package:flutter/material.dart';
import 'data/insect_data.dart';

class InsectDetailScreen extends StatelessWidget {
  final String label;
  final String? assetPath;

  const InsectDetailScreen({super.key, required this.label, this.assetPath});

  @override
  Widget build(BuildContext context) {
    // 1. Get data; fallback if not found
    final detail =
        insectDetails[label] ??
        InsectDetail(
          commonName: label,
          scientificName: 'Unknown Species',
          description: 'No detailed information available for this insect yet.',
          tags: ['UNKNOWN'],
          dangerLevel: 'Unknown',
          size: 'Unknown',
          habitat: 'Unknown',
          behavior: '',
        );

    // 2. Determine image path (reusing local assets logic if possible, or construct it)
    // Assuming images are at assets/images/<label>.jpg or so.
    // However, the caller might pass the full path or we construct it.
    // Based on insert.dart, images seem to be in assets/images/
    // We will use a placeholder or try to match the asset naming convention.
    // For "Content" sake, let's assume we map label to an asset or just show a placeholder if missing.
    // In insert.dart, it looked like `_supportedImages` had path: `assets/images/$label.jpg`.
    // 2. Determine image path
    // Use passed assetPath if available, otherwise fallback to guessing
    final String imagePath =
        assetPath ?? 'assets/images/${label.toLowerCase()}.jpg';

    return Scaffold(
      backgroundColor: const Color(0xFF10091E), // kDarkBackground
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              onPressed: () {
                // TODO: Add to favorites
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                // TODO: Share
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image
            Stack(
              children: [
                SizedBox(
                  height: 350,
                  width: double.infinity,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.bug_report,
                            size: 80,
                            color: Colors.white54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10091E),
                          const Color(0xFF10091E).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Scientific Name
                  Text(
                    detail.commonName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail.scientificName,
                    style: TextStyle(
                      color: const Color(0xFF00FFC2), // Cyan/Greenish accent
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: detail.tags.map((tag) {
                      Color tagColor = const Color(0xFF5D3DFD); // Purple
                      if (tag == 'POLLINATOR') {
                        tagColor = Colors.green;
                      } else if (tag == 'DANGER' ||
                          tag == 'POISONOUS' ||
                          tag == 'STINGING') {
                        tagColor = Colors.redAccent;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: tagColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tag == 'POLLINATOR') ...[
                              const Icon(
                                Icons.eco,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              tag,
                              style: TextStyle(
                                color: tagColor.withValues(alpha: 1.0), // solid
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Info Cards (Size, Toxicity)
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.straighten,
                          label: 'SIZE',
                          value: detail.size,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.warning_amber_rounded,
                          label: 'TOXICITY',
                          value: detail.dangerLevel,
                          isWarning: detail.dangerLevel != 'Harmless',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Description Section
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    detail.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Habitat / Distribution Section
                  if (detail.habitat.isNotEmpty) ...[
                    const Text(
                      'Habitat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1436),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.landscape,
                            color: Color(0xFF5D3DFD),
                            size: 30,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              detail.habitat,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (detail.behavior.isNotEmpty) ...[
                    const Text(
                      'Behavior',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      detail.behavior,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // Bottom padding for FAB
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: () {
            // TODO: Implement Log Sighting
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sighting logged to history!')),
            );
          },
          backgroundColor: const Color(0xFF00FFC2),
          label: const Text(
            'Log Sighting',
            style: TextStyle(
              color: Color(0xFF10091E),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          icon: const Icon(Icons.camera_alt, color: Color(0xFF10091E)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1436),
        borderRadius: BorderRadius.circular(16),
        border: isWarning
            ? Border.all(color: Colors.redAccent.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isWarning ? Colors.redAccent : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
