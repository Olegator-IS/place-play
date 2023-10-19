import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCreationForm extends StatefulWidget {
  final String organizer;
  final String activityType;
  final String userId;
  final String type;
  final String address;
  final String name;

  EventCreationForm({required this.organizer, required this.activityType,required this.userId,required this.type,required this.address,required this.name});

  @override
  _EventCreationFormState createState() => _EventCreationFormState();
}

class _EventCreationFormState extends State<EventCreationForm> {
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  bool isBooked = false;

  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventTimeBeginController = TextEditingController();
  final TextEditingController _eventTimeEndController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    startTime = TimeOfDay.now();
    endTime = TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Создание ивента'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Организатор: ${widget.organizer}',
              style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold)),
            Text('Тип активности: ${widget.activityType}',
                style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold)),
            Text('Идентификатор пользователя: ${widget.userId}',
                style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold)),

            GestureDetector(
              onTap: () async {
                final currentDate = DateTime.now();
                final selectedDateString = DateFormat('dd.MM.yyyy').format(currentDate);
                _eventDateController.text = selectedDateString;

                DateTime? newDate = await showCupertinoModalPopup<DateTime?>(
                  context: context,
                  builder: (context) {
                    final initialDate = selectedDate ?? currentDate;
                    return Container(
                      color: Colors.white,
                      height: 200,
                      child: CupertinoDatePicker(
                        use24hFormat: true,
                        backgroundColor: Colors.white,
                        initialDateTime: initialDate,
                        mode: CupertinoDatePickerMode.date,
                        maximumYear: currentDate.year,
                        minimumYear: 1900,
                        onDateTimeChanged: (newDate) {
                          final selectedDateString =
                              "${currentDate.day}.${currentDate.month}.${currentDate.year}";
                          _eventDateController.text =
                              selectedDateString;
                          // Remove the setState from here
                        },
                      ),
                    );
                  },
                );

                if (selectedDate != null) {
                  setState(() {
                    final selectedDateString =
                        "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}";
                    _eventDateController.text = selectedDateString;
                  });
                  // final selectedDateString =
                  // DateFormat('dd.MM.yyyy').format(newDate);
                  // _eventDateController.text = selectedDateString;
                } else {
                  print('Выбор даты отменен');
                }
              },

              child: AbsorbPointer(
                child: TextFormField(
                  controller: _eventDateController,
                  decoration: InputDecoration(labelText: 'Дата ивента'),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Время начала'),
                    controller: TextEditingController(
                      text: '${startTime.hour}:${startTime.minute}',
                    ),
                    readOnly: true,
                    onTap: () {
                      showTimePicker(
                        context: context,
                        initialTime: startTime,
                      ).then((time) {
                        if (time != null) {
                          setState(() {
                            startTime = time;
                            // Обновите текст в поле после выбора времени
                            _eventTimeBeginController.text = '${time.hour}:${time.minute}';
                          });
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Время окончания'),
                    controller: TextEditingController(
                      text: '${endTime.hour}:${endTime.minute}',
                    ),
                    readOnly: true,
                    onTap: () {
                      showTimePicker(
                        context: context,
                        initialTime: endTime,
                      ).then((time) {
                        if (time != null) {
                          setState(() {
                            endTime = time;
                            // Обновите текст в поле после выбора времени
                            _eventTimeEndController.text = '${time.hour}:${time.minute}';
                          });
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              title: Text('Заведение уже забронировано'),
              value: isBooked,
              onChanged: (value) {
                setState(() {
                  isBooked = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_eventDateController.text.isEmpty) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Ошибка'),
                    content: Text('Пожалуйста, выберите дату ивента.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
              return; // Остановка выполнения кода
            }

            DateTime startDateTime = DateTime(startTime.hour, startTime.minute);
            DateTime endDateTime = DateTime(endTime.hour, endTime.minute);

            // // Проверка, чтобы время окончания было больше времени начала
            // if (endDateTime.isBefore(startDateTime)) {
            //   // Если время окончания меньше времени начала, проверьте, является ли endDateTime "следующим днем"
            //   if (endDateTime.isBefore(startDateTime.add(Duration(hours: 24)))) {
            //     // Время окончания на следующий день, ничего не делаем
            //   } else {
            //     showDialog(
            //       context: context,
            //       builder: (context) {
            //         return AlertDialog(
            //           title: Text('Ошибка'),
            //           content: Text('Время окончания должно быть больше времени начала.'),
            //           actions: [
            //             TextButton(
            //               onPressed: () {
            //                 Navigator.of(context).pop();
            //               },
            //               child: Text('OK'),
            //             ),
            //           ],
            //         );
            //       },
            //     );
            //     return; // Остановка выполнения кода
            //   }
            // }

            if (!isBooked) {
              // Проверка, был ли выбран чекбокс "Заведение уже забронировано"
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Подтвердите бронирование'),
                      content: Text('Пожалуйста свяжитесь по контактным номерам и забронируйте место!'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  });
              return; // Остановка выполнения кода
            }

            Navigator.of(context).pop(); // Закрыть диалог
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Поздравляю', style: TextStyle(color: Colors.red)), // Заголовок красного цвета
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.sentiment_very_satisfied, // Иконка "удовлетворенности" смайлика
                        size: 80,
                        color: Colors.orange, // Оранжевая иконка
                      ),
                      Text(
                        'Ваша игра в ${widget.activityType} состоится в ${startTime.hour}:${startTime.minute}\n'
                         'По адресу:\n${widget.address}\nB заведении:\n${widget.name}\nПросим прибыть на месте чуточку раньше.\nУдачной игры!', // Текст "Вы лох"
                        style: TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('OK', style: TextStyle(color: Colors.blue)), // Кнопка OK с синим текстом
                    ),
                  ],
                );
              },
            );

          },

          child: Text('Создать ивент'),
        ),

        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Закрыть диалог без сохранения
          },
          child: Text('Отмена'),
        ),
      ],
    );
  }
}
