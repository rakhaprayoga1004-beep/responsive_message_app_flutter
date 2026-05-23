// lib/screen/admin/users_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMsg;
  List<dynamic> _users = [];
  int _totalUsers = 0;
  
  // Filter
  String _searchQuery = '';
  String _userTypeFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        showSnackBar('Token tidak ditemukan. Silakan login kembali.', Colors.red);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      
      final queryParams = {
        'action': 'list',
        'search': _searchQuery,
        'user_type': _userTypeFilter,
      };
      
      final uri = Uri.parse('${Constants.baseUrl}${Constants.apiUsers}')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _users = data['users'] ?? [];
            _totalUsers = data['total'] ?? 0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMsg = data['message'] ?? 'Gagal memuat data user';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        showSnackBar('Sesi login habis. Silakan login kembali.', Colors.red);
        await ApiService.logout();
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _errorMsg = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _errorMsg = 'Error: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadUsers();
    setState(() => _isRefreshing = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen User'),
        backgroundColor: const Color(0xFF0B4D8A),
        actions: [
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: SpinKitFadingCircle(color: Color(0xFF0B4D8A), size: 50))
          : _errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(_errorMsg!, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: Column(
                    children: [
                      _buildFilterBar(),
                      Expanded(
                        child: _buildUsersTable(),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari user...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _loadUsers();
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                setState(() => _searchQuery = value);
                _loadUsers();
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              value: _userTypeFilter,
              decoration: const InputDecoration(
                labelText: 'Tipe User',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('Semua')),
                ...Constants.userTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.replaceAll('_', ' ')),
                )),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _userTypeFilter = value);
                  _loadUsers();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              setState(() => _searchQuery = _searchController.text);
              _loadUsers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4D8A)),
            child: const Text('Filter'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUsersTable() {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Tidak ada data user', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (user['nama_lengkap'] ?? user['username'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              user['nama_lengkap'] ?? user['username'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['user_type']?.replaceAll('_', ' ') ?? '-', style: const TextStyle(fontSize: 12)),
                if (user['email'] != null && user['email'].isNotEmpty)
                  Text(user['email'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user['is_active'] == 1 ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user['is_active'] == 1 ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  fontSize: 11,
                  color: user['is_active'] == 1 ? Colors.green : Colors.red,
                ),
              ),
            ),
            onTap: () => _showUserDetail(user),
          ),
        );
      },
    );
  }
  
  void _showUserDetail(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['nama_lengkap'] ?? user['username'] ?? 'Detail User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Username', user['username']),
            _buildInfoRow('Nama Lengkap', user['nama_lengkap']),
            _buildInfoRow('Email', user['email']),
            _buildInfoRow('No. Telepon', user['phone_number']),
            _buildInfoRow('Tipe User', user['user_type']?.replaceAll('_', ' ') ?? '-'),
            _buildInfoRow('Status', user['is_active'] == 1 ? 'Aktif' : 'Nonaktif'),
            _buildInfoRow('Terdaftar', user['created_at']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: Text(value ?? '-', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}