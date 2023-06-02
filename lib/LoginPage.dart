import 'package:flutter/material.dart';
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Фоновый контейнер
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/back.jpg'), // Путь к фоновому изображению
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Контейнер с полями ввода
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Поле ввода E-mail
            TextField(
            decoration: InputDecoration(
            hintText: 'E-mail',
              filled: true,
              fillColor: Color.fromRGBO(01, 64, 161, 0.5),
              // Цвет с 80% прозрачности
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none, // Убираем границы
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none, // Убираем границы при фокусе
              ),
              contentPadding: EdgeInsets.all(16.0),
              prefixIcon: Icon(Icons.email, color: Colors.white), // Добавляем иконку
              suffixIcon: Icon(Icons.clear, color: Colors.white), // Добавляем иконку очистки
            ),
            style: TextStyle(color: Colors.white), // Цвет текста
          ),

                SizedBox(height: 20.0),
                // Поле ввода пароля
                TextFormField(
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    hintText: 'Пароль',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                      child: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {

                      },
                      child: Text(
                        'FORGOT PASSWORD?',
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.0),
                // Кнопка входа

              ],
            ),
          ),
        ],
      ),
    );
  }
}