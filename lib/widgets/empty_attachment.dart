// lib/widgets/empty_attachment.dart
import 'package:flutter/material.dart';

class EmptyAttachment extends StatelessWidget {
  final String? message;
  final bool showTip;

  const EmptyAttachment({
    Key? key,
    this.message,
    this.showTip = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: const Icon(
                Icons.image,
                size: 40,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Tidak Ada Lampiran Gambar',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            if (showTip) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pesan ini tidak dilengkapi dengan gambar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}