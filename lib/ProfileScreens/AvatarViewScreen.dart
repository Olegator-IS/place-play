import 'package:flutter/material.dart';

class AvatarViewScreen extends StatelessWidget {
  final String imageUrl;

  AvatarViewScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Просмотр аватарки'),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          width: 200.0, // Установите желаемую ширину аватарки
          height: 200.0, // Установите желаемую высоту аватарки
        ),
      ),
    );
  }
}
