// lib/utils/environment.dart - VERSI LENGKAP DENGAN FALLBACK MECHANISM

import 'package:flutter/foundation.dart';
import 'dart:io';

class Environment {
  // Default values (akan digunakan jika setBaseUrl tidak dipanggil)
  static const String _defaultBaseUrlLan = 'http://192.168.18.7:8090/responsive-message-app';
  static const String _defaultBaseUrlRootLan = 'http://192.168.18.7:8090';
  
  // Ngrok configuration (untuk production/testing)
  static const String _baseUrlNgrok = 'https://wikipedia-cherub-confound.ngrok-free.dev/responsive-message-app';
  static const String _baseUrlRootNgrok = 'https://wikipedia-cherub-confound.ngrok-free.dev';
  
  // Dynamic variables (bisa diubah saat runtime)
  static String _dynamicBaseUrl = _defaultBaseUrlLan;
  static String _dynamicBaseUrlRoot = _defaultBaseUrlRootLan;
  
  // Flag untuk menggunakan ngrok
  static bool _useNgrok = false;
  
  // ============================================================
  // SETTER METHODS - Untuk mengubah base URL dinamis
  // ============================================================
  
  /// Set base URL secara dinamis (dipanggil dari main.dart setelah API health check)
  static void setBaseUrl(String rootUrl) {
    // Bersihkan trailing slash jika ada
    String cleanRootUrl = rootUrl;
    if (cleanRootUrl.endsWith('/')) {
      cleanRootUrl = cleanRootUrl.substring(0, cleanRootUrl.length - 1);
    }
    
    _dynamicBaseUrlRoot = cleanRootUrl;
    _dynamicBaseUrl = '$cleanRootUrl/responsive-message-app';
    
    print('📍 Environment updated:');
    print('   - baseUrlRoot: $_dynamicBaseUrlRoot');
    print('   - baseUrl: $_dynamicBaseUrl');
  }
  
  /// Reset ke default values
  static void resetToDefault() {
    _dynamicBaseUrl = _defaultBaseUrlLan;
    _dynamicBaseUrlRoot = _defaultBaseUrlRootLan;
    _useNgrok = false;
    print('📍 Environment reset to default');
  }
  
  /// Enable/disable ngrok mode
  static void setUseNgrok(bool useNgrok) {
    _useNgrok = useNgrok;
    print('📍 Ngrok mode: ${_useNgrok ? "ENABLED" : "DISABLED"}');
  }
  
  // ============================================================
  // GETTER METHODS - Dengan fallback mechanism
  // ============================================================
  
  /// Mendapatkan base URL utama (dengan prioritas: ngrok > dynamic > default)
  static String get baseUrl {
    if (_useNgrok) {
      print('🌐 Using Ngrok URL: $_baseUrlNgrok');
      return _baseUrlNgrok;
    }
    
    // Pastikan _dynamicBaseUrl tidak kosong
    if (_dynamicBaseUrl.isEmpty) {
      print('⚠️ Dynamic baseUrl is empty, using default');
      return _defaultBaseUrlLan;
    }
    
    return _dynamicBaseUrl;
  }
  
  /// Mendapatkan base URL root (tanpa /responsive-message-app)
  static String get baseUrlRoot {
    if (_useNgrok) {
      return _baseUrlRootNgrok;
    }
    
    if (_dynamicBaseUrlRoot.isEmpty) {
      return _defaultBaseUrlRootLan;
    }
    
    return _dynamicBaseUrlRoot;
  }
  
  /// Mendapatkan status koneksi saat ini
  static String get currentStatus {
    if (_useNgrok) {
      return 'Ngrok Mode - $_baseUrlRootNgrok';
    }
    return 'LAN Mode - $_dynamicBaseUrlRoot';
  }
  
  // ============================================================
  // API ENDPOINTS GETTERS
  // ============================================================
  
  static String get apiUrl => '$baseUrl/api';
  static String get modulesUrl => '$baseUrl/modules';
  static String get adminApiUrl => '$modulesUrl/admin/api';
  static String getUserApiUrl() => '$modulesUrl/user/api';
  static String getGuruApiUrl() => '$modulesUrl/guru/api';
  static String getWakepsekApiUrl() => '$modulesUrl/wakepsek/api';
  static String get uploadsUrl => '$baseUrl/uploads';
  
  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  /// List semua kemungkinan base URL untuk fallback
  static List<String> getPossibleBaseUrls() {
    return [
      baseUrlRoot,                                    // Current active
      _defaultBaseUrlRootLan,                        // Default LAN
      'http://192.168.18.7:8091',                    // Fallback port 8091
      'http://localhost:8090',                       // Localhost
      'http://127.0.0.1:8090',                       // Loopback
    ];
  }
  
  /// Cek apakah base URL saat ini valid
  static bool get isNgrokMode => _useNgrok;
  
  /// Dapatkan environment info untuk debugging
  static Map<String, String> get debugInfo {
    return {
      'baseUrl': baseUrl,
      'baseUrlRoot': baseUrlRoot,
      'apiUrl': apiUrl,
      'modulesUrl': modulesUrl,
      'useNgrok': _useNgrok.toString(),
      'dynamicBaseUrl': _dynamicBaseUrl,
      'dynamicBaseUrlRoot': _dynamicBaseUrlRoot,
      'status': currentStatus,
    };
  }
  
  /// Print debug info ke console
  static void printDebugInfo() {
    print('========== ENVIRONMENT DEBUG INFO ==========');
    print('baseUrl: $baseUrl');
    print('baseUrlRoot: $baseUrlRoot');
    print('apiUrl: $apiUrl');
    print('modulesUrl: $modulesUrl');
    print('useNgrok: $_useNgrok');
    print('dynamicBaseUrl: $_dynamicBaseUrl');
    print('dynamicBaseUrlRoot: $_dynamicBaseUrlRoot');
    print('status: $currentStatus');
    print('============================================');
  }
}

// ============================================================
// EXTENSION: Untuk memudahkan akses ke environment
// ============================================================

extension EnvironmentExtension on String {
  /// Memastikan URL memiliki format yang benar
  String get sanitizeUrl {
    if (isEmpty) return this;
    String url = this;
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
  
  /// Mengecek apakah URL valid
  bool get isValidUrl {
    if (isEmpty) return false;
    return startsWith('http://') || startsWith('https://');
  }
}