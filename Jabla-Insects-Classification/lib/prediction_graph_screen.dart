import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'services/database_helper.dart';

const Color kDarkBackground = Color(0xFF10091E);
const Color kPrimaryColor = Color(0xFF5D3DFD);
const Color kSecondaryColor = Color(0xFFC764FF);
const Color kTextColor = Colors.white;
const Color kLightTextColor = Color(0xFFD6D6D6);

class PredictionGraphScreen extends StatefulWidget {
  const PredictionGraphScreen({super.key});

  @override
  State<PredictionGraphScreen> createState() => _PredictionGraphScreenState();
}

class _PredictionGraphScreenState extends State<PredictionGraphScreen> {
  List<Map<String, dynamic>> _stats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseHelper().getClassificationStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
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
          'Prediction Frequency',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _stats.isEmpty
          ? const Center(
              child: Text(
                'No classification history yet.',
                style: TextStyle(color: kLightTextColor),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Prediction Frequency by Class',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Shows how often each insect class was predicted',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kLightTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Expanded(child: _buildChart()),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _stats.length,
                      itemBuilder: (context, index) {
                        final item = _stats[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kPrimaryColor.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: kPrimaryColor),
                            ),
                          ),
                          title: Text(
                            item['label'],
                            style: const TextStyle(color: kTextColor),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item['count']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChart() {
    // Basic normalization for graph visualization
    // We Map each label to an X index: 0, 1, 2...
    final List<FlSpot> spots = [];
    double maxCount = 0;

    for (int i = 0; i < _stats.length; i++) {
      final count = (_stats[i]['count'] as num).toDouble();
      if (count > maxCount) maxCount = count;
      spots.add(FlSpot(i.toDouble(), count));
    }

    // Add some padding to Y axis
    final yMax = maxCount * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return const FlLine(color: Color(0xFF332749), strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(color: Color(0xFF332749), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _stats.length) {
                  // Show first letter or short label to avoid clutter
                  final label = _stats[index]['label'] as String;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      label.length > 3 ? label.substring(0, 3) : label,
                      style: const TextStyle(
                        color: kLightTextColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: ((yMax / 5).ceil().toDouble() == 0
                  ? 1.0
                  : (yMax / 5).ceil().toDouble()),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: kLightTextColor, fontSize: 10),
                );
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFF332749)),
        ),
        minX: 0,
        maxX: (_stats.length - 1).toDouble(),
        minY: 0,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true, // Smooth curve
            gradient: const LinearGradient(
              colors: [kSecondaryColor, kPrimaryColor],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  kSecondaryColor.withValues(alpha: 0.3),
                  kPrimaryColor.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
