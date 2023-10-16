import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              final gamesInterestsString = userData['games_interests'];
              final _selectedGameInterests = gamesInterestsString.split(', ');
              final selectedSports = _selectedGameInterests.join(', ');
              print(_selectedGameInterests);
            });
          }
        }
      });
    }else{
      // такого не может быть впринципе чтобы во время редактирования профиля,пользователь не был найден :)
    }
  }

  Future<List<String>> getGamesInterestsFromFirestore() async {
    final QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('listOfSports').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['nameRu'] as String? ?? '';
    }).toList();
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

  void _registerProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;

      Map<String, dynamic> userProfileData = {
        'uid': uid,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'games_interests': _selectedGameInterests.join(', '),
        'skill_levels': _skillLevels,
        'location': _locationController.text,
        // 'availability': _availabilityController.text,
        'meeting_preferences': _selectedMeetingPreferences,
        'communication_preferences': _selectedCommunicationPreferences,
        'bio': _bioController.text,
        'partner_preferences': _selectedPartnerPreferences,
        'gender': _genderController.text,
        'age': _ageController.text,
        'photos': _photosController.text.split(','),
        'activity': _selectedActivityPreferences,
        'family_status': _selectedFamilyStatus,
        'openness_controller': _selectedOpennessPreferences,
        'birthday': _birthdayController.text,
      };


      try {
        await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(uid)
            .set(userProfileData);

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

  void _removeLastInterest() {
    setState(() {
      if (_selectedGameInterests.isNotEmpty) {
        final removedInterest = _selectedGameInterests.removeLast();
        _skillLevels.remove(removedInterest);
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Здесь задайте количество ваших вкладок
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
                                      return Container(
                                        color: Colors.white,
                                        height: 200,
                                        child: CupertinoDatePicker(
                                          use24hFormat: true,
                                          backgroundColor: Colors.white,
                                          initialDateTime: currentDate,
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
                          // Здесь добавьте логику для сохранения изменений в профиле
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
                              items: _selectedGameInterests.map((String interest) {
                                return DropdownMenuItem<String>(
                                  value: interest,
                                  child: Text(interest),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                if (value != null &&
                                    !_selectedGameInterests.contains(value)) {
                                  setState(() {
                                    _selectedGameInterest = value;
                                    _selectedGameInterests.add(value);
                                    _selectedGameInterest = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                  labelText: 'Вид спорта'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  if (_selectedGameInterest != null &&
                                      !_selectedGameInterests.contains(
                                          _selectedGameInterest)) {
                                    _selectedGameInterests.add(_selectedGameInterest!);
                                    _skillLevels[_selectedGameInterest!] =
                                    0.0;
                                    _selectedGameInterest = null;
                                  }
                                });
                              },
                              child: Text(_selectedGameInterests.isEmpty
                                  ? 'Добавить'
                                  : 'Добавить еще один вид спорта'),
                            ),
                            Text(
                                'Выбранные виды спорта: ${_selectedGameInterests.join(", ")}'),
                            ElevatedButton(
                              onPressed: _removeLastInterest,
                              child: Text('Удалить последний вид спорта'),
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

            // Добавьте другие вкладки здесь, если необходимо
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyTab3,
                  child: Column(
                    children: <Widget>[
                      // Добавьте поля для редактирования фотографий
                      // ...
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
                      // Добавьте поля для редактирования фотографий
                      // ...
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