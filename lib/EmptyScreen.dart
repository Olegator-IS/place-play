import 'package:flutter/material.dart';
class EmptyScreen extends StatelessWidget {
  const EmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Empty Screen'),

      ),
      body: Center(
        child: Text('This is an empty screen.'),
      ),
    );
  }
}