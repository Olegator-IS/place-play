import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:placeandplay/Events/EventCreationForm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'EventConversation.dart';
import 'EventsScreen.dart';


class EventsCalendar extends StatefulWidget{

  final String organizer;
  final String activityType;
  final String userId;
  final String type;
  final String typeEn;
  final String address;
  final String name;
  final String phoneNumber;
  final String firstName;
  final String markerName;

  const EventsCalendar({super.key, required this.organizer, required this.activityType,required this.userId,required this.type,required this.typeEn,required this.address,required this.name,required this.phoneNumber,required this.firstName, required this.markerName});

  @override
  _EventsCalendarState createState() => _EventsCalendarState();

}

class _EventsCalendarState extends State<EventsCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DocumentSnapshot? userDataSnapshot;



  @override
  void initState() {
    super.initState();
    // Получаем данные из Firebase
    fetchEventsFromFirebase();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('uid',widget.userId);
    print('попал сюда111111111111111111111111111111111111111111111111111111111111111111111111111111');
    try {
      final snapshot = await FirebaseFirestore.instance.collection('events').doc().get();
      if (snapshot.exists) {
        setState(() {
          userDataSnapshot = snapshot;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке данных123: $e');
    }
  }

  Future<void> fetchEventsFromFirebase() async {
    try {
      // Здесь предполагается, что у вас есть коллекция "events" в Firebase
      // и у каждого документа есть поле "events", которое является массивом
      DocumentSnapshot<Map<String, dynamic>> eventsSnapshot =
      await FirebaseFirestore.instance.collection('events').doc(widget.name).get();

      setState(() {
        // Получаем массив событий из документа
        List<dynamic> eventsArray = eventsSnapshot.data()?['events'] ?? [];

        // Извлекаем даты из массива и добавляем в dateList
        dateList = eventsArray
            .map((event) {
          // Приводим даты к формату 'yyyy-MM-dd'
          DateTime parsedDate = DateFormat('dd.MM.yyyy').parse(event['dateEvent']);
          return DateFormat('yyyy-MM-dd').format(parsedDate);
        })
            .toList();

        print('DATE LIST $dateList');

      });
    } catch (error) {
      print('Ошибка при получении данных из Firebase: $error');
      // Обработайте ошибку, если необходимо
    }
  }
  String cardContent = "";
  List<String> dateList = [];


  @override
  Widget build(BuildContext context) {
    String type = widget.type;
    return AlertDialog(
      title: Row(
        children: [
          Text('Выберите дату'),
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Colors.green,
              size: 30,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Поиск ивентов'),
                    content: Text('Ниже на календаре представлены доступные игры в $type.\n\nВыберите удобную дату для Вас.\n'
                        'Дни подсвеченные синим цветом говорят о том,что в этот день кто-то создал ивент.\n\n'
                        'Желаем удачи в поиске!'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Хорошо'),
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

      content: Container(
        width: 400.0, // Установите фиксированную ширину
        height: 550.0, // Установите фиксированную высоту

        child: Column(

          mainAxisSize: MainAxisSize.min,
          children: [


            TableCalendar(
              calendarFormat: _calendarFormat,
              focusedDay: _focusedDay,
              firstDay: DateTime(2024),
              lastDay: DateTime(2050),
              selectedDayPredicate: (day) {
                return _selectedDay != null && isSameDay(day, _selectedDay!);
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, _) {
                  return _buildDayWidget(date);
                },
                selectedBuilder: (context, date, _) {
                  return _buildDayWidget(date, isSelected: true);
                },
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_selectedDay != null) {
                  print('Выбрана дата: $_selectedDay');
                  print(widget.markerName);
                  _showEventData(_selectedDay!,widget.firstName,widget.userId,widget.markerName);
                }
              },
              child: Text('Отобразить доступные ивенты'),
            ),
            Container(
              margin: EdgeInsets.only(left: 10),
              alignment: Alignment.center,
              width: 300,
              child: Text(
                'Не нашли ничего интересного?\nТогда организуйте игру сами!',
                style: TextStyle(
                    fontSize: 15.0,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => EventCreationForm(
              organizer: widget.organizer,
              activityType: type,
              userId: widget.userId,
              type: type,
              typeEn: widget.typeEn,
              address: widget.address,
              name: widget.name,
              phoneNumber: widget.phoneNumber, firstName: widget.firstName,
            ),

          );
          _refreshData();
        },
        icon: Icon(Icons.add_card),
        label: Text('Организовать ивент'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrangeAccent,
          textStyle: const TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEventData(DateTime selectedDay,String firstName,String uid, String markerName) async {
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.name)
        .get();

    if (eventsSnapshot.exists) {
      final eventsData = eventsSnapshot.data() as Map<String, dynamic>;
      final allEvents = eventsData['events'] as List<dynamic>;

      print('selected DATE NEW');

      print(DateFormat('dd.MM.yyyy').format(selectedDay));


      // Фильтруем события по выбранной дате
      final selectedEvents = allEvents
          .where((event) =>
      DateFormat('dd.MM.yyyy').format(selectedDay) ==
          event['dateEvent'])
          .toList();

      print('selectedEvents $selectedEvents');


      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventsScreen(eventsList: selectedEvents,markerName: markerName,uid: uid,firstName: firstName,selectedDay: _selectedDay),
        ),
      );
    }
  }





  Widget _buildDayWidget(DateTime date, {bool isSelected = false}) {
    bool isDateListed = dateList.contains('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');

    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: isSelected
            ? isDateListed ? Colors.orange : Colors.blue
            : (isDateListed ? Colors.blue : null),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: TextStyle(
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }

}



Widget _buildCard(String data) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(data),
    ),
  );
}



