import 'package:flutter/material.dart';
import 'package:placeandplay/LoginPage.dart';

import 'EmptyScreen.dart';
import 'HelloLayout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {


    return MaterialApp(
      home: HelloLayout(),

      routes: {
        '/LoginPage': (context) => LoginPage(),
        '/Hello': (context) => HelloLayout(),
        '/forgot_password': (context) => EmptyScreen(),
      },
    );
  }
}

class HelloLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/LoginPage');
      },
      child: Scaffold(
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
      ),
    );
  }



}




