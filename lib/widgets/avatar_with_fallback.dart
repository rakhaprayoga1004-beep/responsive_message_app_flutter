// lib/widgets/avatar_with_fallback.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarWithFallback extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AvatarWithFallback({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24,
    this.backgroundColor,
    this.onTap,
  });

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.blue.shade100,
        backgroundImage: imageUrl != null && imageUrl!.isNotEmpty && imageUrl!.startsWith('http')
            ? CachedNetworkImageProvider(imageUrl!)
            : null,
        child: imageUrl == null || imageUrl!.isEmpty || !imageUrl!.startsWith('http')
            ? Text(
                _getInitials(),
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