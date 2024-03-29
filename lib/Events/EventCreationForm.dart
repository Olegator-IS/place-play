import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_functions/cloud_functions.dart';


class EventCreationForm extends StatefulWidget {
  final String organizer;
  final String activityType;
  final String userId;
  final String type;
  final String typeEn;
  final String address;
  final String name;
  final String phoneNumber;
  final String firstName;

  const EventCreationForm({super.key, required this.organizer, required this.activityType,required this.userId,required this.type,required this.typeEn,required this.address,required this.name,required this.phoneNumber,required this.firstName});

  @override
  _EventCreationFormState createState() => _EventCreationFormState();
}

class EventData {
  final String eventId;
  final String firstName;
  final String dateEvent;
  final String startTimeEvent;
  final String organizer;
  final String type;
  final String typeEn;
  final String address;
  final String uid;
  final List<Map<String, String>> participants;


  EventData({
    required this.eventId,
  required this.firstName,
  required this.dateEvent,
  required this.startTimeEvent,
  required this.organizer,
    required this.type,
    required this.typeEn,
    required this.address,
    required this.uid,
    required this.participants,
});



Map<String, dynamic> toJson() {
  return {
    'eventId': eventId,
    'eventName': firstName,
    'dateEvent': dateEvent,
    'startTimeEvent': startTimeEvent,
    'organizer': organizer,
    'type': type,
    'type':typeEn,
    'uid': uid,
    'participants':participants,
    'isRegistered':false,
  };
}
}


class EventDataWithOut {
  final String eventId;
  final String firstName;
  final String dateEvent;
  final String startTimeEvent;
  final String organizer;
  final String type;
  final String typeEn;
  final String address;
  final String uid;
  final List<Map<String, String>> participants;


  EventDataWithOut({
    required this.eventId,
    required this.firstName,
    required this.dateEvent,
    required this.startTimeEvent,
    required this.organizer,
    required this.type,
    required this.typeEn,
    required this.address,
    required this.uid,
    required this.participants,
  });



  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventName': firstName,
      'dateEvent': dateEvent,
      'startTimeEvent': startTimeEvent,
      'organizer': organizer,
      'type': type,
      'typeEn': typeEn,
      'uid': uid,
      'isRegistered':false,
      'participants':[],
    };
  }
}

class _EventCreationFormState extends State<EventCreationForm> {
  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  // FlutterLocalNotificationsPlugin();
  List<EventData> events = [];
  List<EventDataWithOut> eventsWithOut = [];// Создайте список событий
  late String eventId;
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  bool isBooked = false;
  DocumentSnapshot? userDataSnapshot;

  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventTimeBeginController = TextEditingController();
  final TextEditingController _eventTimeEndController = TextEditingController();
  final TextEditingController _participants = TextEditingController();
  String? token;

  @override
  void initState() {
    super.initState();
    // initializeNotifications();
    selectedDate = DateTime.now();
    startTime = TimeOfDay.now();
    endTime = TimeOfDay.now();

    // Запрос токена устройства

    _refreshData();
  }
  Future<void> _loadUserData() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      token = await messaging.getToken();
      print('FCM Device Token: $token');
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
  Future<List<dynamic>?> getUsersId(String eventType) async {
    print('ПОЛУЧЕНННННННЫЙ UID EVENT TYPES $eventType');
    try {
      // Получение документа пользователя из коллекции subscriptions
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('subscriptions').doc(eventType).get();

      print('snapshot prowel');
      print('eventType $eventType');
      // Извлечение массива userId из документа пользователя
      List<dynamic>? usersId = (userDoc.data() as Map<String, dynamic>?)?['usersId'];
      print('USERS ID -> $usersId');


      return usersId;
    } catch (e) {
      print('Error getting usersId: $e');
      return null;
    }
  }

  Future<void> sendNotificationToSubscribers(List<dynamic> userIds, String title, String body,String uid) async {
    for (String userId in userIds) {
      try {
        print('BEGIN');
        // Получаем документ пользователя из коллекции 'users'
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

        // Извлекаем токен пользователя
        String? userToken = (userDoc.data() as Map<String, dynamic>?)?['fcmToken'];


        print('userToken $userToken');
        // Проверяем, есть ли токен
        if (userToken != null) {
          String swipe = "audio/swipe.mp3";
          // Отправляем уведомление с использованием полученного токена
          String typeEn = widget.typeEn;
          print('TYPE EN $typeEn');
          if(typeEn.toUpperCase().contains('BILLIARDS')){
            swipe = "audio/billiards.mp3";
          }else if(typeEn.toUpperCase().contains('TENNIS')){
            swipe = "audio/tennis.mp3";
          }

            await sendNotification(userToken, title, body, userId, swipe);

        } else {
          print('Токен пользователя не найден для пользователя с UID $userId');
        }
      } catch (e) {
        print('Ошибка при отправке уведомления пользователю с UID $userId: $e');
      }
    }
  }

