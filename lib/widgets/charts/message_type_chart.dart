// lib/widgets/charts/message_type_chart.dart - Perbaikan overflow
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/dashboard_model.dart';

class MessageTypeChart extends StatefulWidget {
  final List<MessageTypeStat> data;

  const MessageTypeChart({super.key, required this.data});

  @override
  State<MessageTypeChart> createState() => _MessageTypeChartState();
}

class _MessageTypeChartState extends State<MessageTypeChart> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getShortName(String jenisPesan) {
    if (jenisPesan.length > 12) {
      return '${jenisPesan.substring(0, 10)}..';
    }
    return jenisPesan;
  }

  @override
  Widget build(BuildContext context) {
    final allData = widget.data;
    
    if (allData.isEmpty) {
      return const Center(
        child: Text('Tidak ada data jenis pesan', style: TextStyle(fontSize: 9)),
      );
    }

    final maxY = _getMaxY(allData);
    final double barWidth = 60;
    final double totalWidth = allData.length * barWidth;

    return SizedBox(
      height: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Informasi scroll
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz, size: 8, color: Colors.grey),
                SizedBox(width: 2),
                Text('Geser untuk lihat semua', style: TextStyle(fontSize: 6)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Horizontal ScrollView dengan Scrollbar
          Expanded(
            child: RawScrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              thickness: 6,
              radius: const Radius.circular(4),
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    width: totalWidth,
                    padding: const EdgeInsets.only(bottom: 8, right: 8),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY.toDouble(),
                        barGroups: _buildBarGroups(allData),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _getInterval(maxY),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 25,
                              interval: _getInterval(maxY),
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 7),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < allData.length) {
                                  final item = allData[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Column(
                                      children: [
                                        Text(
                                          _getShortName(item.jenisPesan),
                                          style: const TextStyle(
                                            fontSize: 6,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 1),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            '${item.total}',
                                            style: const TextStyle(
                                              fontSize: 6,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final item = allData[groupIndex];
                              String label = '';
                              int value = 0;
                              switch (rodIndex) {
                                case 0: label = 'Total'; value = item.total; break;
                                case 1: label = 'Pending'; value = item.pending; break;
                                case 2: label = 'Diproses'; value = item.processed; break;
                                case 3: label = 'Disetujui'; value = item.approved; break;
                                case 4: label = 'Ditolak'; value = item.rejected; break;
                              }
                              return BarTooltipItem(
                                '${item.jenisPesan}\n$label: $value',
                                const TextStyle(color: Colors.white, fontSize: 8),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Legend Warna
          Wrap(
            spacing: 6,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem('Total', Colors.blue),
              _buildLegendItem('Pending', Colors.orange),
              _buildLegendItem('Diproses', Colors.cyan),
              _buildLegendItem('Disetujui', Colors.green),
              _buildLegendItem('Ditolak', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<MessageTypeStat> data) {
    return List.generate(data.length, (index) {
      final item = data[index];
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.total.toDouble(),
            color: Colors.blue,
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
          BarChartRodData(
            toY: item.pending.toDouble(),
            color: Colors.orange,
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
          BarChartRodData(
            toY: item.processed.toDouble(),
            color: Colors.cyan,
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
          BarChartRodData(
            toY: item.approved.toDouble(),
            color: Colors.green,
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
          BarChartRodData(
            toY: item.rejected.toDouble(),
            color: Colors.red,
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
        ],
        barsSpace: 0,
      );
    });
  }

  double _getMaxY(List<MessageTypeStat> data) {
    int max = 0;
    for (var item in data) {
      max = [
        max,
        item.total,
        item.pending,
        item.processed,
        item.approved,
        item.rejected,
      ].reduce((a, b) => a > b ? a : b);
    }
    return (max + 2).toDouble();
  }

  double _getInterval(double maxY) {
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    return 20;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}