import 'package:flutter/material.dart';

class HelloLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/hello.jpg'),
            fit: BoxFit.cover,
          ),
          color: Colors.black.withOpacity(0.55),
        ),
        child: Center(
          child: Text(
            'Hello!',
            style: TextStyle(
              fontFamily: 'Patua One',
              fontSize: 128,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }



}