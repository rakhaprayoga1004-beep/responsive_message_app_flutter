// lib/widgets/charts/message_type_pie_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/dashboard_model.dart';

class MessageTypePieChart extends StatelessWidget {
  final List<MessageTypeStat> data;

  const MessageTypePieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Filter data dengan total > 0
    final filteredData = data.where((item) => item.total > 0).toList();
    
    if (filteredData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Tidak ada data jenis pesan', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final totalCount = filteredData.fold<int>(0, (sum, item) => sum + item.total);
    
    // Warna untuk setiap jenis pesan
    final List<Color> pieColors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.brown,
      Colors.lime,
    ];

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: filteredData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final percentage = (item.total / totalCount) * 100;
                    return PieChartSectionData(
                      value: item.total.toDouble(),
                      title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
                      color: pieColors[index % pieColors.length],
                      radius: 90,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      badgeWidget: null,
                      badgePositionPercentageOffset: 0.98,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            // Angka total di tengah donut
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      totalCount.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B4D8A),
                      ),
                    ),
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Legend dengan warna
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: filteredData.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final percentage = (item.total / totalCount) * 100;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: pieColors[index % pieColors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.jenisPesan}: ${item.total} (${percentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}