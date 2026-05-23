// lib/utils/user_types.dart
import 'package:flutter/material.dart';

class UserTypes {
  static const List<String> allTypes = [
    'Siswa',
    'Guru',
    'Guru_BK',
    'Guru_Humas',
    'Guru_Kurikulum',
    'Guru_Kesiswaan',
    'Guru_Sarana',
    'Orang_Tua',
    'Admin',
    'Wakil_Kepala',
    'Kepala_Sekolah',
    'External',
  ];
  
  static const List<String> displayTypes = [
    'Siswa',
    'Guru',
    'Guru BK',
    'Guru Humas',
    'Guru Kurikulum',
    'Guru Kesiswaan',
    'Guru Sarana',
    'Orang Tua',
    'Admin',
    'Wakil Kepala',
    'Kepala Sekolah',
    'External',
  ];
  
  // ==========================================================================
  // PRIVILEGE LEVELS - DENGAN STANDARD
  // ==========================================================================
  static const List<String> privilegeLevels = [
    'Standard',
    'Full_Access',
    'Limited_Lv1',
    'Limited_Lv2',
    'Limited_Lv3',
  ];
  
  static String getPrivilegeDisplay(String level) {
    switch (level) {
      case 'Standard': return 'Standard (Default)';
      case 'Full_Access': return 'Akses Penuh';
      case 'Limited_Lv1': return 'Akses Terbatas Level 1';
      case 'Limited_Lv2': return 'Akses Terbatas Level 2';
      case 'Limited_Lv3': return 'Akses Terbatas Level 3';
      default: return level;
    }
  }
  
  static String getDisplayType(String type) {
    switch (type) {
      case 'Guru_BK': return 'Guru BK';
      case 'Guru_Humas': return 'Guru Humas';
      case 'Guru_Kurikulum': return 'Guru Kurikulum';
      case 'Guru_Kesiswaan': return 'Guru Kesiswaan';
      case 'Guru_Sarana': return 'Guru Sarana';
      case 'Orang_Tua': return 'Orang Tua';
      case 'Wakil_Kepala': return 'Wakil Kepala';
      case 'Kepala_Sekolah': return 'Kepala Sekolah';
      default: return type;
    }
  }
  
  static Color getTypeColor(String type) {
    switch (type) {
      case 'Admin': return Colors.red;
      case 'Wakil_Kepala':
      case 'Kepala_Sekolah': return Colors.purple;
      case 'Guru_BK':
      case 'Guru_Humas':
      case 'Guru_Kurikulum':
      case 'Guru_Kesiswaan':
      case 'Guru_Sarana': return Colors.teal;
      case 'Guru': return Colors.green;
      case 'Siswa': return Colors.blue;
      case 'Orang_Tua': return Colors.orange;
      case 'External': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }
}