import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:placeandplay/EmptyScreen.dart';
import 'package:placeandplay/RegistrationProfilePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


import 'ForgotPasswordScreen.dart';
import 'ProfileScreen.dart';
import 'RegistrationPage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _passwordVisible = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String firstName = "";
  bool _isLoading = false;


  Future<void> _signInWithFacebook() async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'user_birthday', 'user_location', 'user_age_range', 'user_gender', 'user_hometown'],
      );

      if (loginResult.status == LoginStatus.success) {
        final AuthCredential facebookAuthCredential = FacebookAuthProvider.credential(loginResult.accessToken!.token);
        final UserCredential authResult = await _auth.signInWithCredential(facebookAuthCredential);

        // Получите информацию о пользователе из граф API Facebook
        final graphResponse = await http.get(
          Uri.parse('https://graph.facebook.com/v12.0/me?fields=email,location,age_range,gender,first_name,last_name'),
          headers: {
            'Authorization': 'Bearer ${loginResult.accessToken!.token}',
          },
        );

        final userData = json.decode(graphResponse.body);
        final location = userData['location'];
        final ageRange = userData['age_range'];
        final gender = userData['gender'];
        // var locationName = null;

        // if (location != null && location is Map<String, dynamic> && location.containsKey('name')) {
        //   locationName = location['name'];
        // }



        if (graphResponse.statusCode == 200) {
          final Map<String, dynamic> userData = json.decode(graphResponse.body);


          final String firstName = userData['first_name'];
          final String lastName = userData['last_name'];


          print(firstName);



          // Получите текущего пользователя
          User? user = FirebaseAuth.instance.currentUser;

          if (user != null) {
            // Получите UID пользователя
            String uid = user.uid;
            String? email = user.email;

            print(uid);

            // Обновите документ пользователя в коллекции "users"
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'first_name': firstName,
              'last_name': lastName,
              'email':email,
              // 'location':locationName
            });


            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString('first_name', firstName);
            prefs.setBool('isLoggedIn', true);


            DocumentSnapshot userProfileSnapshot = await FirebaseFirestore.instance
                .collection('userProfiles')
                .doc(uid)
                .get();

            // Проверьте, существует ли документ и имеет ли он поле 'userProfiles'
            if (userProfileSnapshot.exists) {
              // userProfiles существует для пользователя
              // Остальная часть кода
              print('Профиль пользователя существует');
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(userId: uid)));
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

            // Ваши дальнейшие действия после записи данных
          }
        } else {
          // Если запрос к граф API не удался
          print('Не удалось получить информацию о пользователе из Facebook');
        }
      } else if (loginResult.status == LoginStatus.cancelled) {
        // Пользователь отменил аутентификацию
        print('Facebook login cancelled');
      } else {
        // Произошла ошибка аутентификации через Facebook
        print('Facebook login error: ${loginResult.message}');
      }
    } catch (e) {
      print('Error: $e');
      // Обработайте ошибку аутентификации через Facebook здесь
    }
  }




  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      print('Logged in successfully');

      // Получите текущего пользователя
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Получите UID пользователя
        String uid = user.uid;

        // Запросите документ пользователя в коллекции "users"
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        print('testtttt');
        print(userSnapshot.get('first_name'));
        firstName = userSnapshot.get('first_name');
        // Проверьте, существует ли документ и имеет ли он поле 'userProfiles'
        if (userSnapshot.exists) {
          Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;

          if (userData != null && userData.containsKey('first_name')) {
            // userProfiles существует для пользователя
            print('Профиль пользователя существует');
            // Теперь у вас есть 'userProfiles' пользователя
            // Проверьте его заполненность (например, наличие данных)
            List<dynamic>? userProfileData = userData['userProfiles'] as List<dynamic>?;

              // userProfiles заполнен, перенаправляем на ProfileScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(userId: uid)), // Замените на экран ProfileScreen
              );
            } else {
            // userProfiles пуст, перенаправляем на emptyScreen
            print('Профиль пользователя не существует, начинается регистрация сначала!');

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Профиль вашего пользователя не существует'),
                  content: Text('Начинаем регистрацию информации о пользователе.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Закрываем диалоговое окно
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => RegistrationProfilePage()),
                        );
                      },
                      child: Text('Продолжить'),
                    ),
                  ],
                );
              },
            );
          }
        }
        // else {
        //   // Документ пользователя не существует
        //   print('Документ пользователя не существует');
        // }
      }
      // else {
        // Пользователь не аутентифицирован
      //   print('Пользователь не аутентифицирован');
      // }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('first_name', firstName);
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      print('Error: $e');

      // Отображаем уведомление о неправильном пароле
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incorrect email or password'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/back.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Color.fromRGBO(0, 0, 0, 0.3), // Dark semi-transparent overlay
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'E-mail',
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
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _emailController.clear();
                      },
                    ),
                  ),
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    hintText: 'Password',
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

              Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                  );
                },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      fontSize: 18,
                    ),
                  ),
                ),
                ),

                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _signInWithEmailAndPassword,
                  child: Text(
                    'LOGIN',
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
                SizedBox(height: 20.0),
                Container(
                  color: Colors.black.withOpacity(0.5), // Dark semi-transparent overlay
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    children: [
                      Text(
                        'Or sign in with',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              print('Нажали на кнопку FACEBOOK');
                              _signInWithFacebook();

                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.facebook,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 20.0),
                          GestureDetector(
                            onTap: () {
                              print('Нажали на кнопку GOOGLE');
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.android,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.0),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegistrationPage()),
                          );
                        },
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            children: [
                              TextSpan(
                                text: '\nTIME TO REGISTER',
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: LoginPage(),
  ));
}
