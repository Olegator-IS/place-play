import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../ProfileScreens/ViewProfileScreen.dart';
import 'EventConversation.dart';

class EventsList extends StatefulWidget {
  final String userId;

  const EventsList({Key? key, required this.userId}) : super(key: key);

  @override
  _EventsListState createState() => _EventsListState();
}

class _EventsListState extends State<EventsList> {
  List<Map<String, dynamic>> eventsList = [];


  int currentIndex = 0; // 0 for organizer, 1 for participant
  bool canEditEvent = false;
  String selectedFilter = 'all';
  CollectionReference<Map<String, dynamic>> events =
  FirebaseFirestore.instance.collection('events');

  List<Map<String, dynamic>> fetchOrganizerEvents(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    List<Map<String, dynamic>> organizerEvents = [];

    snapshot.docs.forEach((doc) {
      List<Map<String, dynamic>> eventsList =
      List<Map<String, dynamic>>.from(doc.data()!['events']);
      organizerEvents.addAll(
        eventsList.where((event) => event['uid'] == widget.userId),
      );
    });

    return organizerEvents;
  }

  Future<String> getUnreadMessageCount(Map<String, dynamic> eventList, String currentUserId) async {
    String unreadMessageCount = "";
    int unreadMessage = 0;
    List<String> test = [];
    for (var eventEntry in eventList.entries) {
      String eventId = eventEntry.key;
      if(eventId.contains('eventId')){
        test.add(eventEntry.value);


      }
    }
    for (int i=0;i<test.length;i++) {
      print(test[i]);
      CollectionReference<Map<String, dynamic>> eventMessagesCollection =
      FirebaseFirestore.instance.collection('eventMessages').doc(test[i]).collection('messages');
      print('Сколько сообщений $eventMessagesCollection');
      // Получаем все сообщения для текущего события
      QuerySnapshot<Map<String, dynamic>> messagesSnapshot =
      await eventMessagesCollection.get();

      print('TTTTTTTTTTT124$messagesSnapshot');

      for (QueryDocumentSnapshot<Map<String, dynamic>> messageDoc in messagesSnapshot.docs) {
        print('1241241241');
        Map<String, dynamic> message = messageDoc.data();
        List<dynamic>? readBy = message['readBy'] as List<dynamic>?;
        print(readBy);

        // Если readBy не содержит currentUserId, увеличиваем счетчик непрочитанных сообщений
        if (readBy == null || !readBy.contains(currentUserId)) {
          unreadMessage++;
          unreadMessageCount = '(+$unreadMessage)';
          print(unreadMessage);
          if(unreadMessage == 0){
            unreadMessageCount = "";
          }
        }
      }
    }


    return unreadMessageCount;
  }





  void updateEventsList(Map<String, dynamic> updatedEvent, int currentIndex) {
    setState(() {
      // Обновление данных на основе нового события и индекса
      // Например, если у вас есть список eventsList, то можно сделать следующим образом:
      eventsList[currentIndex] = updatedEvent;
    });
  }

  List<Map<String, dynamic>> fetchParticipantEvents(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    List<Map<String, dynamic>> participantEvents = [];

    snapshot.docs.forEach((doc) {
      List<Map<String, dynamic>> eventsList =
      List<Map<String, dynamic>>.from(doc.data()!['events']);
      participantEvents.addAll(
        eventsList.where((event) => event['participants']
            .any((participant) => participant['uid'] == widget.userId)),
      );
    });

    return participantEvents;
  }


  bool isEventOnDate(Map<String, dynamic> event, DateTime date) {
    DateTime eventDate = parseEventDate(event['dateEvent']);
    return eventDate.year == date.year &&
        eventDate.month == date.month &&
        eventDate.day == date.day;
  }

