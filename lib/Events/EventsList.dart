import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toggle_switch/toggle_switch.dart';

class EventsList extends StatefulWidget {
  final String userId;

  const EventsList({Key? key, required this.userId}) : super(key: key);

  @override
  _EventsListState createState() => _EventsListState();
}

class _EventsListState extends State<EventsList> {
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

                  return ListView.builder(
                    itemCount: eventsList.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> event = eventsList[index];
                      bool isOrganizer = event['uid'] == widget.userId;
                      bool isRegistered = event['isRegistered'] ?? false;

                      return ListTile(
                        title: Text(event['eventName'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['dateEvent'] ?? ''),
                            SizedBox(height: 4.0),
                            Text(

                                  'Вы ${currentIndex == 0 ? 'организатор' : 'участник'}',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                              Text(
                                event['isRegistered'] == true
                                    ? 'Мероприятие подтверждено, начнется ${event['startTimeEvent']}'
                                    : 'МЕРОПРИЯТИЕ НЕ ПОДТВЕРЖДЕНО! ОЖИДАЕТСЯ РЕГИСТРАЦИЯ',
                                style: TextStyle(
                                  color: event['isRegistered'] == true ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Удалить мероприятие'),
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
                          onSelected: (value) {
                            if (value == 'delete') {
                              // Обработка удаления мероприятия
                            } else if (value == 'confirm') {
                              // Обработка подтверждения мероприятия
                            } else if (value == 'edit') {
                              // Обработка редактирования мероприятия
                            }
                          },
                        ),
                        onTap: () {
                          // Navigate to the details screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetails(event: event),
                            ),
                          );
                        },
                      );


                    },
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

class EventDetails extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetails({Key? key, required this.event}) : super(key: key);

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
          elevation: 5.0,  // Высота тени под боксом
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
                  'Дата: ${event['dateEvent']}',
                  style: TextStyle(fontSize: 16.0),
                ),
                // Добавьте другие виджеты для отображения деталей события
              ],
            ),
          ),
        ),
      ),
    );
  }

}
