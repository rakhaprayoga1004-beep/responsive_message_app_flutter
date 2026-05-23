import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class AttachmentGrid extends StatefulWidget {
  final int messageId;
  final Function(String, String) onPreviewImage;
  
  const AttachmentGrid({
    super.key,
    required this.messageId,
    required this.onPreviewImage,
  });
  
  @override
  State<AttachmentGrid> createState() => _AttachmentGridState();
}

class _AttachmentGridState extends State<AttachmentGrid> {
  List<Map<String, dynamic>> _attachments = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }
  
  Future<void> _loadAttachments() async {
    try {
      final response = await ApiService.getMessageAttachments(widget.messageId);
      if (response['success'] == true) {
        setState(() {
          _attachments = List<Map<String, dynamic>>.from(response['data']['attachments'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return const SizedBox.shrink();
    }
    
    if (_attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Lampiran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _attachments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final att = _attachments[index];
              final imageUrl = att['filepath'] as String;
              final fileName = att['filename'] as String? ?? 'image.jpg';
              
              return InkWell(
                onTap: () => widget.onPreviewImage(imageUrl, fileName),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}