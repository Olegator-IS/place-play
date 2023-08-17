import 'package:flutter/material.dart';
import 'package:placeandplay/LoginPage.dart';
import 'package:placeandplay/RegistrationPage.dart';
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
      title: 'Place and Play',
      home: HelloLayout(),

      routes: {
        '/LoginPage': (context) => LoginPage(),
        '/Hello': (context) => HelloLayout(),
        '/forgot_password': (context) => EmptyScreen(),
         '/Registration':(context) => RegistrationPage(),
      },
    );
  }
}