  void showCenteredNotification(BuildContext context, String message) {
    OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 25.0,
        width: MediaQuery.of(context).size.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            alignment: Alignment.center,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  message,
                  style: TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold,color: Colors.red),

                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  DateTime parseEventDate(String dateString) {
    // Пример: "17.11.2023"
    List<String> parts = dateString.split('.');

    if (parts.length == 3) {
      int day = int.tryParse(parts[0]) ?? 1;
      int month = int.tryParse(parts[1]) ?? 1;
      int year = int.tryParse(parts[2]) ?? 2000;
      print(DateTime(year,month,day));
      return DateTime(year, month, day);
    } else {
      // Если формат даты некорректен, вернем текущую дату
      return DateTime.now();
    }
  }


  void _viewProfile(dynamic participant) {
    String uid = participant['uid']; // Получите uid участника
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProfileScreen(userId: uid),
      ),
    );
  }

  void _addToFriends(dynamic participant) {
    print('Добавлен в друзья: ${participant['firstName']}');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мои события'),
      ),
      body: Column(
        children: [
        ToggleSwitch(
        minWidth: 120.0,  // Увеличьте ширину по вашему усмотрению
        initialLabelIndex: currentIndex,
        activeBgColor: [Colors.green, Colors.blue],
        activeFgColor: Colors.white,
        inactiveBgColor: Colors.grey,
        inactiveFgColor: Colors.white,
        labels: ['Организатор', 'Участник'],
        onToggle: (index) {
          setState(() {
            currentIndex = index ?? 0;
          });
        },
      ),
          DropdownButton<String>(
            value: selectedFilter,
            onChanged: (String? newValue) {
              setState(() {
                selectedFilter = newValue!;
              });
            },
            items: [
              DropdownMenuItem<String>(
                value: 'all',
                child: Text('Все события'),
              ),
              DropdownMenuItem<String>(
                value: 'today',
                child: Text('События на сегодня'),
              ),
              DropdownMenuItem<String>(
                value: 'future',
                child: Text('Будущие события'),
              ),
              DropdownMenuItem<String>(
                value: 'past',
                child: Text('Прошедшие события'),
              ),
              // Add more filter options as needed
            ],
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: events.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Произошла ошибка: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('У вас нет организованных событий');
                } else {
                  List<Map<String, dynamic>> eventsList =
                  currentIndex == 0
                      ? fetchOrganizerEvents(snapshot.data!)
                      : fetchParticipantEvents(snapshot.data!);
                  canEditEvent = currentIndex == 0;
                  switch (selectedFilter) {
                    case 'today':
                      eventsList = eventsList
                          .where((event) {
                        DateTime eventDate = parseEventDate(event['dateEvent']);
                        DateTime today = DateTime.now();
                        today = DateTime(today.year, today.month, today.day);

                        print('Event Date: $eventDate, Today: $today');

                        return eventDate.year == today.year &&
                            eventDate.month == today.month &&
                            eventDate.day == today.day;
                      })
                          .toList();
                      print('Filtered Events: $eventsList');
                      break;

                    case 'future':
                      eventsList = eventsList
                          .where((event) {
                        DateTime eventDate = parseEventDate(event['dateEvent']);
                        DateTime today = DateTime.now();
                        today = DateTime(today.year, today.month, today.day);

                        print('Event Date: $eventDate, Today: $today');

                        return eventDate.isAfter(today);
                      })
                          .toList();
                      print('Filtered Events: $eventsList');
                      break;



                    case 'past':
                      eventsList = eventsList
                          .where((event) {
                        DateTime eventDate = parseEventDate(event['dateEvent']);
                        DateTime today = DateTime.now();
                        today = DateTime(today.year, today.month, today.day);

                        print('Event Date: $eventDate, Today: $today');

                        return eventDate.isBefore(today);
                      })
                          .toList();
                      print('Filtered Events: $eventsList');
                      break;
                  // Добавьте другие варианты для других фильтров при необходимости
                    default:
                      break;
                  }

                  return Expanded(
                      child: ListView.separated(
                      itemCount: eventsList.length,
                      separatorBuilder: (BuildContext context, int index) {
                    return SizedBox(height: 8); // Пространство между контейнерами
                  },
                itemBuilder: (BuildContext context, int index) {
                Map<String, dynamic> event = eventsList[index];
                bool isOrganizer = event['uid'] == widget.userId;
                bool isRegistered = event['isRegistered'] ?? false;
                return Container(
                        color: event['isRegistered'] == true ? Colors.green : Colors.red,
                       child: ListTile(
                        title: Text(
                          event['eventName'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['dateEvent'] ?? ''),
                            SizedBox(height: 10.0),
                            Text(

                                  'Вы ${currentIndex == 0 ? 'организатор' : 'участник'}',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                              Text(
                                event['isRegistered'] == true
                                    ? 'Мероприятие подтверждено, \nначало ожидается в  ${event['startTimeEvent']}'
                                    : 'МЕРОПРИЯТИЕ НЕ ПОДТВЕРЖДЕНО! ОЖИДАЕТСЯ РЕГИСТРАЦИЯ',
                                style: TextStyle(
                                  color: event['isRegistered'] == true ? Colors.white : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // Ваш код для открытия обсуждения
                                    // Например, Navigator.push(...);
                                    print('Открыть обсуждение11');
                                    print(event['eventId']);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => EventConversation(eventId: event['eventId'],eventName: event['eventName']),
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    Icons.chat, // Иконка обсуждения
                                    size: 50.0, // Размер иконки
                                  ),
                                ),
                                SizedBox(width: 8), // Расстояние между иконкой и текстом
                                FutureBuilder<String>(
                                  future: getUnreadMessageCount(event, widget.userId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return CircularProgressIndicator(); // Или другой индикатор загрузки
                                    } else if (snapshot.hasError) {
                                      return Text('Ошибка: ${snapshot.error}');
                                    } else {
                                      String unreadMessageCount = snapshot.data ?? "";
                                      return GestureDetector(
                                        onTap: () {
                                          // Ваш код для открытия обсуждения
                                          // Например, Navigator.push(...);
                                          print('Открыть обсуждение22');
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => EventConversation(eventId: event['eventId'],eventName: event['eventName']),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Перейти в чат $unreadMessageCount',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            // Ваши стили для текста
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Отменить мероприятие'),
                              enabled: canEditEvent,
                            ),
                            PopupMenuItem<String>(
                              value: 'confirm',
                              child: Text('Подтвердить мероприятие'),
                              enabled: canEditEvent,
                            ),
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Редактировать мероприятие'),
                              enabled: canEditEvent,
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'delete') {
                              try {
                                String eventId = event['eventId'];
                                String uid = event['uid'];
                                String eventName = event['eventName'];

                                // Создание обновленного списка участников без удаленного
                                DocumentReference<Map<String, dynamic>> docReference =
                                FirebaseFirestore.instance.collection('events').doc(eventName);

                                // Получение текущих данных
                                DocumentSnapshot<Map<String, dynamic>> docSnapshot = await docReference.get();

                                // Проверка, есть ли данные
                                if (docSnapshot.exists) {
                                  // Получение текущих данных
                                  Map<String, dynamic> data = docSnapshot.data()!;

                                  // Получение текущего массива событий
                                  List<dynamic> events = List.from(data['events']);

                                  // Найдите индекс события по eventId и uid
                                  int indexOfEvent = events.indexWhere(
                                          (event) => event['eventId'] == eventId && event['uid'] == uid);

                                  // Если событие найдено, удаляем его из массива "events"
                                  if (indexOfEvent != -1) {
                                    events.removeAt(indexOfEvent);

                                    // Обновление документа с обновленным массивом "events"
                                    await docReference.update({'events': events});
                                    showCenteredNotification(context, 'Ваш ивент успешно отменён!');
                                  }
                                }
                              } catch (e) {
                                print('Ошибка при отмене ивента: $e');
                                showCenteredNotification(context, 'Ошибка при отмене ивента');
                              }
                            } else if (value == 'confirm') {
                              try {
                                String eventId = event['eventId'];
                                String eventName = event['eventName'];

                                // Создание обновленного списка участников без удаленного
                                DocumentSnapshot<Map<String, dynamic>> docSnapshot =
                                await FirebaseFirestore.instance.collection('events').doc(eventName).get();

                                // Проверка, есть ли данные
                                if (docSnapshot.exists) {
                                  // Получение текущих данных
                                  Map<String, dynamic> data = docSnapshot.data()!;

                                  // Получение текущего массива событий
                                  List<dynamic> events = List.from(data['events']);

                                  // Найдите событие по eventId
                                  int indexOfEvent = events.indexWhere((event) => event['eventId'] == eventId);

                                  // Если событие найдено, обновите его "participants"
                                  if (indexOfEvent != -1) {
                                    events[indexOfEvent]['isRegistered'] = true;

                                    // Обновление документа с обновленным массивом "events"
                                    await FirebaseFirestore.instance.collection('events').doc(eventName).update({'events': events});
                                  }
                                }
                                showCenteredNotification(context, 'Регистрация подтверждена успешно');
                                String organizator = event['uid'];
                                sendMessage('Организатор $organizator подтвердил регистрацию',eventId);


                                // Create a copy of the event with the modified isRegistered property
                                Map<String, dynamic> updatedEvent = Map.from(event);
                                updatedEvent['isRegistered'] = true;

                                // Update the UI by setting the state with the updated event
                                setState(() {
                                  event = updatedEvent;
                                });
                              } catch (e) {
                                print('Ошибка при подтверждении регистрации: $e');
                                showCenteredNotification(context, 'Ошибка при подтверждении регистрации');
                              }
                              // Обработка подтверждения мероприятия
                            }
                            // else if (value == 'edit') {
                            //   // Обработка редактирования мероприятия
                            // }
                          },
                        ),
                        onTap: () {
                          // Navigate to the details screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetails(
                                event: event,
                                currentUserId: widget.userId,
                                isOrganizer: currentIndex,
                                isRegistered: event['isRegistered'],
                              ),
                            ),
                          );
                        },
                       ),
                );
                },
                      ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
void sendMessage(String messageText,String eventId) async {
  User? user = FirebaseAuth.instance.currentUser;
  String? sender = user?.uid;
  CollectionReference messagesCollection =
  FirebaseFirestore.instance.collection('eventMessages');

  if (messageText.isNotEmpty) {
    String senderName = await getSenderFirstName(sender!) ?? 'Аноним';

    // Добавление сообщения в чат
    DocumentReference<Map<String, dynamic>> newMessageRef =
    await messagesCollection.doc(eventId).collection('messages').add({
      'message': '$senderName $messageText',
      'senderId': '12345',
      'senderName': 'system',
      'docId':eventId,
      'isChanged':false,
      'messageId':'',
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [user?.uid],
    });

    String messageId = newMessageRef.id;


    // Обновляем messageId в добавленном сообщении
    await newMessageRef.update({'messageId': messageId});


  }
}

Future<String?> getSenderFirstName(String senderId) async {
  try {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
    await _firestore.collection('users').doc(senderId).get();

    if (userSnapshot.exists) {
      return userSnapshot.data()?['firstName'];
    }
  } catch (e) {
    print('Ошибка при получении данных пользователя: $e');
  }

  return null;
}


class EventDetails extends StatefulWidget  {

  final Map<String, dynamic> event;
  final String currentUserId;
  final int isOrganizer;
  final bool isRegistered;


  const EventDetails(
      {Key? key, required this.event,required this.currentUserId,required this.isOrganizer,required this.isRegistered})
      : super(key: key);




  @override
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {

  List<Map<String, dynamic>> fetchOrganizerEvents(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    List<Map<String, dynamic>> organizerEvents = [];

    snapshot.docs.forEach((doc) {
      List<Map<String, dynamic>> eventsList =
      List<Map<String, dynamic>>.from(doc.data()!['events']);
      organizerEvents.addAll(
        eventsList.where((event) => event['uid'] == currentUserId),
      );
    });

    return organizerEvents;
  }
  Map<String, dynamic> get event => widget.event;
  String get currentUserId => widget.currentUserId;
  int get isOrganizer => widget.isOrganizer;
  bool get isRegistered => widget.isRegistered;




  void confirmRegistration(Map<String, dynamic> event) async {
    try {
      String eventId = event['eventId'];
      String eventName = event['eventName'];

      // Создание обновленного списка участников без удаленного
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
      await FirebaseFirestore.instance.collection('events').doc(eventName).get();

      // Проверка, есть ли данные
      if (docSnapshot.exists) {
        // Получение текущих данных
        Map<String, dynamic> data = docSnapshot.data()!;

        // Получение текущего массива событий
        List<dynamic> events = List.from(data['events']);

        // Найдите событие по eventId
        int indexOfEvent = events.indexWhere((event) => event['eventId'] == eventId);

        // Если событие найдено, обновите его "participants"
        if (indexOfEvent != -1) {
          events[indexOfEvent]['isRegistered'] = true;

          // Обновление документа с обновленным массивом "events"
          await FirebaseFirestore.instance.collection('events').doc(eventName).update({'events': events});
        }
      }
      showCenteredNotification(context, 'Регистрация подтверждена успешно');
      String organizator = event['uid'];
      sendMessage('Организатор $organizator подтвердил регистрацию',eventId);

      // Create a copy of the event with the modified isRegistered property
      Map<String, dynamic> updatedEvent = Map.from(event);
      updatedEvent['isRegistered'] = true;

      // Update the UI by setting the state with the updated event
      setState(() {
        event = updatedEvent;
      });
    } catch (e) {
      print('Ошибка при подтверждении регистрации: $e');
      showCenteredNotification(context, 'Ошибка при подтверждении регистрации');
    }
  }




  void cancelEvent(Map<String, dynamic> event) async {

    print('Начало отмены');
    try {
      String eventId = event['eventId'];
      String uid = event['uid'];
      String eventName = event['eventName'];

      // Создание обновленного списка участников без удаленного
      DocumentReference<Map<String, dynamic>> docReference =
      FirebaseFirestore.instance.collection('events').doc(eventName);

      // Получение текущих данных
      DocumentSnapshot<Map<String, dynamic>> docSnapshot = await docReference.get();

      // Проверка, есть ли данные
      if (docSnapshot.exists) {
        // Получение текущих данных
        Map<String, dynamic> data = docSnapshot.data()!;

        // Получение текущего массива событий
        List<dynamic> events = List.from(data['events']);

        // Найдите индекс события по eventId и uid
        int indexOfEvent = events.indexWhere(
                (event) => event['eventId'] == eventId && event['uid'] == uid);

        // Если событие найдено, удаляем его из массива "events"
        if (indexOfEvent != -1) {
          events.removeAt(indexOfEvent);

          // Обновление документа с обновленным массивом "events"
          await docReference.update({'events': events});
          showCenteredNotification(context, 'Ваш ивент успешно отменён!');
          setState(() {
            event['eventName'] = "Ивент отменен!";
          });
        }
      }
    } catch (e) {
      print('Ошибка при отмене ивента: $e');
      showCenteredNotification(context, 'Ошибка при отмене ивента');
    }


  }






  @override
  Widget build(BuildContext context) {
    // Use the data from the event to build the event details UI
    return Scaffold(
      appBar: AppBar(
        title: Text('Детали события'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 5.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Название: ${event['eventName']}',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Тип мероприятия: ${event['type']}',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Дата: ${event['dateEvent']}',
                  style:  TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Участники:',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Container(
                  height: event['participants'].length * 60.0,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.all(0.0),
                    itemCount: event['participants'].length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onLongPress: () {
                          _showContextMenu(
                            context,
                            event['participants'][index],
                            event['uid'],
                            currentUserId,
                            isOrganizer,
                            event,
                            isRegistered,
                          );
                        },
                        child: ListTile(
                          title: Text(
                            'Имя участника: ${event['participants'][index]['firstName']}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16.0),

                Column(
                  children: [
                    Visibility(
                      visible: isOrganizer == 0 && event['isRegistered'] == false,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            confirmRegistration(event);

                            setState(() {
                              event['isRegistered'] = true;
                            });

                          },
                          child: Text('Подтвердить регистрацию'),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: isOrganizer == 0 && event['isRegistered'] == false,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Логика для изменения ивента
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.blue, // Цвет кнопки
                          ),
                          child: Text('Изменить ивент'),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: isOrganizer == 0,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5.0),
                        child: ElevatedButton(
                          onPressed: () {
                            cancelEvent(event);
                            setState(() {
                              event['isRegistered'] = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.blue, // Цвет кнопки
                          ),
                          child: Text('Отменить ивент'),
                        ),
                      ),
                    ),
                  ],
                ),





              ],

            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, dynamic participant, String currentUserId,dynamic event,int currentIndex,dynamic eventList, bool isRegistered) {
    print(isRegistered);
    print(eventList);
    print('isOrganizer$isOrganizer');
    // Показать контекстное меню
    print('test $event');
    print(participant['uid']);
    print(currentUserId);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {


        List<Widget> menuItems = [
          ListTile(
            title: Text('Выбранный участник - ${participant['firstName']}'),
          ),
        ];

        if (participant['uid'] != currentUserId) {
          // Добавьте "Посмотреть профиль" только если UID участника не совпадает с UID текущего пользователя
          menuItems.add(
            ListTile(
              title: Text('Посмотреть профиль'),
              onTap: () {
                _viewProfile(context, participant);
              },
            ),
          );

          if (isOrganizer == 0) {
            // Если выбран организатор, добавьте дополнительные параметры
            menuItems.addAll([
              ListTile(
                title: Text('Удалить участника из события'),
                onTap: () {
                  _removeParticipant(context,participant,eventList);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Назначить организатором'),
                onTap: () {
                  // _assignOrganizer(participant);
                  Navigator.pop(context);
                },
              ),
            ]);
          }
        }else{
          menuItems.addAll([
            ListTile(
              title: Text('Это организатор.\nОн может удалять/назначать других пользователей организатором'),
            ),
            ListTile(
              title: Text('Посмотреть профиль'),
              onTap: () {
                _viewProfile(context, participant);
              },
            ),
          ]);
        }

        // Добавьте остальные пункты меню
        menuItems.addAll([
          // ... other menu items ...
        ]);

        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: menuItems,
          ),
        );
      },
    );
  }

  void _viewProfile(BuildContext context, dynamic participant) {
    String uid = participant['uid'];
    print(uid);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProfileScreen(userId: uid),
      ),
    );
  }

  void _removeParticipant(BuildContext context,dynamic participant, Map<String, dynamic> event) async {

    String participantUid = participant['uid'];
    String eventId = event['eventId'];
    String eventName = event['eventName'];

    // Создание обновленного списка участников без удаленного
    List<dynamic> updatedParticipants = List.from(event['participants']);
    updatedParticipants.removeWhere((p) => p['uid'] == participantUid);

    DocumentSnapshot<Map<String, dynamic>> docSnapshot = await FirebaseFirestore.instance.collection('events')
        .doc(eventName)
        .get();

    // Проверка, есть ли данные
    if (docSnapshot.exists) {
      // Получение текущих данных
      Map<String, dynamic> data = docSnapshot.data()!;

      // Получение текущего массива событий
      List<dynamic> events = List.from(data['events']);

      // Найдите событие по eventId
      int indexOfEvent = events.indexWhere((event) => event['eventId'] == eventId);

      // Если событие найдено, обновите его "participants"
      if (indexOfEvent != -1) {
        events[indexOfEvent]['participants'] = updatedParticipants;

        print('updatedParticipants $updatedParticipants');

        // Обновление документа с обновленным массивом "events"
        await FirebaseFirestore.instance.collection('events')
            .doc(eventName)
            .update({'events': events});






      }

    }


    showCenteredNotification(context, '${participant['firstName']} удален из списка участников');
    setState(() {
      event['participants'] = updatedParticipants;
    });
  }





  void showCenteredNotification(BuildContext context, String message) {
    OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 25.0,
        width: MediaQuery.of(context).size.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            alignment: Alignment.center,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  message,
                  style: TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold,color: Colors.red),

                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}


