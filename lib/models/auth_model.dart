class User {
  final int id;
  final String username;
  final String email;
  final String userType;
  final String namaLengkap;
  final String? nisNip;
  final String? phoneNumber;
  final String? kelas;
  final String? jurusan;
  final String? privilegeLevel;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.userType,
    required this.namaLengkap,
    this.nisNip,
    this.phoneNumber,
    this.kelas,
    this.jurusan,
    this.privilegeLevel,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      userType: json['user_type'],
      namaLengkap: json['nama_lengkap'],
      nisNip: json['nis_nip'],
      phoneNumber: json['phone_number'],
      kelas: json['kelas'],
      jurusan: json['jurusan'],
      privilegeLevel: json['privilege_level'],
      lastLogin: json['last_login'] != null 
          ? DateTime.tryParse(json['last_login'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'user_type': userType,
      'nama_lengkap': namaLengkap,
      'nis_nip': nisNip,
      'phone_number': phoneNumber,
      'kelas': kelas,
      'jurusan': jurusan,
      'privilege_level': privilegeLevel,
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  String get displayName => namaLengkap.isNotEmpty ? namaLengkap : username;
  String get userTypeDisplay {
    switch (userType) {
      case 'Guru_BK': return 'Guru BK';
      case 'Guru_Humas': return 'Guru Humas';
      case 'Guru_Kurikulum': return 'Guru Kurikulum';
      case 'Guru_Kesiswaan': return 'Guru Kesiswaan';
      case 'Guru_Sarana': return 'Guru Sarana';
      default: return userType.replaceAll('_', ' ');
    }
  }
}

class LoginResponse {
  final bool success;
  final User? user;
  final String? token;
  final String? message;

  LoginResponse({
    required this.success,
    this.user,
    this.token,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'],
      user: json['data']?['user'] != null 
          ? User.fromJson(json['data']['user'])
          : null,
      token: json['data']?['token'],
      message: json['message'],
    );
  }
}