import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'ProfileScreen.dart';

void main() {
  runApp(MaterialApp(home: RegistrationProfilePage()));
}

class RegistrationProfilePage extends StatefulWidget {
  @override
  _RegistrationProfilePageState createState() => _RegistrationProfilePageState();
}

class _RegistrationProfilePageState extends State<RegistrationProfilePage> {
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

      FirebaseFirestore.instance.collection('users').doc(uid).get().then((userDoc) {
        if (userDoc.exists) {
          Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

          if (userData != null) {
            setState(() {
              _firstNameController.text = userData['first_name'] ?? '';
              _lastNameController.text = userData['last_name'] ?? '';
            });
          }
        }
      });
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
    final QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('communicationPreferences').get();
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
    final QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('activityPreferences').get();
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
    final QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('opennessPreferences').get();
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
        'activity':_selectedActivityPreferences,
        'family_status':_selectedFamilyStatus,
        'openness_controller':_selectedOpennessPreferences,
        'birthday':_birthdayController.text,
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Регистрация профиля'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  setState(() {
                    if (_currentStep < 21) {
                      _currentStep += 1;
                    } else {
                      _currentStep = 0;
                    }
                  });
                },
                onStepCancel: () {
                  print(_currentStep);
                  setState(() {
                    if (_currentStep > 0) {
                      _currentStep -= 1;
                    }else if(_currentStep == 0){
                      _currentStep = 0;
                    }else {
                      _currentStep = 21;
                    }
                  });
                },
                steps: <Step>[
                  Step(
                    title: Text('Имя и Фамилия'),
                    content: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(labelText: 'Имя'),
                          readOnly: true,
                        ),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(labelText: 'Фамилия'),
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: Text('Выберите пол'),
                    content: Column(
                      children: <Widget>[
                        RadioListTile<String>(
                          title: Text('Мужской'),
                          value: 'Мужской',
                          groupValue: _genderController.text,
                          onChanged: (String? value) {
                            setState(() {
                              _genderController.text = value ?? '';
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: Text('Женский'),
                          value: 'Женский',
                          groupValue: _genderController.text,
                          onChanged: (String? value) {
                            setState(() {
                              _genderController.text = value ?? '';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: Text('Укажите ваш возраст'),
                    content: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Возраст'),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Пожалуйста, введите свой возраст';
                            }
                            // Добавьте дополнительные проверки по вашему усмотрению
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: Text('Укажите дату вашего рождения'),
                    content: Column(
                      children: <Widget>[
                        DateTimePicker(
                          type: DateTimePickerType.date,
                          dateMask: 'dd.MM.yyyy',
                          controller: _birthdayController,
                          initialDate: DateTime.now(), // Используйте DateTime.now() без toString()
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          icon: Icon(Icons.event),
                          dateLabelText: 'Дата рождения',
                          onChanged: (val) => setState(() {}),
                        ),

                      ],
                    ),
                  ),
                  Step(
                    title: Text('Укажите ваш город'),
                    content: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(labelText: 'Город'),
                          validator: (value) {
                            if (value == null) {
                              return 'Пожалуйста, введите свой город';
                            }
                            // Добавьте дополнительные проверки по вашему усмотрению
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: Text('Интересующий вид спорта'),
                    content: Column(
                      children: <Widget>[
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
                                    decoration: InputDecoration(labelText: 'Вид спорта'),
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
                                  Text('Выбранные интересы: ${_selectedGameInterests.join(", ")}'),
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
                  Step(
                    title: Text('Уровень навыков'),
                    content: Column(
                      children: <Widget>[
                        for (String sportInterest in _selectedGameInterests)
                          Column(
                            children: <Widget>[
                              Text('Уровень навыков для $sportInterest: ${_getSkillLevelDescription(_skillLevels[sportInterest] ?? 0.0)}'),
                              Slider(
                                value: _skillLevels[sportInterest] ?? 0.0,
                                onChanged: (newValue) {
                                  setState(() {
                                    _skillLevels[sportInterest] = newValue;
                                  });
                                },
                                min: 0.0,
                                max: 100.0,
                                divisions: 100,
                                label: _skillLevels[sportInterest]?.toStringAsFixed(2) ?? '0.0',
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Step(
                    title: Text('Предпочтительный стиль общения'),
                    content: Column(
                      children: <Widget>[
                        FutureBuilder<List<String>>(
                          future: getCommunicationPreferences(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Ошибка загрузки');
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Text('Нет данных об стилях общения');
                            } else {
                              final communicationPreferences = snapshot.data!;
                              return Column(
                                children: <Widget>[
                                  Column(
                                    children: communicationPreferences.map((String preference) {
                                      return RadioListTile<String>(
                                        title: Text(preference),
                                        value: preference,
                                        groupValue: _selectedCommunicationPreferences,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedCommunicationPreferences = value;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: Text('Предпочтительное время активности'),
                    content: Column(
                      children: <Widget>[
                        FutureBuilder<List<String>>(
                          future: getMeetingPreferences(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Ошибка загрузки');
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Text('Нет данных о времени активности');
                            } else {
                              final meetingPreferences = snapshot.data!;
                              return Column(
                                children: <Widget>[
                                  Column(
                                    children: meetingPreferences.map((String preference) {
                                      return RadioListTile<String>(
                                        title: Text(preference),
                                        value: preference,
                                        groupValue: _selectedMeetingPreferences,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedMeetingPreferences = value;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  Step(
                    title: Text('Ваш уровень активности'),
                    content: Column(
                      children: <Widget>[
                        FutureBuilder<List<String>>(
                          future: getActivityPreferences(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Ошибка загрузки');
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Text('Нет данных об уровне активности');
                            } else {
                              final activityPreferences = snapshot.data!;
                              return Column(
                                children: <Widget>[
                                  Column(
                                    children: activityPreferences.map((String preference) {
                                      return RadioListTile<String>(
                                        title: Text(preference),
                                        value: preference,
                                        groupValue: _selectedActivityPreferences,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedActivityPreferences = value;

                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  Step(
                    title: Text('Семейное положение'),
                    content: Column(
                      children: <Widget>[
                        FutureBuilder<List<String>>(
                          future: getFamilyStatus(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Ошибка загрузки');
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Text('Нет данных о семейном положении');
                            } else {
                              final familyStatusPreferences = snapshot.data!;
                              return Column(
                                children: <Widget>[
                                  Column(
                                    children: familyStatusPreferences.map((String preference) {
                                      return RadioListTile<String>(
                                        title: Text(preference),
                                        value: preference,
                                        groupValue: _selectedFamilyStatus,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedFamilyStatus = value;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  Step(
                    title: Text('Уровень открытости к новым знакомствам'),
                    content: Column(
                      children: <Widget>[
                        FutureBuilder<List<String>>(
                          future: getOpennessPreferences(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Ошибка загрузки');
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Text('Нет данных об уровне открытости');
                            } else {
                              final opennessPreferences = snapshot.data!;
                              return Column(
                                children: <Widget>[
                                  Column(
                                    children: opennessPreferences.map((String preference) {
                                      return RadioListTile<String>(
                                        title: Text(preference),
                                        value: preference,
                                        groupValue: _selectedOpennessPreferences,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedOpennessPreferences = value;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  Step(
                    title: Text('Укажите предпочтительную группу общения'),
                    content: Column(
                      children: <Widget>[
                        FutureBuilder<List<String>>(
                          future: getPartnerPreferences(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Ошибка загрузки');
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Text('Нет данных о группе общения');
                            } else {
                              final partnerPreferences = snapshot.data!;
                              return Column(
                                children: <Widget>[
                                  Column(
                                    children: partnerPreferences.map((String preference) {
                                      return RadioListTile<String>(
                                        title: Text(preference),
                                        value: preference,
                                        groupValue: _selectedPartnerPreferences,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedPartnerPreferences = value;

                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  Step(
                    title: Text('О себе'),
                    content: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _bioController,
                          decoration: InputDecoration(labelText: 'О себе'),
                          maxLines: null, // Разрешает многострочный ввод текста
                        ),
                      ],
                    ),
                  ),




                  // Добавьте другие этапы регистрации сюда
                  // ...
                  Step(
                    title: Text('Завершение'),
                    content: Column(
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: _registerProfile,
                          child: Text('Завершить регистрацию'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
