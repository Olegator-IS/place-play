import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../WelcomeScreens/LoginPage.dart';
import '../Slides/Slide1.dart';
import 'SuccessScreen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: RegistrationPage(),
  ));
}






class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  bool _passwordVisible = false;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
  bool _showFormFields = false; // Переменная для отображения полей формы
  String _email = ''; // Добавьте переменную для хранения email
  String _password = ''; // Добавьте переменную для хранения пароля
  String _firstName = '';
  String _lastName = '';
  bool _isRegistering = false; // Добавьте это состояние
  String _errorMessage = ''; // Добавьте переменную для хранения текста ошибки



  Future<void> _registerUser() async {
    setState(() {
      _isRegistering = true; // Показываем индикатор загрузки перед началом регистрации
    });

    try {
      // Здесь можете добавить виджет индикатора загрузки
      // Например, CircularProgressIndicator()

      if (_isRegistering) CircularProgressIndicator();
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _email, // Значение из вашего TextFormField для email
        password: _password, // Значение из вашего TextFormField для пароля
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'first_name': _firstName,
        'last_name': _lastName,
        'email': _email,
        // Другие данные пользователя
      });

      await userCredential.user!.sendEmailVerification();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SuccessScreen()),
      );

      // Регистрация прошла успешно
      // Теперь можно сохранить дополнительные данные пользователя в Firestore или Realtime Database, как вы описали в предыдущем вопросе.

      // Завершаем индикатор загрузки
      setState(() {
        _isRegistering = false;
      });
    } catch (e) {
      // Ошибка регистрации
      print('Ошибка регистрации: $e');
      print('Password ' + _password);
      print('Email  ' + _email);
      if (e.toString().contains('email-already-in-use')) {
        _errorMessage = 'Пользователь с этим email уже зарегистрирован.';
      } else if (e.toString().contains('invalid-email')) {
        _errorMessage = 'Введен некорректный email адрес.';
      } else if (e.toString().contains('weak-password')) {
        _errorMessage = 'Пароль слишком слабый. Пароль должен содержать минимум 6 символов.';
      } else {
        _errorMessage = 'Произошла ошибка при регистрации. Пожалуйста, попробуйте ещё раз.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage), // Выводим текст ошибки
          duration: Duration(seconds: 5),
        ),
      );

      // Завершаем индикатор загрузки
      setState(() {
        _isRegistering = false;
      });
    }
  }



  void _handleCarouselPageChange(bool showFormFields) {
    setState(() {
      _showFormFields = showFormFields;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showFormFields
          ? AppBar(
        title: Text('Регистрация'),
        centerTitle: true,
        // backgroundColor: Colors.transparent, // Прозрачный фон AppBar
        elevation: 0, // Убираем тень AppBar
        leading: Image.asset('assets/images/TheLogo.png'), // Ваш логотип
      )
          : null, // Скрываем AppBar до завершения карусели
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Карусель
                Visibility(
                  visible: !_showFormFields,
                  child: CarouselWidget(
                    onCarouselEnd: () {
                      // Здесь можно выполнить какие-либо действия по завершении карусели
                    },
                    onCarouselPageChange: _handleCarouselPageChange, // Передаем функцию обратного вызова
                  ),
                ),
                // Поля для отображения после прокрутки карусели
                Visibility(
                  visible: _showFormFields, // Показываем поля после прокрутки
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Имя',
                            filled: true,
                            fillColor: Color.fromRGBO(1, 64, 161, 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.all(16.0),
                            prefixIcon: Icon(Icons.person, color: Colors.white),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите имя';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _firstName = value;
                            });
                          },
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Фамилия',
                            filled: true,
                            fillColor: Color.fromRGBO(1, 64, 161, 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.all(16.0),
                            prefixIcon: Icon(Icons.person, color: Colors.white),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите фамилию';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _lastName = value;
                            });
                          },
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: Color.fromRGBO(1, 64, 161, 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.all(16.0),
                            prefixIcon: Icon(Icons.email, color: Colors.white),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty || !value.contains('@')) {
                              return 'Пожалуйста, введите корректный email';
                            }
                            final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Пожалуйста, введите корректный email';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _email = value;
                            });
                          },
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            filled: true,
                            fillColor: Color.fromRGBO(1, 64, 161, 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.all(16.0),
                            prefixIcon: Icon(Icons.lock, color: Colors.white),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_passwordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty || value.length < 6) {
                              return 'Пароль должен содержать минимум 6 символов';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _passwordController.text = value;
                            _password = value;
                          },
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Повторите пароль',
                            filled: true,
                            fillColor: Color.fromRGBO(1, 64, 161, 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.all(16.0),
                            prefixIcon: Icon(Icons.lock, color: Colors.white),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_passwordVisible,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value != _passwordController.text) {
                              return 'Пароли не совпадают';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _confirmPasswordController.text = value;
                            _password = value;
                          },
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        SizedBox(height: 16.0),
                        Row(
                          children: <Widget>[
                            Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value!;
                                });
                              },
                            ),
                            Text(
                              'Я согласен с условиями использования',
                              style: TextStyle(color: Colors.black87, fontSize: 15),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _isRegistering ? null : _registerUser,
                          child: _isRegistering
                              ? CircularProgressIndicator() // Анимация при входе
                              : Text(
                            'Зарегистрироваться',
                            style: TextStyle(fontSize: 24),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.blue,
                            onPrimary: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class CarouselWidget extends StatelessWidget {
  final Function()? onCarouselEnd;
  final Function(bool showFormFields)? onCarouselPageChange;

  CarouselWidget({required this.onCarouselEnd, required this.onCarouselPageChange});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return CarouselSlider(
      items: [
        // Здесь вы можете добавить ваши слайды для карусели
        Align(
          alignment: Alignment.center,
          child: Slide1(),
        ),
        Align(
          alignment: Alignment.center,
          child: Slide2(),
        ),
        Align(
          alignment: Alignment.center,
          child: Slide3(),
        ),
        Align(
          alignment: Alignment.center,
          child: Slide4(),
        ),
      ],
      options: CarouselOptions(
        height: screenHeight, // Высота экрана
        autoPlay: false,
        enlargeCenterPage: true,
        onPageChanged: (index, reason) {
          if (index == 3) {
            onCarouselEnd!(); // Вызываем функцию обратного вызова после завершения карусели
            onCarouselPageChange!(true); // Устанавливаем _showFormFields в true
          }
          else {
            onCarouselPageChange!(false); // Устанавливаем _showFormFields в false для других слайдов
          }
        },
      ),
    );
  }
}
