import 'package:flutter/material.dart';
import 'package:placeandplay/WelcomeScreens/LoginPage.dart';
import 'package:placeandplay/RegistrationScreens/RegistrationPage.dart';
import 'EmptyScreen.dart';
import 'WelcomeScreens/HelloLayout.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
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
        // '/viewProfile': (context) => ViewProfileScreen(userId: ''),

      },
    );
  }
}










