import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
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
      final gamesInterestsString = userDataSnapshot!['games_interests'];
      final cleanedGamesInterestsString =
      gamesInterestsString.replaceAll('  ', ' ');
      final gamesInterestsList = cleanedGamesInterestsString.split(', ');

      setState(() {
        _showInterestsFields = !_showInterestsFields;
        if (_showInterestsFields) {
          // Вычислите высоту на основе количества элементов и высоты каждого элемента
          final numberOfInterests = gamesInterestsList.length;
          print('test');
          print(numberOfInterests);
          final itemHeight = 73.0; // Предположим высоту каждого элемента
          _interestsHeight = numberOfInterests * itemHeight;
        } else {
          _interestsHeight = 0.0;
        }
      });
    }
  }




  void _toggleActivity() {
    setState(() {
      _showActivityFields = !_showActivityFields;
      _activityHeight = _showActivityFields ? 800.0 : 0.0; // Измените значение высоты по вашему желанию
    });
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

      final storageReference =
      firebase_storage.FirebaseStorage.instance.ref().child('avatars/${widget.userId}.jpg');
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
      await Future.delayed(Duration(seconds: 2));
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

      final storageReference =
      firebase_storage.FirebaseStorage.instance.ref().child('avatars/${widget.userId}.jpg');

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
        });
      } catch (e) {
        print('Ошибка при загрузке изображения: $e');
      }
    }
  }





  void _showAvatarOptionsDialog(BuildContext context, String? currentAvatarURL) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите действие'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('Просмотреть аватар'),
                onTap: () {
                  if (currentAvatarURL != null) {
                    // Добавьте код для просмотра текущей аватарки (currentAvatarURL) здесь
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Изменить аватар'),
                onTap: () async {
                  await _pickImage(context);
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (BuildContext context) => ProfileScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
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
            final firstName = userData['first_name'] as String;
            final lastName = userData['last_name'] as String;
            final age = userData['age'] as String;
            final bio = userData['bio'] as String;
            final gender = userData['gender'] as String;
            final city = userData['location'] as String? ?? 'Не указан';
            final gamesInterestsString = userData['games_interests'];
            final cleanedGamesInterestsString =
            gamesInterestsString.replaceAll('  ', ' ');
            final gamesInterestsList = cleanedGamesInterestsString.split(', ');
            final skillLevels = userData['skill_levels'] as Map<String, dynamic>;
            final activity = userData['activity'];
            final communicationPref = userData['communication_preferences'];
            final familyStatus = userData['family_status'];
            final meetingPref = userData['meeting_preferences'];
            final partnerPref = userData['partner_preferences'];
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
                            radius: 80,
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
                          'Биография',
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
                      ],
                    ),
                  ),


                  SizedBox(height: 20.0),

                  ElevatedButton(
                    onPressed: () {
                      // Измените высоту списка при нажатии кнопки
                      _toggleInterests();
                    },
                    child: Text('Заинтересованные виды спорта'),
                  ),

                  SizedBox(height: 20.0),



                  // Используйте AnimatedSize для анимации высоты
                  AnimatedSize(
                    duration: Duration(seconds: 1), // Уменьшена длительность анимации
                    curve: Curves.easeInOut, // Добавьте кривую анимации
                    child: Container(
                      height: _interestsHeight,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: gamesInterestsList.length,
                        itemBuilder: (context, index) {
                          final sportInterest = gamesInterestsList[index];
                          final skillLevel = skillLevels[sportInterest] ?? 0.0;
                          final skillLevelDescription =
                          _getSkillLevelDescription(skillLevel);

                          return Column(
                            children: [
                              ListTile(
                                title: Text(sportInterest),
                                subtitle:
                                Text('Уровень навыков: $skillLevelDescription'),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Измените высоту списка при нажатии кнопки
                      _toggleActivity();
                    },
                    child: Text('Уровень активности'),


                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

void main(userId) {
  runApp(MaterialApp(
    home: ProfileScreen(userId: userId),
  ));
}
