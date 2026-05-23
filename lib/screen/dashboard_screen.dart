import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';
import '../models/message_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final provider = Provider.of<MessageProvider>(context, listen: false);
    await provider.loadDashboardStats('all');
    await provider.loadRecentActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), centerTitle: true, backgroundColor: Colors.blue),
      body: Consumer<MessageProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.error != null) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsCards(provider.dashboardStats),
                  const SizedBox(height: 24),
                  _buildRecentActivities(provider.recentActivities),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(DashboardStats? stats) {
    if (stats == null) return const Center(child: Text('Tidak ada data statistik'));
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(title: 'Total Pesan', value: stats.totalAssigned.toString(), icon: Icons.inbox, color: Colors.blue),
        _StatCard(title: 'Pending', value: stats.pending.toString(), icon: Icons.hourglass_empty, color: Colors.orange),
        _StatCard(title: 'Diproses', value: stats.diproses.toString(), icon: Icons.settings, color: Colors.cyan),
        _StatCard(title: 'Selesai', value: (stats.disetujui + stats.selesai).toString(), icon: Icons.check_circle, color: Colors.green),
        _StatCard(title: 'Ditolak', value: stats.ditolak.toString(), icon: Icons.cancel, color: Colors.red),
        _StatCard(title: 'Rata-rata Respons', value: '${stats.avgResponseTime.toStringAsFixed(1)} jam', icon: Icons.timer, color: Colors.orange),
      ],
    );
  }

  Widget _buildRecentActivities(List<RecentActivity> activities) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Column(children: [Icon(Icons.inbox, size: 48, color: Colors.grey), SizedBox(height: 12), Text('Belum ada aktivitas terbaru')]),
      );
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Aktivitas Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 5 ? 5 : activities.length,
            itemBuilder: (context, index) {
              final a = activities[index];
              return ListTile(
                leading: CircleAvatar(backgroundColor: a.statusColor.withOpacity(0.1), child: Icon(Icons.message, size: 20, color: a.statusColor)),
                title: Text(a.senderName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(a.isiPesan.length > 50 ? '${a.isiPesan.substring(0, 50)}...' : a.isiPesan, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: a.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(a.status, style: TextStyle(fontSize: 11, color: a.statusColor, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}