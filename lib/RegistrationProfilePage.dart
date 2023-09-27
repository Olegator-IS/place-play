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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  List<String> _selectedGameInterests = [];
  String? _selectedGameInterest;
  Map<String, double> _skillLevels = {};
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  final TextEditingController _meetingPreferencesController = TextEditingController();
  final TextEditingController _communicationPreferencesController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _partnerPreferencesController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _photosController = TextEditingController();

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
        'availability': _availabilityController.text,
        'meeting_preferences': _meetingPreferencesController.text,
        'communication_preferences': _communicationPreferencesController.text,
        'bio': _bioController.text,
        'partner_preferences': _partnerPreferencesController.text,
        'gender': _genderController.text,
        'age': _ageController.text,
        'photos': _photosController.text.split(','),
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
                    if (_currentStep < 13) {
                      _currentStep += 1;
                    } else {
                      _currentStep = 0;
                    }
                  });
                },
                onStepCancel: () {
                  setState(() {
                    if (_currentStep > 0) {
                      _currentStep -= 1;
                    } else {
                      _currentStep = 13;
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
                                      setState(() {
                                        _selectedGameInterest = value;
                                      });
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