  Future<bool> doesUserDocExist(String eventType) async {
    try {
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('subscriptions').doc(eventType);
      DocumentSnapshot userDocSnapshot = await userDocRef.get();
      return userDocSnapshot.exists;
    } catch (e) {
      print('Error checking if user eventType exists: $e');
      return false;
    }
  }

  Future<void> sendPrepare(String token) async {
    List<dynamic>? currentEventTypes = [];
    List<dynamic>? usersId = [];
    String uid = widget.userId;
    String typeEn = widget.typeEn;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmToken': token,
    });

    bool doesExist = await doesUserDocExist(typeEn);
    if (doesExist) {
      print('eventType exists.');
      usersId = await getUsersId(typeEn);
      print(usersId);
    }







//// Получаю список подписчиков данного спорта

String place = widget.name.toUpperCase();
    String game = widget.type.toUpperCase();
    sendNotificationToSubscribers(usersId!,'Появился новый ивент $game','Кто-то ищет компанию в $place\n'
        'Чтобы сыграть в $game',uid);



  }


  Future<void> sendNotification(String token, String title, String body, String sender,String sound) async {
    final HttpsCallable sendNotificationCallable =
    FirebaseFunctions.instance.httpsCallable('sendNotification');
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(sender).get();

    String? userToken = (userDoc.data() as Map<String, dynamic>?)?['fcmToken'];    print(token);


    print('NEW TOKEN $userToken');
    // Создаем объект payload
    final payload = {
      'token': userToken,
      'title': title,
      'body': body,
      'sender': 'test',
      'sound':'default'

    };





    HttpsCallable a = FirebaseFunctions.instance.httpsCallable("sendNotification");

    try {
      final x = await a(payload);
      print(x.data);
    } on FirebaseFunctionsException catch (e) {
      // Возможно, здесь можно получить дополнительную информацию из e.details
      print('FirebaseFunctionsException: ${e.message}');
      print('Details: ${e.details}');
    } catch (e) {
      print('Error: $e');
    }

  }

  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print('Пользователь подписан на топик: $topic');
  }









  // Future<void> initializeNotifications() async {
  //   const AndroidInitializationSettings initializationSettingsAndroid =
  //   AndroidInitializationSettings('app_icon');
  //
  //   final InitializationSettings initializationSettings =
  //   InitializationSettings(android: initializationSettingsAndroid);
  //
  //   await flutterLocalNotificationsPlugin.initialize(
  //     initializationSettings,
  //   );
  // }

  // Future<void> showNotification() async {
  //   const AndroidNotificationDetails androidPlatformChannelSpecifics =
  //   AndroidNotificationDetails(
  //     'your_channel_id', // Замените на свой уникальный ID канала
  //     'Your Channel Name',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );

  //   const NotificationDetails platformChannelSpecifics =
  //   NotificationDetails(android: androidPlatformChannelSpecifics);
  //
  //   await flutterLocalNotificationsPlugin.show(
  //     0, // Уникальный ID уведомления
  //     'Уведомление', // Заголовок уведомления
  //     'Ваше событие успешно создано!', // Текст уведомления
  //     platformChannelSpecifics,
  //     payload: 'item x',
  //   );
  // }


  Future<void> _refreshData() async {
    await _loadUserData();



  }

  Future<void> addOrUpdateEvent(EventData event, String name) async {
    final collection = FirebaseFirestore.instance.collection('events');
    final documentName = name; // Имя документа

    final docRef = collection.doc(documentName);
    final docSnapshot = await docRef.get();
    eventId = docRef.id;


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
    // showNotification();
  }

  Future<void> addOrUpdateEventWithOut(EventDataWithOut event, String name) async {
    final collection = FirebaseFirestore.instance.collection('events');
    final documentName = name; // Имя документа

    final docRef = collection.doc(documentName);
    final docSnapshot = await docRef.get();
    eventId = docRef.id;


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
    // showNotification();
  }

  String generateEventId() {
    var uuid = Uuid();
    return uuid.v4(); // Генерация версии 4 UUID
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
            // CheckboxListTile(
            //   title: const Text('Зарегистрироваться как участник тоже?'),
            //   value: isBooked,
            //   onChanged: (value) {
            //     setState(() {
            //       isBooked = value ?? false;
            //     });
            //   },
            // ),
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

            // if (!isBooked) {
            //   // Проверка, был ли выбран чекбокс "Заведение уже забронировано"
            //   showDialog(
            //       context: context,
            //       builder: (context) {
            //         return AlertDialog(
            //           title: const Text('Подтвердите бронирование'),
            //           content: Text('Пожалуйста свяжитесь по контактным номерам и забронируйте место!\n\nНе забудьте сообщить что вы бронируете через PlaceAndPlay! ;) \n\n${widget.phoneNumber}\n\n${widget.name}'),
            //           actions: [
            //             TextButton(
            //               onPressed: () {
            //                 Navigator.of(context).pop();
            //               },
            //               child: const Text('OK'),
            //             ),
            //           ],
            //         );
            //       });
            //   return; // Остановка выполнения кода
            // }
            // Создайте экземпляр EventData с данными из формы

            DateTime now = DateTime.now();
            String formattedDate = DateFormat('yyyyMMdd').format(now);
            String eventName = widget.name; // Замените на фактический способ получения имени мероприятия
            String generatedUUID = generateEventId();
            String eventId = '$eventName-$generatedUUID';

            EventData newEvent = EventData(
              eventId: eventId,
              firstName: widget.name,
              dateEvent: _eventDateController.text,
              startTimeEvent: _eventTimeBeginController.text,
              organizer: widget.organizer,
              type: widget.type,
              typeEn: widget.typeEn,
              address: widget.address,
              uid: widget.userId, participants: [{'uid': widget.userId.toString(), 'firstName': widget.firstName.toString()}],
            );


            EventDataWithOut eventWithoutParticipant = EventDataWithOut(
              eventId: eventId,
              firstName: widget.name,
              dateEvent: _eventDateController.text,
              startTimeEvent: _eventTimeBeginController.text,
              organizer: widget.organizer,
              type: widget.type,
                typeEn: widget.typeEn,
              address: widget.address,
              uid: widget.userId,
                participants: []
            );
            // Добавьте новое событие в список



            // if(isBooked){
            //   events.add(newEvent);
            //   addOrUpdateEvent(newEvent,widget.name);
            // }else{
            //   eventsWithOut.add(eventWithoutParticipant);
            //   addOrUpdateEventWithOut(eventWithoutParticipant,widget.name);
            // }

            events.add(newEvent);
            addOrUpdateEvent(newEvent,widget.name);




            // Преобразуйте список событий в JSON формат
            final eventsJson = events.map((event) => event.toJson()).toList();
            final jsonData = {'events': eventsJson};
            print(jsonData);
            print(widget.typeEn);
            subscribeToTopic(widget.typeEn.toString());
            print('tokennnnnnnnnnnn $token');
            String firstName = widget.firstName;
            print('firstName$firstName');
            String place = widget.name;
            print('place$place');
            String uid = widget.userId;
            print('uid$uid');
            // sendNotification(token!, 'Ура!Кто-то создал ивент', 'Пользователь$firstName Создал событие в $place',uid);
            sendPrepare(token!);



            // Очистите форму и закройте диалог

            Navigator.of(context).pop(); // Закрыть диалог
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Успешно', style: TextStyle(color: Colors.orange, fontSize: 24)), // Заголовок красного цвета
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[

                          Text(
                            'Ожидайте участников или пригласите своих друзей!',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
// Text(
//   '\n${widget.name}\n\n Ориентировочное время мероприятия: \n ${_eventTimeBeginController.text}\n\n${widget.address}',
//   style: const TextStyle(
//     color: Colors.black,
//     fontSize: 30.0,
//     fontWeight: FontWeight.bold,
//   ),
// ),
                          Text(
                            '\nВаша игра в ${widget.activityType}\nне является зарегистрированным мероприятием. \n\n',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Для регистрации выполните следующие шаги: \nОткройте вкладку "События" - Выберите текущее мероприятие - Подтвердите бронирование!',
                            style: TextStyle(
                              fontSize: 21,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
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
