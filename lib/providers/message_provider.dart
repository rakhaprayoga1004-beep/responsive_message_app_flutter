import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  DashboardStats? _dashboardStats;
  List<RecentActivity> _recentActivities = [];
  bool _isLoading = false;
  String? _error;

  DashboardStats? get dashboardStats => _dashboardStats;
  List<RecentActivity> get recentActivities => _recentActivities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboardStats(String timeFilter) async {
    _isLoading = true;
    notifyListeners();

    try {
      final stats = await MessageService.getDashboardStats(timeFilter);
      _dashboardStats = stats;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _dashboardStats = DashboardStats(
        totalAssigned: 0,
        pending: 0,
        dibaca: 0,
        diproses: 0,
        disetujui: 0,
        ditolak: 0,
        selesai: 0,
        avgResponseTime: 0,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecentActivities() async {
    try {
      final activities = await MessageService.getRecentActivities();
      _recentActivities = activities;
      notifyListeners();
    } catch (e) {
      print('Error loading recent activities: $e');
    }
  }
}