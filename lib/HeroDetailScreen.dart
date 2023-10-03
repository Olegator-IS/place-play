import 'package:flutter/material.dart';

class HeroDetailScreen extends StatelessWidget {
  final String userId;
  final ImageProvider<Object>? avatarImageProvider;

  HeroDetailScreen({required this.userId, required this.avatarImageProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Просмотр аватара'),
      ),
      body: Center(
        child: Hero(
          tag: 'avatar_${userId}', // Используйте тот же уникальный тег, что и в прошлом экране
          child: CircleAvatar(
            radius: 160,
            backgroundImage: avatarImageProvider,
          ),
        ),
      ),
    );
  }
}
