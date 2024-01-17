import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../MapScreens/MapsPage.dart';
import 'EventConversation.dart';

class EventsScreen extends StatefulWidget {
  final List<dynamic> eventsList;
  final String markerName;
  final String uid;
  final String firstName;
  final DateTime? selectedDay;

  const EventsScreen({Key? key, required this.eventsList, required this.markerName,required this.uid,required this.firstName,required this.selectedDay}) : super(key: key);

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Stream<QuerySnapshot> eventsStream;

  @override
  void initState() {
    super.initState();
    // Создайте Stream для слежения за изменениями в коллекции events
    eventsStream = FirebaseFirestore.instance.collection('events').snapshots();

    print('eventsTstream $eventsStream');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Доступные ивенты'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: eventsStream,
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Ошибка: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            // Достаньте документы из снепшота
            List<DocumentSnapshot> documents = snapshot.data!.docs;

            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (BuildContext context, int index) {
                final event = documents[index].data() as Map<String, dynamic>;
                final eventsList = (event['events'] as List<dynamic>?) ?? [];

                // Возвращаем виджет EventCard для каждого события
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: eventsList.map<Widget>((event) {
                    final type = event['type'];
                    final eventName = event['eventName'];
                    final dateEvent = event['dateEvent'];
                    final startTimeEvent = event['startTimeEvent'];
                    final isRegistered = event['isRegistered'];
                    final organizer = event['organizer'];
                    final organizerUid = event['uid'];
                    // final eventName = event['eventName'];
                    final eventId = event['eventId'];

                    // Обработка участников события
                    // List<dynamic> participantsData = (event['participants'] as List<dynamic>?) ?? [];
                    // List<Map<String, String>> participants = participantsData.map((participant) {
                    //   Map<String, dynamic> participantData = participant as Map<String, dynamic>;
                    //
                    //   // Извлекаем uid и firstName из данных участника
                    //   final String uid = participantData['uid'] as String;
                    //   final String firstName = participantData['firstName'] as String;
                    //
                    //   return {'uid': uid, 'firstName': firstName};
                    // }).toList();

                    List<dynamic> participantsData = (event['participants'] as List<dynamic>?) ?? [];
                    List<Map<String, String>> participants = participantsData.map((participant) {
                      if (participant is Map<String, String>) {
                        return participant;
                      } else {
                        // Здесь вы можете предположить что-то другое, например, если у вас есть
                        // другие требования к типам данных.
                        Map<String, dynamic> participantData = participant as Map<String, dynamic>;
                        final String uid = participantData['uid'] as String;
                        final String firstName = participantData['firstName'] as String;
                        return {'uid': uid, 'firstName': firstName};
                      }
                    }).toList();
                    final isRegistered12 = isRegistered1(context, event);

                    print('SELECTED DAYYY');

                    if (widget.selectedDay != null) {
                      print(DateFormat('dd.MM.yyyy').format(widget.selectedDay!));
                    }

                    if (DateFormat('dd.MM.yyyy').format(widget.selectedDay!) != null && dateEvent != DateFormat('dd.MM.yyyy').format(widget.selectedDay!)) {
                      return Container(); // Пустой контейнер, если дата не соответствует
                    }

                    return EventCard(
                      startTimeEvent: startTimeEvent,
                      participants: participants,
                      organizer: organizer,
                      isRegistered: isRegistered,
                      isJoined: isRegistered12,
                      firstName: widget.firstName,
                      uid: widget.uid,
                      markerName: eventName,
                      dateEvent: dateEvent,
                      eventId: eventId,
                      organizerUid: organizerUid,
                      eventName: eventName,
                      participantMap: participants,
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

bool isRegistered1(BuildContext context, Map<String, dynamic> eventData) {
  final participants = eventData['participants'] as List<dynamic>?;

  if (participants != null) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return participants.any((participant) => participant['uid'] == userId);
  } else {
    // Обработка случая, когда 'participants' равно null
    return false;
  }
}


class EventCard extends StatelessWidget {
  final String startTimeEvent;
  final List<dynamic> participants;
  final String organizer;
  final bool isJoined;
  final bool isRegistered;
  final String firstName;
  final String uid;
  final String markerName;
  final String dateEvent;
  final String eventId;
  final String organizerUid;
  final String eventName;
  final List<Map<String, String>> participantMap;


  const EventCard({Key? key, required this.startTimeEvent, required this.participants, required this.organizer,
    required this.isJoined,required this.isRegistered,required this.firstName,
    required this.uid,required this.markerName,required this.dateEvent,required this.eventId,required this.organizerUid,
    required this.eventName, required this.participantMap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(16.0),
          margin: EdgeInsets.symmetric(vertical: 8.0),
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(13.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            color: isRegistered ? Colors.green : Colors.blue, // Условие для цвета
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Время начала
              Container(
                margin: EdgeInsets.only(left: 10),
                alignment: Alignment.centerLeft,
                width: 75,
                child: Text(
                  startTimeEvent,
                  style: TextStyle(
                    fontSize: 50.0,
                  ),
                ),
              ),

            ],
          ),
        ),
        Positioned(
          bottom: 10, // Расположение участников сверху
          left: 5,
          child: Container(
            child: Text(
              'Участники: ${participants.map((participant) => participant['firstName']).join(', ')}',
            ),
          ),
        ),
        Positioned(
          top: 10, // Расположение организатора сверху
          right: 5,
          child: Text(
            'Организатор: $organizer',
            style: TextStyle(
              fontSize: 17,
            ),
          ),
        ),


        Row(
          children: [
            // Кнопка "Открыть чат" (видна только если пользователь уже присоединен)


            // Кнопка "Посмотреть участников" (видна всегда)
            IconButton(
              icon: Icon(Icons.people),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ParticipantsDialog(
                    participants: participantMap,
                    organizerUid: organizerUid,
                    currentUserUid: userId,
                  ),
                );
              },
            ),
            // Кнопка "Присоединиться" (видна только если пользователь еще не присоединен)
            if (!isJoined)
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  String currentUserId = userId;
                  print('Текущий пользователь нажал на Присоединиться: $currentUserId');

                  // Проверьте, есть ли текущий пользователь уже в списке участников
                  bool isUserAlreadyParticipant = false;
                  for (var participant in participants) {
                    if (participant['uid'] == currentUserId) {
                      isUserAlreadyParticipant = true;
                      break;
                    }
                  }

                  // Если текущего пользователя еще нет в списке, добавьте его
                  if (!isUserAlreadyParticipant) {
                    String? firstNameParticipant = firstName;
                    // Создайте нового участника
                    Map<String, String> newParticipant = {'uid': currentUserId, 'firstName': firstNameParticipant as String};

                    // Добавьте нового участника в список
                    participants.add(newParticipant);

                    // Вызовите функцию для присоединения к мероприятию
                    joinEvent(markerName, dateEvent, startTimeEvent, currentUserId, firstNameParticipant, organizerUid,eventId);
                  }
                },
              ),
          ],
        ),

        if (isJoined)
          Positioned(
            bottom: 25, // Поднимите кнопку чуть ниже относительно верхнего края
            left: 5,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FutureBuilder<String>(
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Ошибка: ${snapshot.error}');
                      } else {
                        String unreadMessageCount = snapshot.data ?? "";
                        return ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => EventConversation(
                                eventId: eventId,
                                eventName: eventName,
                              ),
                            );
                          },
                          icon: Icon(Icons.chat),
                          label: Text('Открыть чат$unreadMessageCount'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            textStyle: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                    },
                    future: null,
                  ),
                ],
              ),
            ),
          ),

        // Кнопка "Посмотреть участников"
        // Positioned(
        //   bottom: 75, // Поднимите кнопку еще ниже
        //   left: 5,
        //   child: SingleChildScrollView(
        //     scrollDirection: Axis.horizontal,
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         ElevatedButton.icon(
        //           onPressed: () {
        //             showDialog(
        //               context: context,
        //               builder: (context) => ParticipantsDialog(
        //                 participants: participantMap,
        //                 organizerUid: organizerUid,
        //                 currentUserUid: userId,
        //               ),
        //             );
        //           },
        //           icon: Icon(Icons.group),
        //           label: Text('Посмотреть участников'),
        //           style: ElevatedButton.styleFrom(
        //             backgroundColor: Colors.indigo,
        //             textStyle: const TextStyle(
        //               fontSize: 15.0,
        //               fontWeight: FontWeight.bold,
        //             ),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Future<void> joinEvent(String markerName, String dateEvent, String startTimeEvent, String currentUserId, String firstNameParticipant,String organizerUid,String eventId) async {
    try {

      print('markerName');
      print(markerName);
      DocumentReference docRef = FirebaseFirestore.instance.collection('events').doc(markerName);

      // Получите данные документа
      DocumentSnapshot docSnapshot = await docRef.get();
      Map<String, dynamic>? eventData = docSnapshot.data() as Map<String, dynamic>?;

      if (eventData != null) {
        // Извлеките поле "events" (которое является массивом)
        List<dynamic> events = eventData['events'] as List<dynamic>;

        print(events);
        // Найдите событие по dateEvent и startTimeEvent
        for (int i = 0; i < events.length; i++) {
          Map<String, dynamic> event = events[i] as Map<String, dynamic>;
          if (event['dateEvent'] == dateEvent && event['startTimeEvent'] == startTimeEvent && event['uid'] == organizerUid) {
            // Найдено событие, добавьте нового участника
            List<dynamic> participants = event['participants'] as List<dynamic>;
            participants.add({'uid': currentUserId, 'firstName': firstNameParticipant});

            // Обновите только конкретное событие
            events[i]['participants'] = participants;
            await docRef.update({'events': events});
            sendMessage('присоединился к мероприятию',eventId);
            print('Участник успешно добавлен к событию');
            return;
          }
        }
      }

      print('Событие не найдено');
    } catch (error) {
      print('Произошла ошибка: $error');
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
      await messagesCollection.doc(eventId).collection('messages').add({
        'message': '$senderName $messageText',
        'senderId': '12345',
        'senderName': 'system',
        'isChanged':false,
        'docId':'System docId',
        'messageId':'System message',
        'timestamp': FieldValue.serverTimestamp(),
      });

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
}
