// lib/widgets/charts/user_growth_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/dashboard_model.dart';

class UserGrowthChart extends StatelessWidget {
  final List<UserGrowth> data;

  const UserGrowthChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Tidak ada data pertumbuhan pengguna', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Hitung cumulative growth
    List<double> cumulativeGrowth = [];
    int cumulative = 0;
    for (var item in data) {
      cumulative += item.newUsers;
      cumulativeGrowth.add(cumulative.toDouble());
    }

    final maxNewUsers = data.map((e) => e.newUsers).reduce((a, b) => a > b ? a : b).toDouble();
    final maxCumulative = cumulativeGrowth.isNotEmpty ? cumulativeGrowth.reduce((a, b) => a > b ? a : b) : 0;
    final maxY = maxNewUsers > maxCumulative ? maxNewUsers : maxCumulative;

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
          horizontalInterval: maxY > 0 ? maxY / 5 : 10,
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
              reservedSize: 35,
              interval: maxY > 0 ? maxY / 5 : 10,
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
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Line chart untuk new users
          LineChartBarData(
            spots: List.generate(data.length, (index) {
              return FlSpot(index.toDouble(), data[index].newUsers.toDouble());
            }),
            isCurved: false,
            color: Colors.cyan,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: data.length <= 60),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.cyan.withOpacity(0.1),
            ),
          ),
          // Line chart untuk cumulative growth
          LineChartBarData(
            spots: List.generate(cumulativeGrowth.length, (index) {
              return FlSpot(index.toDouble(), cumulativeGrowth[index]);
            }),
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
        minY: 0,
        maxY: maxY > 0 ? maxY * 1.1 : 10,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                String label;
                if (spot.barIndex == 0) {
                  label = 'Pengguna Baru: ${data[index].newUsers}';
                } else {
                  label = 'Total Kumulatif: ${cumulativeGrowth[index].toInt()}';
                }
                return LineTooltipItem(
                  '$label\n${_formatDate(data[index].date)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
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