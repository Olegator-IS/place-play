import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:placeandplay/EmptyScreen.dart';
import 'package:placeandplay/Events/EventsList.dart';
import 'package:placeandplay/ProfileScreens/EditProfileScreen.dart';
import 'package:placeandplay/WelcomeScreens/IntroSlides.dart';
import 'package:placeandplay/WelcomeScreens/LoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:ui' as ui;




import '../MapScreens/MapsPage.dart';
import 'AvatarViewScreen.dart';
import 'ProfileScreen.dart';

class ViewProfileScreen extends StatefulWidget {
  final String userId;

  ViewProfileScreen({required this.userId});

  @override
  _ViewProfileScreenState createState() => _ViewProfileScreenState();

}

class ProfileTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.person,
          color: Colors.white,
        ),
        SizedBox(width: 20.0),
        Text(
          'Просмотр пользователя',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ViewProfileScreenState extends State<ViewProfileScreen>
    with SingleTickerProviderStateMixin {
  final audioCache = AudioCache();
  final audioFilePath = 'audio/swipe.mp3'; // Путь к вашему аудиофайлу в папке assets


  int _currentIndex = 0;
  DocumentSnapshot? userDataSnapshot;
  String? avatarURL;
  String? defaultAvatarURL;
  ImageProvider<Object>? avatarImageProvider;
  ImageProvider<Object>? defaultAvatarImageProvider;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  bool _showInterestsFields = false; // Переменная для определения, показывать или скрывать поля
  bool _showActivityFields = false;
  double _interestsHeight = 0.0; // Высота поля интересов
  double _activityHeight = 0.0; // Высота поля активности
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadAvatarURL();

    // Создайте анимацию и контроллер
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3), // Уменьшена длительность анимации
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 360,
    ).animate(_animationController);

    // Добавьте слушателя, чтобы обновить виджет при завершении анимации
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
      }
    });
  }


  void _toggleInterests() {
    if (userDataSnapshot != null) {
      final gamesInterestsString = userDataSnapshot!['gamesInterests'];
      final cleanedGamesInterestsString = gamesInterestsString.replaceAll('  ', ' ');
      final gamesInterestsList = cleanedGamesInterestsString.split(', ');

      if (gamesInterestsList.isNotEmpty) {
        final newShowInterestsFields = !_showInterestsFields;
        if (newShowInterestsFields != _showInterestsFields) {
          setState(() {
            _showInterestsFields = newShowInterestsFields;
            if (_showInterestsFields) {
              // Вычислите высоту на основе количества элементов и высоты каждого элемента
              final numberOfInterests = gamesInterestsList.length;
              final itemHeight = 73.0; // Предположим высоту каждого элемента
              _interestsHeight = numberOfInterests * itemHeight;
            } else {
              _interestsHeight = 0.0;
            }
          });
        }
      }
    }
  }



  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAvatarURL() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final storageReference = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('avatars/${widget.userId}.jpg');
      final downloadURL = await storageReference.getDownloadURL();

      setState(() {
        avatarURL = downloadURL;
        if (avatarURL != null) {
          avatarImageProvider = NetworkImage(avatarURL!);
        }
      });
    } catch (e) {
      print('Ошибка при загрузке URL аватарки: $e');
      _loadDefaultAvatar();
    } finally {
      // Ждать немного, чтобы показать индикатор загрузки
      await Future.delayed(Duration(seconds: 3));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDefaultAvatar() async {
    try {
      final storageReferenceDefaultImage = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('avatars/DefaultProfileImage.png');
      final downloadURLDefaultImage = await storageReferenceDefaultImage.getDownloadURL();
      setState(() {
        defaultAvatarURL = downloadURLDefaultImage;
        if (defaultAvatarURL != null) {
          defaultAvatarImageProvider = NetworkImage(defaultAvatarURL!);
        }
      });
    } catch (e) {
      print('Ошибка при загрузке URL аватарки: $e');
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);

      final storageReference = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('avatars/${widget.userId}.jpg');

      try {
        // Начать анимацию на экране
        _animationController.forward();

        // Выполнить остальной код в фоновом потоке
        await Future.delayed(Duration.zero, () async {
          await storageReference.putFile(imageFile);
          final downloadURL = await storageReference.getDownloadURL();

          await FirebaseFirestore.instance.collection('userProfiles').doc(widget.userId).update({
            'photos': FieldValue.arrayUnion([downloadURL]),
          });

          setState(() {
            avatarURL = downloadURL;
          });
          print('Аватар успешно обновлен');

          // Завершить анимацию
          _animationController.reverse();
          _loadAvatarURL();
        });
      } catch (e) {
        print('Ошибка при загрузке изображения: $e');
        print('test');
      }
    }
  }

  void _showAvatarOptionsDialog(BuildContext context, String? currentAvatarURL) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Размытие фона
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (currentAvatarURL != null)
                  Image.network(currentAvatarURL),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Закрыть'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  String _getSkillLevelDescription(double value) {
    if (value >= 0.0 && value <= 10.0) {
      return 'Не умеею играть';
    } else if (value > 10.0 && value <= 30.0) {
      return 'Начинающий';
    } else if (value > 30.0 && value <= 50.0) {
      return 'Любитель';
    } else if (value > 50.0 && value <= 75.0) {
      return 'Полупрофессионал';
    } else if (value > 75.0 && value <= 100.0) {
      return 'Профессионал';
    }
    return '';
  }

  Future<void> _loadUserData() async {
    try {
      _playSound();
      // Выполните запрос к базе данных или получите данные заново
      final snapshot = await FirebaseFirestore.instance.collection('userProfiles').doc(widget.userId).get();

      if (snapshot.exists) {
        setState(() {
          userDataSnapshot = snapshot;
        });
      } else {
        print('Профиль не найден');
        Navigator.push(
          context,
          MaterialPageRoute(
            // builder: (context) => EmptyScreen(userId: widget.userId),
            builder: (context) => LoginPage(),

          ),
        );
      }
    } catch (e) {
      print('Ошибка при загрузке данных: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadUserData();



  }

  _playSound() async {
    await audioCache.play(audioFilePath);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ProfileTitle(),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('userProfiles').doc(widget.userId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Ошибка загрузки данных'));
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('Профиль не найден'));
            } else {

              userDataSnapshot = snapshot.data; // Установите userDataSnapshot
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              print('lohhh');
              final firstName = userData['firstName'] as String;
              final lastName = userData['lastName'] as String;
              final age = userData['age'] as String ?? 'Не указан';
              final bio = userData['bio'] ?? '';
              final gender = userData['gender'] ?? 'Не определенный';
              final city = userData['location'] as String? ?? 'Не указан';
              final gamesInterestsString = userData['gamesInterests'];
              final birthday = userData['birthday'];
              final cleanedGamesInterestsString =
              gamesInterestsString.replaceAll('  ', ' ');
              final gamesInterestsList = cleanedGamesInterestsString.split(', ');
              final skillLevels = userData['skillLevels'] as Map<String, dynamic>;
              final activity = userData['activity'] as String? ?? 'Уровень активности не определен';
              final communicationPref = userData['communicationPreferences'] as String? ?? 'Предпочтения не указаны';
              final familyStatus = userData['familyStatus'] as String? ?? 'Не указано';
              final meetingPref = userData['meetingPreferences'] as String? ?? 'Предпочтения не указаны';
              final partnerPref = userData['partnerPreferences'] as String? ?? 'Предпочтения не указаны';
              final opennessPref = userData['opennessController']  ?? 'Не указано';
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        if (!_isLoading) {
                          _showAvatarOptionsDialog(context, avatarURL);
                        }
                      },
                      child: RotationTransition(
                        turns: _rotationAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 100,
                              backgroundImage:
                              avatarImageProvider ?? defaultAvatarImageProvider,
                            ),
                            if (_isLoading) CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      '$firstName $lastName',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Город',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            city,
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Возраст',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            age,
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Пол',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            gender,
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Дата рождения',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            birthday,
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Семейное положение',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            familyStatus,
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Краткая информация',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            bio,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),



                    ElevatedButton(
                      onPressed: () {
                        // Измените высоту списка при нажатии кнопки
                        _toggleInterests();
                      },
                      child: Text('Заинтересованные виды спорта'),
                    ),

                    SizedBox(height: 20.0),

                    // Условное отображение списка элементов
                    if (_showInterestsFields)
                      Container(
                        child: gamesInterestsList.isEmpty
                            ? Text('Список заинтересованных видов спорта пуст')
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: gamesInterestsList.length,
                          itemBuilder: (context, index) {
                            final sportInterest = gamesInterestsList[index];
                            final skillLevel = skillLevels[sportInterest] ?? 0.0;
                            final skillLevelDescription = _getSkillLevelDescription(skillLevel);

                            Color tileColor;
                            if (skillLevel >= 75.0) {
                              tileColor = Colors.green;
                            } else if (skillLevel <= 75.0&&skillLevel>=50.0) {
                              tileColor = Colors.blue;
                            }else if (skillLevel < 50.0&&skillLevel>30.0) {
                              tileColor = Colors.yellowAccent;
                            }
                            else if (skillLevel < 30.0&&skillLevel>10.0) {
                              tileColor = Colors.deepOrangeAccent;
                            }
                            else {
                              tileColor = Colors.red;
                            }

                            return Column(
                              children: [
                                ListTile(
                                  title: Text(sportInterest),
                                  subtitle: Text('Уровень навыков: $skillLevelDescription'),
                                ),
                                Stack(
                                  children: [
                                    Container(
                                      height: 10, // Высота полоски прогресса
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300], // Цвет фона полоски
                                        borderRadius: BorderRadius.circular(5), // Закругленные углы
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: skillLevel / 100.0, // Фактор ширины, основанный на уровне навыков
                                      child: Container(
                                        height: 10, // Высота полоски прогресса
                                        decoration: BoxDecoration(
                                          color: tileColor, // Цвет заполняющейся части
                                          borderRadius: BorderRadius.circular(5), // Закругленные углы
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    ExpansionTile(
                      leading: Icon(
                        Icons.local_activity,
                        color: Colors.blue,
                      ),
                      title: Text(
                        'Уровень активности',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8.0),
                              Text(
                                activity,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    ExpansionTile(
                      leading: Icon(
                        Icons.timelapse_outlined, // Выберите нужную иконку
                        color: Colors.blue, // Цвет иконки
                      ),
                      title: Text(
                        'Предпочтения по встречам',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      children: [
                        SizedBox(height: 8.0),
                        Text(
                          meetingPref,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    ExpansionTile(
                      leading: Icon(
                        Icons.accessibility_new_sharp, // Выберите нужную иконку
                        color: Colors.blue, // Цвет иконки
                      ),
                      title: Text(
                        'Открытость к знакомствам',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      children: [
                        SizedBox(height: 8.0),
                        Text(
                          opennessPref,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Продолжайте также с другими ExpansionTile

                    ExpansionTile(
                      leading: Icon(
                        Icons.info_outline, // Выберите нужную иконку
                        color: Colors.blue, // Цвет иконки
                      ),
                      title: Text(
                        'Предпочтения по общению',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      children: [
                        SizedBox(height: 8.0),
                        Text(
                          communicationPref,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    ExpansionTile(
                      leading: Icon(
                        Icons.account_box_sharp, // Выберите нужную иконку
                        color: Colors.blue, // Цвет иконки
                      ),
                      title: Text(
                        'Предпочтения по партнёру',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      children: [
                        SizedBox(height: 8.0),
                        Text(
                          partnerPref,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      ],
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Ваш профиль',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Карта',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'События',
          ),

        ],
        currentIndex: _currentIndex, // Устанавливайте индекс текущей вкладки
        onTap: (int index) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          print('LOOOOOOOOOOOOH12345');
          print(prefs.getString('uid').toString());
          if (index == 0) {
            // Пользователь выбрал вкладку "Карта", перенаправляем его на пустую страницу
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: prefs.getString('uid').toString()),
              ),
            );
          } else if(index == 1){
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => MapsPage(userId: prefs.getString('uid').toString()),
              ),
            );
          }else if(index == 2){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventsList(userId: prefs.getString('uid').toString()),
              ),
            );
          }
            // Для других вкладок обновляем индекс
            setState(() {
              _currentIndex = index;
            });
          }
      ),


    );
  }


}





void main(userId) {
  runApp(MaterialApp(
    home: ProfileScreen(userId: userId),
  ));
}
