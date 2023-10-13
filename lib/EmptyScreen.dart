import 'package:flutter/material.dart';
class EmptyScreen extends StatelessWidget {
  const EmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LOH'),

      ),
      body: Center(
        child: Text('Service is not ready yet'),
      ),
    );
  }
}