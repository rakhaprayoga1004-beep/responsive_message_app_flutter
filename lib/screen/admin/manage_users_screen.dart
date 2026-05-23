// lib/screen/admin/manage_users_screen.dart
import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen User'),
        backgroundColor: const Color(0xFF0B4D8A),
      ),
      body: const Center(
        child: Text('Fitur Manajemen User akan segera hadir'),
      ),
    );
  }
}