import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // Уведомление о сбросе пароля
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Password reset email sent. Check your email to reset your password.'),
          duration: Duration(seconds: 5),
        ),
      );
      // Перенаправьте пользователя на экран авторизации или другой экран
      Navigator.pop(context); // Закрываем экран сброса пароля
    } catch (e) {
      print('Error: $e');
      // Ошибка сброса пароля
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset failed. Please check your email address.'),
          duration: Duration(seconds: 5),
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
