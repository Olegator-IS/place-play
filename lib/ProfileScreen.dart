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

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  String? avatarURL;
  String? defaultAvatarURL;
  ImageProvider<Object>? avatarImageProvider;
  ImageProvider<Object>? defaultAvatarImageProvider;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  bool _showInterestsFields = false; // Переменная для определения, показывать или скрывать поля
  double _interestsHeight = 0.0; // Высота поля интересов

  @override
  void initState() {
    super.initState();
    _loadAvatarURL();

    // Создайте анимацию и контроллер
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5), // Длительность анимации
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
    setState(() {
      _showInterestsFields = !_showInterestsFields;
      _interestsHeight = _showInterestsFields ? 800.0 : 0.0; // Измените значение высоты по вашему желанию
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
        // Начать анимацию
        _animationController.forward();

        await storageReference.putFile(imageFile);
        final downloadURL = await storageReference.getDownloadURL();

        await FirebaseFirestore.instance.collection('userProfiles').doc(widget.userId).update({
          'photos': FieldValue.arrayUnion([downloadURL]),
        });

        setState(() {
          avatarURL = downloadURL;
        });

        print('Аватар успешно обновлен');
      } catch (e) {
        print('Ошибка при загрузке изображения: $e');
      } finally {
        // Завершить анимацию
        _animationController.reverse();
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
        title: Text('Профиль пользователя'),
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
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final firstName = userData['first_name'] as String;
            final lastName = userData['last_name'] as String;
            final city = userData['city'] as String? ?? 'Не указан';
            final gamesInterestsString = userData['games_interests'];
            final cleanedGamesInterestsString = gamesInterestsString.replaceAll('  ', ' ');
            final gamesInterestsList = cleanedGamesInterestsString.split(', ');
            final skillLevels = userData['skill_levels'] as Map<String, dynamic>;

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
                            backgroundImage: avatarImageProvider ?? defaultAvatarImageProvider,
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
                  Text(
                    'Город: $city',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 16.0),

                  ElevatedButton(
                    onPressed: _toggleInterests, // Изменено на вызов функции _toggleInterests
                    child: Text('Заинтересованные виды спорта'),
                  ),

                  // Используйте AnimatedContainer для анимации высоты
                  AnimatedContainer(
                    height: _interestsHeight,
                    duration: Duration(seconds: 10), // Установите желаемую продолжительность анимации
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: gamesInterestsList.length,
                      itemBuilder: (context, index) {
                        final sportInterest = gamesInterestsList[index];
                        final skillLevel = skillLevels[sportInterest] ?? 0.0;
                        final skillLevelDescription = _getSkillLevelDescription(skillLevel);


                        return Column(
                          children: [
                            ListTile(

                              title: Text(sportInterest),
                              subtitle: Text('Уровень навыков: $skillLevelDescription'),
                            ),
                          ],
                        );
                      },
                    ),
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
