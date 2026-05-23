// lib/widgets/charts/status_distribution_chart.dart - Donut Chart dengan perbaikan
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/dashboard_model.dart';

class StatusDistributionChart extends StatelessWidget {
  final List<MessageStatus> data;
  
  const StatusDistributionChart({
    super.key,
    required this.data,
  });
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Tidak ada data', style: TextStyle(fontSize: 9)),
      );
    }
    
    final Map<String, int> statusMap = {
      for (var status in data) status.status: status.count,
    };
    
    final entries = statusMap.entries.where((e) => e.value > 0).toList();
    final int total = entries.fold(0, (sum, entry) => sum + entry.value);
    
    if (total == 0) {
      return const Center(
        child: Text('Belum ada pesan', style: TextStyle(fontSize: 9)),
      );
    }
    
    final Map<String, Color> statusColors = {
      'Pending': Colors.orange,
      'Dibaca': Colors.blue,
      'Diproses': Colors.cyan,
      'Disetujui': Colors.green,
      'Ditolak': Colors.red,
      'Selesai': Colors.teal,
    };
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Spacer untuk memberi jarak dari judul card (1 cm ≈ 38px)
        const SizedBox(height: 38),
        // Donut Chart
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sections: _buildPieSections(entries, statusColors, total),
                centerSpaceRadius: 25,
                sectionsSpace: 1,
                startDegreeOffset: -90,
              ),
            ),
          ),
        ),
        // Spacer antara donut chart dan legend (1 cm ≈ 38px)
        const SizedBox(height: 38),
        // Legend di bawah donut chart
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: entries.map((entry) {
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            final color = statusColors[entry.key] ?? Colors.grey;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.key}: ${entry.value} ($percentage%)',
                  style: TextStyle(
                    fontSize: 8,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
  
  List<PieChartSectionData> _buildPieSections(
    List<MapEntry<String, int>> entries,
    Map<String, Color> statusColors,
    int total,
  ) {
    return entries.map((entry) {
      final percentage = entry.value / total;
      final color = statusColors[entry.key] ?? Colors.grey;
      final percentageText = '${(percentage * 100).toStringAsFixed(0)}%';
      
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: percentage > 0.08 ? percentageText : '',
        color: color,
        radius: 45,
        titleStyle: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        showTitle: percentage > 0.08,
      );
    }).toList();
  }
}