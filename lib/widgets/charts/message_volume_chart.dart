// lib/widgets/charts/message_volume_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/dashboard_model.dart';

class MessageVolumeChart extends StatelessWidget {
  final List<DailyMessage> data;

  const MessageVolumeChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Tidak ada data volume pesan', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Ekstrak data untuk chart
    final dates = data.map((e) => e.date).toList();
    final totalMessages = data.map((e) => e.messageCount.toDouble()).toList();
    final pendingMessages = data.map((e) => e.pendingCount.toDouble()).toList();
    final approvedMessages = data.map((e) => e.approvedCount.toDouble()).toList();

    // Hitung max Y
    double maxY = 10;
    if (totalMessages.isNotEmpty) {
      final maxTotal = totalMessages.reduce((a, b) => a > b ? a : b);
      final maxPending = pendingMessages.reduce((a, b) => a > b ? a : b);
      final maxApproved = approvedMessages.reduce((a, b) => a > b ? a : b);
      maxY = [maxTotal, maxPending, maxApproved].reduce((a, b) => a > b ? a : b);
      if (maxY > 0) {
        maxY = maxY * 1.1;
      } else {
        maxY = 10;
      }
    }

    // Format labels berdasarkan jumlah data
    List<String> labels = [];
    for (int i = 0; i < data.length; i++) {
      final date = data[i].date;
      if (data.length > 60) {
        // Untuk periode panjang (2-3 tahun), tampilkan setiap bulan
        if (date.day == 1 || i % 30 == 0) {
          labels.add('${date.month}/${date.year.toString().substring(2)}');
        } else {
          labels.add('');
        }
      } else if (data.length > 30) {
        // Untuk periode 90-180 hari, tampilkan setiap minggu
        if (i % 7 == 0) {
          labels.add('${date.day}/${date.month}');
        } else {
          labels.add('');
        }
      } else {
        // Untuk periode pendek, tampilkan setiap hari
        if (i % 3 == 0 || i == data.length - 1) {
          labels.add('${date.day}/${date.month}');
        } else {
          labels.add('');
        }
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 0.5,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: data.length > 60 ? (data.length / 12).ceil().toDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[index],
                      style: const TextStyle(fontSize: 8),
                      overflow: TextOverflow.ellipsis,
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
              reservedSize: 40,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 8),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
        lineBarsData: [
          // Line untuk Total Pesan
          LineChartBarData(
            spots: List.generate(totalMessages.length, (index) {
              return FlSpot(index.toDouble(), totalMessages[index]);
            }),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: data.length <= 60),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
          // Line untuk Pending
          LineChartBarData(
            spots: List.generate(pendingMessages.length, (index) {
              return FlSpot(index.toDouble(), pendingMessages[index]);
            }),
            isCurved: true,
            color: Colors.orange,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: data.length <= 60),
            dashArray: [5, 5],
          ),
          // Line untuk Disetujui
          LineChartBarData(
            spots: List.generate(approvedMessages.length, (index) {
              return FlSpot(index.toDouble(), approvedMessages[index]);
            }),
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: data.length <= 60),
            dashArray: [5, 5],
          ),
        ],
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              final List<LineTooltipItem> items = [];
              for (var spot in touchedSpots) {
                final index = spot.x.toInt();
                String label;
                if (spot.barIndex == 0) {
                  label = 'Total Pesan: ${spot.y.toInt()}';
                } else if (spot.barIndex == 1) {
                  label = 'Pending: ${spot.y.toInt()}';
                } else {
                  label = 'Disetujui: ${spot.y.toInt()}';
                }
                items.add(
                  LineTooltipItem(
                    '$label\n${_formatDate(data[index].date)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return items;
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}