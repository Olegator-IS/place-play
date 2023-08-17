import 'package:flutter/material.dart';
import 'LoginPage.dart';

class HelloLayout extends StatefulWidget {
  @override
  _HelloLayoutState createState() => _HelloLayoutState();
}

class _HelloLayoutState extends State<HelloLayout> {
  String _greetingText = '';

  @override
  void initState() {
    super.initState();
    _setGreetingText();
  }

  void _setGreetingText() {
    DateTime now = DateTime.now();
    int currentHour = now.hour;

    if (currentHour >= 6 && currentHour < 12) {
      setState(() {
        _greetingText = 'Доброе утро';
      });
    } else if (currentHour >= 12 && currentHour < 18) {
      setState(() {
        _greetingText = 'Добрый день';
      });
    } else {
      setState(() {
        _greetingText = 'Доброй ночи';
      });
    }

    // Ожидаем 2 секунды и переходим на LoginPage
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Цвет фона
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _greetingText,
              style: TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8), // Небольшое расстояние между строками текста
            Text(
              'Здесь рождаются игры и дружба',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
