// lib/widgets/message_preview_dialog.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessagePreviewDialog extends StatelessWidget {
  final String imageUrl;
  final String imageName;
  
  const MessagePreviewDialog({
    super.key,
    required this.imageUrl,
    required this.imageName,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text(
              'Preview: $imageName',
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            actions: [
              IconButton(
                onPressed: () {
                  // Download image
                },
                icon: const Icon(Icons.download),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 48),
                        SizedBox(height: 8),
                        Text('Gambar tidak dapat dimuat'),
                      ],
                    ),
                  ),
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}