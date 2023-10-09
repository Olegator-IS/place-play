import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:placeandplay/ProfileScreen.dart';

import 'EmptyScreen.dart';
import 'RegistrationProfilePage.dart';

class SuccessScreen extends StatefulWidget {
  @override
  _SuccessScreenState createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;
  bool isEmailVerified = false;
  bool verificationComplete = false; // Добавьте переменную для управления анимацией и переходом

  @override
  void initState() {
    super.initState();
    checkEmailVerification();
  }

  Future<void> checkEmailVerification() async {
    if (user != null) {
      await user!.reload();
      user = _auth.currentUser;
      isEmailVerified = user!.emailVerified;

      if (isEmailVerified) {
        setState(() {});
      }
    }
  }

  void handleEmailVerification() async {
    await checkEmailVerification();







    if (isEmailVerified) {
      // Установите verificationComplete в true, чтобы показать анимацию завершения
      setState(() {
        verificationComplete = true;
      });

      String uid = _auth.currentUser.toString();
      DocumentSnapshot userProfileSnapshot = await FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(uid)
          .get();
      // Подождите несколько секунд для отображения анимации
      await Future.delayed(Duration(seconds: 3));
      if(userProfileSnapshot.exists){
        // Перенаправьте пользователя на другой экран
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen(userId: uid)),
        );
      }else {
        // Перенаправьте пользователя на другой экран
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RegistrationProfilePage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '\n Ваш EMAIL еще не подтвержден. \n Пожалуйста, проверьте свою почту \n и подтвердите email.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Подтверждение EMAIL'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedSwitcher(
              duration: Duration(seconds: 3), // Длительность анимации
              child: verificationComplete
                  ? Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
                key: Key('check_circle'), // Уникальный ключ для анимации
              )
                  : CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            SizedBox(height: 20),
            Text(
              verificationComplete
                  ? 'Вы успешно зарегистрированы! \n Приступаем к созданию профиля...'
                  : 'Пожалуйста, подтвердите свой email.',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleEmailVerification,
              child: Text(
                'Я подтвердил свой EMAIL',
                style: TextStyle(fontSize: 20),
              ),
            ),
            SizedBox(height: 20),
            AnimatedSwitcher(
              // Добавьте AnimatedSwitcher для плавного переключения кнопки
              duration: Duration(milliseconds: 400),
              child: !isEmailVerified
                  ? ElevatedButton(
                onPressed: () async {
                  try {
                    await user!.sendEmailVerification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Письмо с подтверждением отправлено. Пожалуйста, проверьте свою почту.'),
                        duration: Duration(seconds: 5),
                      ),
                    );
                  } catch (e) {
                    print('Ошибка при отправке письма с подтверждением: $e');
                  }
                },
                child: Text(
                  'Отправить письмо с подтверждением на почту еще раз!',
                  style: TextStyle(fontSize: 12),
                ),
              )
                  : SizedBox.shrink(), // Скройте кнопку, если email подтвержден
            ),
          ],
        ),
      ),
    );
  }
}
