// lib/utils/validators.dart
class Validators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    
    if (!phoneRegex.hasMatch(value)) {
      return 'Nomor HP harus 10-15 digit';
    }
    return null;
  }

  static String? minLength(String? value, String fieldName, int length) {
    if (value == null || value.isEmpty) return null;
    if (value.length < length) {
      return '$fieldName minimal $length karakter';
    }
    return null;
  }
}