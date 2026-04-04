import 'package:flutter/material.dart';
import 'dart:io';

/// Widget to display customer avatar with image or initials fallback
class CustomerAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const CustomerAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF2A2A2A),
        backgroundImage: _getImageProvider(),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
    
    // Fallback to initials
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2A2A2A),
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  ImageProvider? _getImageProvider() {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    
    try {
      if (imageUrl!.startsWith('/') || imageUrl!.startsWith('file://')) {
        final path = imageUrl!.replaceFirst('file://', '');
        final file = File(path);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } else if (imageUrl!.startsWith('http')) {
        return NetworkImage(imageUrl!);
      }
    } catch (e) {
      // Return null to show fallback
    }
    return null;
  }
}
