// lib/models/user_model.dart
class User {
  final int id;
  final String username;
  final String namaLengkap;
  final String userType;
  final String? email;
  final String? phoneNumber;
  final String? avatar;
  final String? privilegeLevel;

  User({
    required this.id,
    required this.username,
    required this.namaLengkap,
    required this.userType,
    this.email,
    this.phoneNumber,
    this.avatar,
    this.privilegeLevel,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? '',
      userType: json['user_type'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'],
      avatar: json['avatar'],
      privilegeLevel: json['privilege_level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama_lengkap': namaLengkap,
      'user_type': userType,
      'email': email,
      'phone_number': phoneNumber,
      'avatar': avatar,
      'privilege_level': privilegeLevel,
    };
  }
  
  String get initials {
    if (namaLengkap.isEmpty) return '?';
    final parts = namaLengkap.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return namaLengkap[0].toUpperCase();
  }
}