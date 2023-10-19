import 'package:cloud_firestore/cloud_firestore.dart';
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

class EventData {
  final String first_name;
  final String date_event;
  final String start_time_event;
  final String organizer;
  final String type;

  EventData({
  required this.first_name,
  required this.date_event,
  required this.start_time_event,
  required this.organizer,
    required this.type,
});

Map<String, dynamic> toJson() {
  return {
    'first_name': first_name,
    'date_event': date_event,
    'start_time_event': start_time_event,
    'organizer': organizer,
    'type': type
  };
}
}

class _EventCreationFormState extends State<EventCreationForm> {
  List<EventData> events = []; // Создайте список событий

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

  void _showEventCreationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return EventCreationForm(
          organizer: 'Организатор', // Замените на соответствующие значения
          activityType: 'Тип активности',
          userId: 'Идентификатор пользователя',
          type: 'Тип события',
          address: 'Адрес',
          name: 'Название заведения',
        );
      },
    );
  }


  Future<void> addOrUpdateEvent(EventData event, String name) async {
    final collection = FirebaseFirestore.instance.collection('events');
    final documentName = name; // Имя документа

    final docRef = collection.doc(documentName);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // Документ существует, обновляем массив в нем
      await docRef.update({
        'events': FieldValue.arrayUnion([event.toJson()]),
      });
    } else {
      // Документ не существует, создаем новый с массивом
      await docRef.set({
        'events': [event.toJson()],
      });
    }
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
                // Expanded(
                //   child: TextFormField(
                //     decoration: InputDecoration(labelText: 'Время окончания'),
                //     controller: TextEditingController(
                //       text: '${endTime.hour}:${endTime.minute}',
                //     ),
                //     readOnly: true,
                //     onTap: () {
                //       showTimePicker(
                //         context: context,
                //         initialTime: endTime,
                //       ).then((time) {
                //         if (time != null) {
                //           setState(() {
                //             endTime = time;
                //             // Обновите текст в поле после выбора времени
                //             _eventTimeEndController.text = '${time.hour}:${time.minute}';
                //           });
                //         }
                //       });
                //     },
                //   ),
                // ),
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
        // ElevatedButton(
        //   onPressed: () {
        //     if (_eventDateController.text.isEmpty) {
        //       showDialog(
        //         context: context,
        //         builder: (context) {
        //           return AlertDialog(
        //             title: Text('Ошибка'),
        //             content: Text('Пожалуйста, выберите дату ивента.'),
        //             actions: [
        //               TextButton(
        //                 onPressed: () {
        //                   Navigator.of(context).pop();
        //                 },
        //                 child: Text('OK'),
        //               ),
        //             ],
        //           );
        //         },
        //       );
        //       return; // Остановка выполнения кода
        //     }
        //
        //     if (!isBooked) {
        //       // Проверка, был ли выбран чекбокс "Заведение уже забронировано"
        //       showDialog(
        //           context: context,
        //           builder: (context) {
        //             return AlertDialog(
        //               title: Text('Подтвердите бронирование'),
        //               content: Text('Пожалуйста свяжитесь по контактным номерам и забронируйте место!'),
        //               actions: [
        //                 TextButton(
        //                   onPressed: () {
        //                     Navigator.of(context).pop();
        //                   },
        //                   child: Text('OK'),
        //                 ),
        //               ],
        //             );
        //           });
        //       return; // Остановка выполнения кода
        //     }
        //
        //     Navigator.of(context).pop(); // Закрыть диалог
        //     showDialog(
        //       context: context,
        //       builder: (context) {
        //         return AlertDialog(
        //           title: Text('Успешно', style: TextStyle(color: Colors.red, fontSize: 24)), // Заголовок красного цвета
        //           content: Column(
        //             mainAxisSize: MainAxisSize.min,
        //             children: <Widget>[
        //               Text(
        //                 'Ваша игра в ${widget.activityType} состоится в ${startTime.hour}:${startTime.minute}\n'
        //                     'По адресу:\n${widget.address}\nB заведении:\n${widget.name}\nПросим прибыть на месте чуточку раньше.\nУдачной игры!', // Текст поздравления
        //                 style: TextStyle(fontSize: 18),
        //               ),
        //             ],
        //           ),
        //           actions: [
        //             TextButton(
        //               onPressed: () {
        //                 Navigator.of(context).pop();
        //               },
        //               child: Text('OK', style: TextStyle(color: Colors.blue, fontSize: 20)), // Кнопка OK с синим текстом
        //             ),
        //           ],
        //         );
        //       },
        //     );
        //
        //   },
        //
        // ),
        ElevatedButton(
          onPressed: () {
            // Создайте экземпляр EventData с данными из формы
            EventData newEvent = EventData(
              first_name: widget.name,
              date_event: _eventDateController.text,
              start_time_event: '${startTime.hour}:${startTime.minute}',
              organizer: widget.organizer,
              type: widget.type,
            );

            // Добавьте новое событие в список
            events.add(newEvent);

            // Преобразуйте список событий в JSON формат
            final eventsJson = events.map((event) => event.toJson()).toList();
            final jsonData = {'events': eventsJson};

            print(jsonData); // Выведет JSON данные в консоль (для проверки)

            addOrUpdateEvent(newEvent,widget.name);
            // Очистите форму и закройте диалог
            _eventDateController.clear();
            _eventTimeBeginController.clear();
            _eventTimeEndController.clear();
            Navigator.of(context).pop();

            // Дальше вы можете отправить JSON данные на сервер или сохранить их локально
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
