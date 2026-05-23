// lib/widgets/avatar_widget.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/helpers.dart';

class AvatarWidget extends StatelessWidget {
  final User? user;
  final String? nama;
  final String? fotoUrl;
  final double radius;
  final VoidCallback? onTap;

  const AvatarWidget({
    Key? key,
    this.user,
    this.nama,
    this.fotoUrl,
    this.radius = 24,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayName = user?.namaLengkap ?? nama ?? '?';
    final imageUrl = user?.fotoUrl ?? fotoUrl ?? '';
    
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blue.shade100,
        backgroundImage: imageUrl.isNotEmpty && imageUrl.startsWith('http')
            ? NetworkImage(imageUrl)
            : null,
        child: imageUrl.isEmpty || !imageUrl.startsWith('http')
            ? Text(
                Helpers.getInitials(displayName),
                style: TextStyle(
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              )
            : null,
      ),
    );
  }
}