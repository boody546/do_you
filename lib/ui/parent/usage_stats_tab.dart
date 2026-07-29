import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class UsageStatsTab extends StatelessWidget {
  const UsageStatsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Usage Analytics',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF202124),
            ),
          ),
          const SizedBox(height: 16),

          // Bar Chart Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 5,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (val.toInt() >= 0 && val.toInt() < days.length) {
                                  return Text(
                                    days[val.toInt()],
                                    style: const TextStyle(color: Color(0xFF5F6368), fontSize: 11),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _makeBarGroup(0, 2.5),
                          _makeBarGroup(1, 3.2),
                          _makeBarGroup(2, 1.8),
                          _makeBarGroup(3, 4.0),
                          _makeBarGroup(4, 2.9),
                          _makeBarGroup(5, 4.5),
                          _makeBarGroup(6, 3.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top Apps Breakdown
          Text(
            'Top Used Apps Today',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF202124),
            ),
          ),
          const SizedBox(height: 12),

          _buildAppUsageTile('YouTube', '1h 45m', 0.7, AppTheme.alertRed),
          _buildAppUsageTile('Roblox', '45m', 0.4, AppTheme.warningAmber),
          _buildAppUsageTile('TikTok', '30m', 0.3, AppTheme.googleBlue),
          _buildAppUsageTile('Chrome', '15m', 0.15, AppTheme.accentGreen),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: AppTheme.familyLinkGradient,
          width: 16,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildAppUsageTile(String appName, String duration, double progress, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF202124),
                  ),
                ),
                Text(
                  duration,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE8EAED),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          ],
        ),
      ),
    );
  }
}
