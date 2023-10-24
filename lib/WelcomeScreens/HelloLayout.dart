import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:placeandplay/EmptyScreen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Импорт пакета shared_preferences
import 'LoginPage.dart';
import '../ProfileScreens/ProfileScreen.dart';
import '../ProfileScreens/RegistrationProfilePage.dart';
import '../RegistrationScreens/SuccessScreen.dart'; // Импорт вашего LoginPage или другого экрана после успешной авторизации

class HelloLayout extends StatefulWidget {
  @override
  _HelloLayoutState createState() => _HelloLayoutState();
}

class _HelloLayoutState extends State<HelloLayout> {
  String _greetingText = '';
  String username = '';
  String firstName = '';

  @override
  void initState() {
    super.initState();
    _setGreetingText();
  }

  void _setGreetingText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    username = prefs.getString('firstName') ?? "Незнакомец";
    String _displayText = ''; // Текст для отображения
    print('HELLO');
    print(username);

    if (isLoggedIn) {
      // Если авторизован, перейти на нужный экран
      // Здесь вам нужно заменить SecondScreen() на тот экран, который вы хотите показать после успешной авторизации
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
      } else if (currentHour >= 18 && currentHour < 23) {
        setState(() {
          _greetingText = 'Добрый вечер';
        });
      } else if (currentHour >= 00 && currentHour < 6) {
        setState(() {
          _greetingText = 'Доброй ночи';
        });
      }

      User? user = FirebaseAuth.instance.currentUser;


      if (user != null) {
        if(!user.emailVerified){
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Ваш EMAIL является неподтвержденным,переходим на окно подтверждения EMAIL'),
                content: Text(
                    'Подтверждаем EMAIL'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Закрываем диалоговое окно
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SuccessScreen()),
                      );
                    },
                    child: Text('Продолжить'),
                  ),
                ],
              );
            },
          );
        }

        String uid = user.uid;
        // Тут буду проверять есть ли users коллекция
        DocumentSnapshot usersCollection = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if(!usersCollection.exists){
          prefs.setBool('isLoggedIn', false);
          prefs.setString('firstName','');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => LoginPage()),
          );
        }


        // Запросите документ пользователя в коллекции "userProfiles"
        DocumentSnapshot userProfileSnapshot = await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(uid)
            .get();

        // Проверьте, существует ли документ и имеет ли он поле 'userProfiles'
        if (userProfileSnapshot.exists) {
          // userProfiles существует для пользователя
          // Остальная часть кода
          print('Профиль пользователя существует');
          Future.delayed(Duration(seconds: 3), ()
          {
            Navigator.pushReplacement(context,
                MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: uid)));
          });
        } else {
          // userProfiles пуст, перенаправляем на emptyScreen
          print(
              'Профиль пользователя не существует, начинается регистрация сначала!');
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Профиль вашего пользователя не существует'),
                content: Text(
                    'Начинаем регистрацию информации о пользователе.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Закрываем диалоговое окно
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegistrationProfilePage()),
                      );
                    },
                    child: Text('Продолжить'),
                  ),
                ],
              );
            },
          );
        }
      }else{
        prefs.setBool('isLoggedIn', false);
        prefs.setString('firstName','');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => LoginPage()),
        );
      }
    } else {
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
      } else if (currentHour >= 18 && currentHour < 23) {
        setState(() {
          _greetingText = 'Добрый вечер';
        });
      }else if (currentHour >= 00 && currentHour < 6) {
        setState(() {
          _greetingText = 'Доброй ночи';
        });
      }




      // Ожидаем 2 секунды и переходим на LoginPage
      Future.delayed(Duration(seconds: 8), () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Цвет фона
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 8),
            Image.asset(
              'assets/images/TheLogo.png', // Путь к вашему логотипу в assets
              width: 500, // Установите желаемую ширину логотипа
              height: 500, // Установите желаемую высоту логотипа
            ),
            Text(
              _greetingText,
              style: TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              username,
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8),
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
