import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../References/References.dart';
import 'ProfileScreen.dart';


void main() {
  runApp(const MaterialApp(home: RegistrationProfilePage()));
}

class RegistrationProfilePage extends StatefulWidget {
  const RegistrationProfilePage({super.key});

  @override
  _RegistrationProfilePageState createState() =>
      _RegistrationProfilePageState();
}

class _RegistrationProfilePageState extends State<RegistrationProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  List<String> _selectedGameInterests = [];
  String? _selectedGameInterest;
  Map<String, double> _skillLevels = {};
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .then((userDoc) {
        if (userDoc.exists) {
          Map<String, dynamic>? userData =
              userDoc.data();

          if (userData != null) {
            setState(() {
              _firstNameController.text = userData['firstName'] ?? '';
              _lastNameController.text = userData['lastName'] ?? '';
            });
          }
        }
      });
    }
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

  Color _generateRandomColor() {
    final Random random = Random();
    final int red = random.nextInt(256);
    final int green = random.nextInt(256);
    final int blue = random.nextInt(256);
    return Color.fromARGB(255, red, green, blue);
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
    BuildContext currentContext = context;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;
      Map<String, dynamic> userProfileData = {
        'uid': uid,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'gamesInterests': _selectedGameInterests.join(', '),
        'skillLevels': _skillLevels,
        'location': _locationController.text,
        'age': _ageController.text,
        'birthday':_birthdayController.text,
        'gender':_genderController.text,
      };

      try {
        await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(uid)
            .set(userProfileData);
        Navigator.pushReplacement(
          currentContext,
          MaterialPageRoute(builder: (context) => ProfileScreen(userId: uid)),
        );
      } catch (e) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Ошибка при сохранении профиля: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text('Пользователь не аутентифицирован'),
          duration: Duration(seconds: 3),
        ),
      );
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
        title: const Text('Создание профиля'),
      ),
      body: ListView (
            children: <Widget>[
              Stepper(
                currentStep: _currentStep,
                onStepTapped: (step) {
                  setState(() {
                    _currentStep = step;
                  });
                },
                onStepContinue: () {
                  setState(() {
                    if (_currentStep < 20) {
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
                    } else if (_currentStep == 0) {
                      _currentStep = 0;
                    } else {
                      _currentStep = 20;
                    }
                  });
                },
                steps: <Step>[
                  Step(
                    title: const Text('Имя и Фамилия'),
                    content: SingleChildScrollView(
                      child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'Имя'),
                          readOnly: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, укажите ваше имя';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Фамилия'),
                          readOnly: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, укажите вашу фамилия';
                            }
                            return null;
                          },
                        ),
                      ],
                      ),
                    ),
                  ),
                  Step(
                    title: const Text('Укажите Ваш пол', style: TextStyle(fontSize: 18)),
                    content: SingleChildScrollView(
                      child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: Radio<String>(
                            value: 'Мужской',
                            groupValue: _genderController.text,
                            onChanged: (String? value) {
                              setState(() {
                                _genderController.text = value ?? '';
                              });
                            },
                          ),
                          title: const Text('Мужской'),
                          trailing: Icon(Icons.male,
                              color: _genderController.text == 'Мужской'
                                  ? Colors.blue
                                  : Colors.grey),
                          onTap: () {
                            setState(() {
                              _genderController.text = 'Мужской';
                            });
                          },
                        ),
                        ListTile(
                          leading: Radio<String>(
                            value: 'Женский',
                            groupValue: _genderController.text,
                            onChanged: (String? value) {
                              setState(() {
                                _genderController.text = value ?? '';
                              });
                            },
                          ),
                          title: const Text('Женский'),
                          trailing: Icon(Icons.female,
                              color: _genderController.text == 'Женский'
                                  ? Colors.pink
                                  : Colors.grey),
                          onTap: () {
                            setState(() {
                              _genderController.text = 'Женский';
                            });
                          },
                        ),
                      ],
                      ),
                    ),
                  ),
                  Step(
                    title: Row(
                      children: <Widget>[
                        const Text('Укажите дату Вашего рождения'),
                        IconButton(
                          icon: const Icon(Icons.info_outline,color: Colors.green),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: const Text('Укажите дату своего рождения,а возраст установится сам :)\n \nПотом если что вы сможете его скрыть в настройках'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Понятно'),
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
                    content: SingleChildScrollView(
                      child: Column(
                      children: <Widget>[
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
                                      final day = currentDate.day.toString().padLeft(2, '0');
                                      final month = currentDate.month.toString().padLeft(2, '0');
                                      final year = currentDate.year.toString();
                                      final selectedDateString = '$day.$month.$year';
                                      _birthdayController.text = selectedDateString;
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
                            }
                          },
                          child: IgnorePointer(
                            child: TextFormField(
                              controller: _birthdayController,
                              decoration: const InputDecoration(labelText: 'Дата рождения'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Пожалуйста, укажите дата своего рождения';
                                }
                                // Добавьте дополнительные проверки по вашему усмотрению
                                return null;
                              },
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(labelText: 'Возраст'),
                          enabled: false,
                        ),
                      ],
                    ),
                    ),
                  ),
                  Step(
                    title: const Text('Укажите Ваш город'),
                    content: SingleChildScrollView(
                      child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: 'Город'),
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
                  ),
                  Step(
                    title: Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text('Выберите интересующие виды спорта'),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            // ...
                          },
                        ),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                      children: <Widget>[
                        FutureBuilder<List<String>>(
                          future: getGamesInterestsFromFirestore(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
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
                                      labelText: 'Вид спорта',
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        if (_selectedGameInterest != null &&
                                            !_selectedGameInterests
                                                .contains(_selectedGameInterest)) {
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
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                  SizedBox(height: 30.0),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                      ),
                    ),
                  ),
                  Step(
                    title: const Text('Укажите уровень владения выбранных видов спорта'),
                    content: SingleChildScrollView(
                      child: Column(
                      children: <Widget>[
                        for (String sportInterest in _selectedGameInterests)
                          Column(
                            children: <Widget>[
                              Text(
                                  'Уровень навыков для $sportInterest: ${_getSkillLevelDescription(_skillLevels[sportInterest] ?? 0.0)}'),
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
                                label: _skillLevels[sportInterest]
                                        ?.toStringAsFixed(2) ??
                                    '0.0',
                              ),
                            ],
                          ),
                      ],
                    ),
                    ),
                  ),
                  /*Step(
                    title: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text('Предпочтительный стиль общения'),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: Text('Будьте честны,укажите ваш тип общения.Это поможет другим людям понять Вас'),
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
                    content: Column(
                      children: <Widget>[
                        FutureBuilder<List<String>>(
                          future: getCommunicationPreferences(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Ошибка загрузки');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Text('Нет данных об стилях общения');
                            } else {
                              final communicationPreferences = snapshot.data!;
                              return Column(
                                children: <Widget>[
                                  Column(
                                    children: communicationPreferences
                                        .map((String preference) {
                                      return RadioListTile<String>(
                                        title: Text(preference),
                                        value: preference,
                                        groupValue:
                                            _selectedCommunicationPreferences,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedCommunicationPreferences =
                                                value;
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
                   */
                  Step(
                    title: const Text('Завершение'),
                    content: SingleChildScrollView(
                      child: Column(
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            if (_genderController.text.isEmpty||_genderController.text == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Вы не указали свой пол.'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }else if (_birthdayController.text.isEmpty||_birthdayController.text == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Вы не указали дату своего рождения'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }else if (_locationController.text.isEmpty||_locationController.text == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Вы указали город Вашего проживания'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }else if (_selectedGameInterests.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Вам необходимо указать хотя бы один интересующий Вас вид спорта.'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                            else{
                              _registerProfile();
                            }
                          },
                          child: const Text('Завершить регистрацию'),
                        ),
                      ],
                    ),
                  ),
                  ),
                ],
              ),
            ],
          ),
        );
  }
}
