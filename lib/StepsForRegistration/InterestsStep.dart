import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../References/References.dart';

class InterestsStep extends StatefulWidget {


  @override
  _InterestsStepState createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  String _selectedGameInterest = '';
  List<String> _selectedGameInterests = [];
  Map<String, double> _skillLevels = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                padding: const EdgeInsets.all(16.0),
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
                          final gamesInterests = snapshot.data!.toSet().toList();
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
                                    _selectedGameInterest = ''; // Используйте пустую строку, а не null
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
                                      _selectedGameInterest = '';
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
    );
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
}