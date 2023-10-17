import 'dart:math';

import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';



import 'ProfileScreen.dart';


void main(userId) {
  runApp(MaterialApp(home: EditProfileScreen(userId: userId)));
}

class EditProfileScreen extends StatefulWidget {
  final String userId;

  EditProfileScreen({required this.userId});

  @override
  _EditProfileScreenState createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  ImageProvider<Object>? avatarImageProvider;
  ImageProvider<Object>? defaultAvatarImageProvider;

  final GlobalKey<FormState> _formKeyTab1 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyTab2 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyTab3 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyTab4 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyTab5 = GlobalKey<FormState>();


  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  List<String> _selectedGameInterests = [];
  String? _selectedGameInterest;
  String? _selectedCommunicationPreferences;
  String? _selectedMeetingPreferences;
  String? _selectedActivityPreferences;
  String? _selectedFamilyStatus;
  String? _selectedOpennessPreferences;
  String? _selectedPartnerPreferences;
  Map<String, double> _skillLevels = {};
  final TextEditingController _locationController = TextEditingController();

  // final TextEditingController _availabilityController = TextEditingController();
  // final TextEditingController _meetingPreferencesController = TextEditingController();
  // final TextEditingController _communicationPreferencesController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // final TextEditingController _partnerPreferencesController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _photosController = TextEditingController();

  // final TextEditingController _activityController = TextEditingController();
  // final TextEditingController _familyStatusController = TextEditingController();
  // final TextEditingController _opennessController = TextEditingController();

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;

      FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(uid)
          .get()
          .then((userDoc) {
        if (userDoc.exists) {
          Map<String, dynamic>? userData =
          userDoc.data() as Map<String, dynamic>?;

          if (userData != null) {
            setState(() {
              _firstNameController.text = userData['first_name'] ?? '';
              _lastNameController.text = userData['last_name'] ?? '';
              _genderController.text = userData['gender'] ?? '';
              _birthdayController.text = userData['birthday'] ?? '';
              _ageController.text = userData['age'] ?? '';
              _selectedCommunicationPreferences = userData['communication_preferences'] ?? '';
              _selectedMeetingPreferences = userData['meeting_preferences'] ?? '';
              _selectedActivityPreferences = userData['activity'] ?? '';
              _selectedFamilyStatus = userData['family_status'] ?? '';
              _selectedOpennessPreferences = userData['openness_controller'] ?? '';
              _selectedPartnerPreferences = userData['partner_preferences'] ?? '';
              _bioController.text = userData['bio'] ?? '';
              _locationController.text = userData['location'] ?? '';
              final skillLevels = userData['skill_levels'] as Map<String, dynamic>?;
              if (skillLevels != null) {
                _skillLevels = skillLevels.map((key, value) => MapEntry(key.trim(), value.toDouble()));
                print('Навыки $skillLevels');
              } else {
                // Устанавливаем уровень навыков по умолчанию (например, 50.0) для всех видов спорта
                _selectedGameInterests.forEach((interest) {
                  _skillLevels[interest] = 50.0;
                  print('444444');
                });
              }
              // final gamesInterestsString = userData['games_interests'];
              // final _selectedGameInterests = gamesInterestsString.split(', ');
              // final selectedSports = _selectedGameInterests.join(', ');

              final gamesInterestsString = userData['games_interests'];
              _selectedGameInterests = gamesInterestsString.split(', ');
              _selectedGameInterests.forEach((interest) {
                if (!_selectedGameInterests.contains(interest)) {
                  _selectedGameInterests.add(interest);
                  print('loooooh');
                }
              });
            });
          }
        }
      });
    } else {
      // такого не может быть в принципе, чтобы во время редактирования профиля, пользователь не был найден :)
    }
  }

  void showStyledToast() {
    Fluttertoast.showToast(
        msg: "This is Center Short Toast",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }



  Future<List<String>> getGamesInterestsFromFirestore() async {
    final QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('listOfSports').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['nameRu'] as String? ?? '';
    }).toList();
  }


  Color _generateRandomColor() {
    final Random random = Random();
    final int red = random.nextInt(256);
    final int green = random.nextInt(256);
    final int blue = random.nextInt(256);
    return Color.fromARGB(255, red, green, blue);
  }

  Future<List<String>> getCommunicationPreferences() async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('communicationPreferences')
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['nameRu'] as String? ?? '';
    }).toList();
  }

  Future<List<String>> getMeetingPreferences() async {
    final QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('meetingPreferences').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['nameRu'] as String? ?? '';
    }).toList();
  }

  Future<List<String>> getActivityPreferences() async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('activityPreferences')
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['nameRu'] as String? ?? '';
    }).toList();
  }

  Future<List<String>> getFamilyStatus() async {
    final QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('familyStatus').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['nameRu'] as String? ?? '';
    }).toList();
  }

  Future<List<String>> getOpennessPreferences() async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('opennessPreferences')
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['nameRu'] as String? ?? '';
    }).toList();
  }

  Future<List<String>> getPartnerPreferences() async {
    final QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('partnerPreferences').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['nameRu'] as String? ?? '';
    }).toList();
  }

  String _getSkillLevelDescription(double value) {
    if (value >= 0.0 && value <= 10.0) {
      return 'Не умею играть';
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



  Map<String, Color> interestColors = {

    'Пейнтбол': Colors.blue,
    'Сноубординг': Colors.red,
    'Бильярд': Colors.green,
    // Добавьте другие интересы и соответствующие цвета
  };



  // Функция для вычисления возраста
  int calculateAge(DateTime birthDate) {
    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _editProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;

      Map<String, dynamic> userProfileData = {
        'uid': uid,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        // 'games_interests': _selectedGameInterests.join(', '),
        // 'skill_levels': _skillLevels,
        // 'location': _locationController.text,
        // 'availability': _availabilityController.text,
        // 'meeting_preferences': _selectedMeetingPreferences,
        // 'communication_preferences': _selectedCommunicationPreferences,
        // 'bio': _bioController.text,
        // 'partner_preferences': _selectedPartnerPreferences,
        'gender': _genderController.text,
        'age': _ageController.text,
        // 'photos': _photosController.text.split(','),
        // 'activity': _selectedActivityPreferences,
        // 'family_status': _selectedFamilyStatus,
        // 'openness_controller': _selectedOpennessPreferences,
        'birthday': _birthdayController.text,
      };


      try {
        await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(uid)
            .update(userProfileData);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('first_name', _firstNameController.text);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen(userId: uid)),
        );
      } catch (e) {
        print('Ошибка при сохранении профиля: $e');
      }
    } else {
      print('Пользователь не аутентифицирован');
    }
  }


  void _editInterests() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;

      Map<String, dynamic> userProfileData = {
        'uid': uid,
        'games_interests': _selectedGameInterests.join(', '),
      };


      try {
        await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(uid)
            .update(userProfileData);

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => ProfileScreen(userId: uid)),
        // );
      } catch (e) {
        print('Ошибка при сохранении профиля: $e');
      }
    } else {
      print('Пользователь не аутентифицирован');
    }
  }


  void _editSkills() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;

      Map<String, dynamic> userProfileData = {
        'uid': uid,
        'skill_levels': _skillLevels,
      };


      try {
        await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(uid)
            .update(userProfileData);

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => ProfileScreen(userId: uid)),
        // );
      } catch (e) {
        print('Ошибка при сохранении профиля: $e');
      }
    } else {
      print('Пользователь не аутентифицирован');
    }
  }

  void _removeLastInterest() {
    setState(() {
      if (_selectedGameInterests.isNotEmpty) {
        print(_selectedGameInterests);
        final removedInterest = _selectedGameInterests.removeLast();
        _skillLevels.remove(removedInterest);
      }else{
        print('');
        print(_selectedGameInterests);
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Здесь задайте количество ваших вкладок
      child: Scaffold(
        appBar: AppBar(
          title: Text('Изменение профиля'),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(40), // Здесь можно настроить высоту вкладок
            child: TabBar(
              isScrollable: true, // Разрешить прокручивание вкладок
              tabs: [
                Tab(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text('Основная информация'),
                  ),
                ),
                Tab(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text('Список спортивных интересов'),
                  ),
                ),
                Tab(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text('Спортивные навыки'),
                  ),
                ),
                Tab(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text('Дополнительная информация'),
                  ),
                ),
                Tab(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text('Контактная информация'),
                  ),
                ),
                // Добавьте еще вкладки, если необходимо
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Содержимое вкладки 1 (Основная информация)
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyTab1,
                  child: Column(
                    children: <Widget>[
                      // Основная информация
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16.0),
                        padding: const EdgeInsets.all(16.0),
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
                              'Имя и Фамилия',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(labelText: 'Имя'),
                              // Добавьте валидацию, если необходимо
                            ),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(labelText: 'Фамилия'),
                              // Добавьте валидацию, если необходимо
                            ),
                          ],
                        ),
                      ),

                      // Пол
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16.0),
                    padding: const EdgeInsets.all(16.0),
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
                          'Пол',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Используйте RadioListTile для каждого варианта пола
                        RadioListTile(
                          title: Text('Мужской'),
                          value: 'Мужской',
                          groupValue: _genderController.text,
                          onChanged: (value) {
                            setState(() {
                              _genderController.text = value.toString();
                            });
                          },
                        ),
                        RadioListTile(
                          title: Text('Женский'),
                          value: 'Женский',
                          groupValue: _genderController.text,
                          onChanged: (value) {
                            setState(() {
                              _genderController.text = value.toString();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                        margin: const EdgeInsets.symmetric(vertical: 16.0),
                        padding: const EdgeInsets.all(16.0),
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
                            Row(
                              children: <Widget>[
                                Text(
                                  'Укажите дату Вашего рождения',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.info_outline, color: Colors.green),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          content: Text(
                                            'Укажите дату своего рождения, а возраст установится сам :)\n \nПотом если что вы сможете его скрыть в настройках',
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text('Понятно'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            // Ваши другие виджеты здесь

                              InkWell(
                                onTap: () async {
                                  final selectedDate =
                                  await showCupertinoModalPopup<DateTime>(
                                    context: context,
                                    builder: (context) {
                                      DateTime currentDate = DateTime.now();
                                      String initialDateString = _birthdayController.text;
                                      final inputFormat = DateFormat('dd.MM.yyyy'); // Определите формат ввода
                                      DateTime initialDate = inputFormat.parse(initialDateString);
                                      return Container(
                                        color: Colors.white,
                                        height: 200,
                                        child: CupertinoDatePicker(
                                          use24hFormat: true,
                                          backgroundColor: Colors.white,
                                          initialDateTime: initialDate ?? currentDate, // Установите начальную дату
                                          mode: CupertinoDatePickerMode.date,
                                          maximumYear: currentDate.year,
                                          minimumYear: 1900,
                                          onDateTimeChanged: (newDate) {
                                            currentDate = newDate;
                                            final selectedDateString =
                                                "${currentDate.day}.${currentDate.month}.${currentDate.year}";
                                            _birthdayController.text =
                                                selectedDateString;
                                            final age = calculateAge(newDate);
                                            _ageController.text = age.toString();
                                          },
                                        ),
                                      );
                                    },
                                  );
                                  if (selectedDate != null) {
                                    final selectedDateString =
                                        "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}";
                                    _birthdayController.text = selectedDateString;
                                    final age = calculateAge(selectedDate);
                                    _ageController.text = age.toString();
                                  } else {
                                    print('Выбор даты отменен');
                                  }
                                },
                                child: IgnorePointer(
                                  child: TextFormField(
                                    controller: _birthdayController,
                                    decoration: InputDecoration(labelText: 'Дата рождения'),
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: _ageController,
                                decoration: InputDecoration(labelText: 'Возраст'),
                                enabled: false,
                              ),
                            ],
                        ),
                      ),


                      // Кнопка "Сохранить"
                      ElevatedButton(
                        onPressed: () {
                          _editProfile();
                          if (_formKeyTab1.currentState!.validate()) {
                            // Все данные валидны, можно сохранить
                          }
                        },
                        child: Text('Сохранить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Содержимое вкладки 2 (Фотографии)
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyTab2,
                  child: Column(
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16.0),
                        padding: const EdgeInsets.all(16.0),
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
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text('Выберите интересующие виды спорта'),
                                ),
                                SizedBox(width: 10), // Добавьте отступ между текстом и иконкой
                                IconButton(
                                  icon: Icon(
                                    Icons.info_outline,
                                    color: Colors.green, // Здесь вы можете указать цвет иконки
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Информация о выборе видов спорта'),
                                          content: Text('Здесь вы можете выбрать интересующие вас виды спорта.\n\nВыбрав один или несколько интересующих Вас видов спорта,\n'
                                              'в следующем пункте не забудьте пожалуйста указать Ваши навыки владения выбранными видами спорта.'),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text('Хорошо'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            FutureBuilder<List<String>>(
                              future: getGamesInterestsFromFirestore(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Ошибка загрузки');
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return Text('Нет данных об интересах');
                                } else {
                                  final gamesInterests = snapshot.data!;
                                  return Column(
                                    children: <Widget>[
                                      DropdownButtonFormField<String>(
                                        value: _selectedGameInterest,
                                        items: gamesInterests.map((String interest) {
                                          return DropdownMenuItem<String>(
                                            value: interest,
                                            child: Text(interest),
                                          );
                                        }).toList(),
                                        onChanged: (String? value) {
                                          if (value != null && !_selectedGameInterests.contains(value)) {
                                            setState(() {
                                              _selectedGameInterest = value;
                                              _selectedGameInterests.add(value);
                                              _selectedGameInterest = null;
                                            });
                                          }
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Вид спорта',
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            if (_selectedGameInterest != null &&
                                                !_selectedGameInterests.contains(_selectedGameInterest)) {
                                              _selectedGameInterests.add(_selectedGameInterest!);
                                              _skillLevels[_selectedGameInterest!] = 0.0;
                                              _selectedGameInterest = null;
                                            }
                                          });
                                        },
                                        child: Text(_selectedGameInterests.isEmpty
                                            ? 'Добавить'
                                            : 'Добавить еще один вид спорта'),
                                      ),
                                      Text(
                                        'Выбранные виды спорта:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Wrap(
                                        spacing: 8.0,
                                        children: _selectedGameInterests.map((interest) {
                                          if (!interestColors.containsKey(interest)) {
                                            interestColors[interest] = _generateRandomColor();
                                          }
                                          Color color = interestColors[interest] ?? Colors.grey;
                                          return Chip(
                                            backgroundColor: color,
                                            label: Text(interest),
                                            onDeleted: () {
                                              setState(() {
                                                _selectedGameInterests.remove(interest);
                                                print('Интерес $interest удален. _selectedGameInterests: $_selectedGameInterests');
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                      SizedBox(height: 30.0),
                                      ElevatedButton(
                                        onPressed: () {

                                          if (_formKeyTab2.currentState!.validate()) {
                                            _editInterests();

                                            Future.delayed(Duration(seconds: 2), ()
                                            {
                                              DefaultTabController.of(context).animateTo(2);
                                            });

                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text('Сохранено!'),
                                                  content: Text('Изменения были сохранены,переходим на следующую вкладку!.'),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: Text('Понятно'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          primary: Colors.red, // Задайте цвет кнопки
                                          onPrimary: Colors.white, // Задайте цвет текста на кнопке
                                          minimumSize: Size(200, 80), // Задайте минимальный размер кнопки (ширина x высота)
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10), // Задайте скругление углов кнопки
                                          ),
                                        ),
                                        child: Text('Сохранить и перейти к следующей вкладке'),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),


                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),


            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyTab3,
                  child: Column(
                    children: <Widget>[

                      for (String sportInterest in _selectedGameInterests)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Уровень навыков для $sportInterest: ${_getSkillLevelDescription(_skillLevels[sportInterest.trim()] ?? 0.0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: _skillLevels[sportInterest.trim()] ?? 0.0,
                              onChanged: (newValue) {
                                print('Уровень навыков для $sportInterest: ${_getSkillLevelDescription(_skillLevels[sportInterest.trim()] ?? 0.0)}');
                                print('test $_skillLevels[sportInterest.trim()]');
                                setState(() {
                                  _skillLevels[sportInterest.trim()] = newValue;
                                });
                              },
                              min: 0.0,
                              max: 100.0,
                              divisions: 100,
                              label: _skillLevels[sportInterest.trim()]?.toString() ?? '0.0',
                            ),
                          ],
                        ),
                      ElevatedButton(
                        onPressed: () {

                          if (_formKeyTab3.currentState!.validate()) {
                            _editSkills();
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Применено'),
                                  content: Text('Изменения были применены.\nP.S простите за убогий интерфейс,пока только так умею :('),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Закрыть'),
                                    ),
                                  ],
                                );
                              },
                            );

                          }
                        },
                        child: Text('Сохранить изменения'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyTab4,
                  child: Column(
                    children: <Widget>[
                  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'SOON',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                        ],
                      ),
                        ],
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyTab5,
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Durov call me -> +998(99)8888931',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}