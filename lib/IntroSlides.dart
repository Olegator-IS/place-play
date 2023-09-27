import 'package:flutter/material.dart';

class IntroSlides extends StatelessWidget {
  final List<Widget> slides;

  IntroSlides({required this.slides});

  @override
  Widget build(BuildContext context) {
    return PageView(
      children: slides,
    );
  }
}
