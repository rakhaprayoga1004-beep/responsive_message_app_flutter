import 'package:flutter/material.dart';

class FollowupScreen extends StatelessWidget {
  const FollowupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow Up Pesan'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Halaman Follow Up Pesan'),
      ),
    );
  }
}