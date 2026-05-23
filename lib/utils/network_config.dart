import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkConfig {
  static const String _baseUrlProduction = 'https://your-production-domain.com';
  static const String _baseUrlDevelopment = 'http://localhost:8090';
  static const String _baseUrlEmulator = 'http://10.0.2.2:8090';
  
  static String getBaseUrl() {
    if (kReleaseMode) {
      return _baseUrlProduction;
    }
    
    // FORCE menggunakan 10.0.2.2 untuk Android
    // Ini adalah solusi sementara untuk debugging
    return 'http://10.0.2.2:8090';
  }
  
  static String getApiUrl(String endpoint) {
    return '${getBaseUrl()}/responsive-message-app/api/$endpoint';
  }
  
  static String getAssetUrl(String path) {
    return '${getBaseUrl()}/responsive-message-app/$path';
  }
}