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
  final String phoneNumber;
  final String firstName;

  const EventCreationForm({super.key, required this.organizer, required this.activityType,required this.userId,required this.type,required this.address,required this.name,required this.phoneNumber,required this.firstName});

  @override
  _EventCreationFormState createState() => _EventCreationFormState();
}

class EventData {
  final String firstName;
  final String dateEvent;
  final String startTimeEvent;
  final String organizer;
  final String type;
  final String address;
  final String uid;
  final List<Map<String, String>> participants;


  EventData({
  required this.firstName,
  required this.dateEvent,
  required this.startTimeEvent,
  required this.organizer,
    required this.type,
    required this.address,
    required this.uid,
    required this.participants,
});

Map<String, dynamic> toJson() {
  return {
    'firstName': firstName,
    'dateEvent': dateEvent,
    'startTimeEvent': startTimeEvent,
    'organizer': organizer,
    'type': type,
    'uid': uid,
    'participants':participants,
  };
}
}

class _EventCreationFormState extends State<EventCreationForm> {
  List<EventData> events = []; // Создайте список событий

  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  bool isBooked = false;
  DocumentSnapshot? userDataSnapshot;

  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventTimeBeginController = TextEditingController();
  final TextEditingController _eventTimeEndController = TextEditingController();
  final TextEditingController _participants = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    startTime = TimeOfDay.now();
    endTime = TimeOfDay.now();
    _refreshData();
  }
  Future<void> _loadUserData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('events').doc().get();
      if (snapshot.exists) {
        setState(() {
          userDataSnapshot = snapshot;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении профиля: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    await _loadUserData();



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
      title: const Text('Создание ивента'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Название ивента:\nИгра в ${widget.type}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20.0),
            Text('Организатор: ${widget.organizer}',
              style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold)),
            const SizedBox(height: 20.0),
            Text('Тип активности: ${widget.activityType}',
                style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 13.0),
            Text('Идентификатор пользователя: ${widget.userId}',
                style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold)),

            GestureDetector(
              onTap: () async {
                final selectedDate =

                 await showCupertinoModalPopup<DateTime?>(
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
                        minimumDate: currentDate,
                        onDateTimeChanged: (newDate) {
                            currentDate = newDate;
                            final day = currentDate.day.toString().padLeft(2, '0');
                            final month = currentDate.month.toString().padLeft(2, '0');
                            final year = currentDate.year.toString();
                            final selectedDateString = '$day.$month.$year';
                            _eventDateController.text = selectedDateString;
                            // Remove the setState from here

                        },
                      ),
                    );
                  },
                );


              },
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _eventDateController,
                  decoration: const InputDecoration(labelText: 'Дата ивента'),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Время начала ивента'),
                    controller: _eventTimeBeginController,
                    readOnly: true,
                    onTap: () async {
                      DateTime selectedDateTime = await showModalBottomSheet(
                        context: context,
                        builder: (BuildContext builder) {
                          return SizedBox(
                            height: 200,
                            child: CupertinoDatePicker(
                              use24hFormat: true,
                              mode: CupertinoDatePickerMode.time,
                              onDateTimeChanged: (DateTime newDateTime) {
                                String formattedTime = DateFormat.Hm().format(newDateTime);
                                _eventTimeBeginController.text = formattedTime;
                              },
                            ),
                          );
                        },
                      );
                      setState(() {
                          startTime = TimeOfDay.fromDateTime(selectedDateTime);
                        });
                    },
                  ),
                ),
              ],
            ),
            Text('Местоположение: ${widget.address}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text('Заведение уже забронировано'),
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
                    title: const Text('Ошибка'),
                    content: const Text('Пожалуйста, выберите дату ивента.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
              return; // Остановка выполнения кода
            }
            if (_eventTimeBeginController.text.isEmpty) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Ошибка'),
                    content: const Text('Пожалуйста, выберите время начала ивента.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
              return; // Остановка выполнения кода
            }

            if (!isBooked) {
              // Проверка, был ли выбран чекбокс "Заведение уже забронировано"
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Подтвердите бронирование'),
                      content: Text('Пожалуйста свяжитесь по контактным номерам и забронируйте место!\n\nНе забудьте сообщить что вы бронируете через PlaceAndPlay! ;) \n\n${widget.phoneNumber}\n\n${widget.name}'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  });
              return; // Остановка выполнения кода
            }
            // Создайте экземпляр EventData с данными из формы
            EventData newEvent = EventData(
              firstName: widget.name,
              dateEvent: _eventDateController.text,
              startTimeEvent: _eventTimeBeginController.text,
              organizer: widget.organizer,
              type: widget.type,
              address: widget.address,
              uid: widget.userId, participants: [{'uid': widget.userId.toString(), 'firstName': widget.firstName.toString()}],
            );

            // Добавьте новое событие в список
            events.add(newEvent);

            // Преобразуйте список событий в JSON формат
            final eventsJson = events.map((event) => event.toJson()).toList();
            final jsonData = {'events': eventsJson};

            addOrUpdateEvent(newEvent,widget.name);
            // Очистите форму и закройте диалог

            Navigator.of(context).pop(); // Закрыть диалог
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Успешно', style: TextStyle(color: Colors.red, fontSize: 24)), // Заголовок красного цвета
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Ваша игра в ${widget.activityType} состоится!',
                            style: const TextStyle(fontSize: 20),
                          ),
                          Text(
                                '\n${widget.name}\n\n${_eventTimeBeginController.text}\n\n${widget.address}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 30.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '\nПросим прибыть на место чуточку раньше.\n\nУдачной игры!', // Текст поздравления
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _eventDateController.clear();
                            _eventTimeBeginController.clear();
                            _eventTimeEndController.clear();
                          },
                          child: const Text('OK', style: TextStyle(color: Colors.blue, fontSize: 20)), // Кнопка OK с синим текстом
                        ),
                      ],
                    );
                  },
                );

          _refreshData();

            // Дальше вы можете отправить JSON данные на сервер или сохранить их локально
          },
          child: const Text('Создать ивент'),
        ),

        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Закрыть диалог без сохранения
          },
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}
