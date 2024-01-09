import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            // width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/images/ForgotPassword.png', // Путь к вашему изображению
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Color(0xFFF9E7D9).withOpacity(0.1), // Цвет фона с небольшой прозрачностью
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Поле ввода
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Enter your email', // Текстовая подсказка
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.25), // Цвет фона поля ввода
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                    ),
                  ),
                  // Кнопка
                  ElevatedButton(
                    onPressed: () {
                      _resetPassword();
                    },
                    child: Text('Reset Password'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text,
      );

      // Уведомление о сбросе пароля с использованием fluttertoast
      Fluttertoast.showToast(
        msg: 'Password reset email sent. Check your email to reset your password.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 28.0,
      );

      // Перенаправление пользователя на экран авторизации или другой экран
      Navigator.pop(context); // Закрываем экран сброса пароля
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again later.';

      if (e is FirebaseAuthException) {
        if (e.code == 'too-many-requests') {
          // Обработка случая, когда слишком много запросов
          errorMessage = 'We have blocked all requests from this device due to unusual activity. Try again later.';
        } else {
          // Обработка других кодов ошибок Firebase Authentication
          errorMessage = 'Authentication error. Please check your credentials and try again.';
        }
      }
      // Ошибка сброса пароля
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to reset password\nDetailed error:\n$errorMessage'),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.red,
          elevation: 999,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }



  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
