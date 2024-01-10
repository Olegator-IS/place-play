import 'dart:convert';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:placeandplay/Events/EventConversation.dart';
import 'package:placeandplay/Events/EventCreationForm.dart';
import 'package:placeandplay/ProfileScreens/ProfileScreen.dart';
import 'package:placeandplay/ProfileScreens/ViewProfileScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../EmptyScreen.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:intl/intl.dart';

import '../Events/EventsList.dart';


String? token;

class MapsPage extends StatefulWidget {
  final String userId;


  const MapsPage({super.key, required this.userId});

  @override
  MapsPageState createState() => MapsPageState();
}



class TextMarker {
  final LatLng position;
  final String text;

  TextMarker({
    required this.position,
    required this.text,
  });
}



class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Обработка нажатия на элемент легенды
        print('Нажал на: $label');
        // Здесь вы можете выполнить дополнительные действия в зависимости от выбора
      },
      child: Row(
        children: <Widget>[
          Container(
            width: 20.0,
            height: 20.0,
            decoration: BoxDecoration(
              color: color,
            ),
          ),
          SizedBox(width: 8.0),
          Text(label),
        ],
      ),
    );
  }
}


class MapsPageState extends State<MapsPage> {
  CollectionReference events = FirebaseFirestore.instance.collection('events');
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
  bool isJoinButtonVisible = true;
  DateTime? selectedDate; // Добавляем переменную для хранения выбранной даты
  String markerName = "";
  DocumentSnapshot? userDataSnapshot;
  String firstName = "";
  int _currentIndex = 1;
  GoogleMapController? _controller;
  Set<Marker> _markers = Set();
  List<Widget> _markerWidgets = [];
  List<TextMarker> _textMarkers = [];

  final apiKey = 'AIzaSyC5PFLVPT3FuPCUYKEcbccwGFaP11r-wUA'; // Замените на свой ключ API
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    _fetchLocationsFromFirestore();
    _fetchUserData();
    _refreshData();
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


  Future<BitmapDescriptor> createTextMarkerIcon(String text, Color textColor, Color backgroundColor) async {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: 30.0,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();

    final size = textPainter.size;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(size.width, size.height)));

    if (backgroundColor != Colors.transparent) {
      final paintBackground = Paint()..color = backgroundColor;
      canvas.drawRect(Rect.fromPoints(Offset(0, 0), Offset(size.width, size.height)), paintBackground);
    }

    textPainter.paint(canvas, Offset(0, 0));

    final img = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = data?.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(buffer!);
  }
  bool isDateInFuture(String dateEvent) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final eventDateTime = dateFormat.parse(dateEvent);
    final currentDateTime = DateTime.now();

    return eventDateTime.isAfter(currentDateTime);
  }

  bool isDateInPast(String dateEvent, int daysAgo) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final eventDateTime = dateFormat.parse(dateEvent);
    final currentDateTime = DateTime.now();
    final difference = currentDateTime.difference(eventDateTime);

    return difference.inDays >= daysAgo;
  }

  bool isEventExpired(String startTimeEvent) {
    final eventTime = TimeOfDay.fromDateTime(DateTime.parse("2023-10-27 $startTimeEvent:00"));
    final currentTime = TimeOfDay.now();

    final eventHour = eventTime.hour;
    final eventMinute = eventTime.minute;
    final currentHour = currentTime.hour;
    final currentMinute = currentTime.minute;

    final hoursDiff = eventHour - currentHour;
    final minutesDiff = eventMinute - currentMinute;

    if (hoursDiff < 0 || (hoursDiff == 0 && minutesDiff < 0)) {
      // Событие истекло
      print('Срок события уже истек.');
      print(eventTime);
      // Здесь вы можете вывести информацию о том, что событие завершилось
      return true;
    } else {
      // Событие ещё актуально
      print('Событие ещё актуально.');
      print('Осталось $hoursDiff часов и $minutesDiff минут.');
      return false;
    }
  }


  void _addTextMarkersToMap() async {
    List<TextMarker> textMarkersCopy = List.from(_textMarkers); // Создаем копию _textMarkers

    for (var textMarker in textMarkersCopy) {
      final customMarker = await createTextMarkerIcon(textMarker.text, Colors.white, Colors.black);
      final markerPosition = LatLng(textMarker.position.latitude - 0.0004, textMarker.position.longitude);
      // В данном примере я сдвинул позицию маркера на 0.01 градуса (что примерно соответствует нескольким сантиметрам)

      _markers.add(
          Marker(
            markerId: MarkerId(textMarker.position.toString()),
            position: markerPosition, // Используйте измененную позицию
            icon: customMarker,
          ));
    }
    _createMarkerWidgetsList();
  }


  Future<void> _refreshData() async {
    await _loadUserData();
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



  Future<void> _fetchLocationsFromFirestore() async {
    final String firstNameUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();


    Location location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        // Обработка случая, когда пользователь не включил службу определения местоположения
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        // Обработка случая, когда разрешения на местоположение не предоставлены
        return;
      }
    }

    _locationData = await location.getLocation();

    FirebaseFirestore.instance.collection('locationsUz').get().then((querySnapshot) {
      querySnapshot.docs.forEach((doc) async {
        var markerColor;
        var data = doc.data();
        var name = data['nameRu'];
        var coordinates = data['coordinates'] as GeoPoint;
        var address = data['address'];
        var phoneNumber = data['phoneNumber'];
        var type = data['typeRu'];
        var typeEn = data['typeEn'];

        if (type == 'Бильярд') {
          markerColor =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        } else if (type == 'Пинг-Понг') {
          markerColor =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        } else if (type == 'Теннис'){
          markerColor =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        }else if (type == 'Пэйнтболл'){
          markerColor =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
        }else if (type == 'Страйкболл'){
          markerColor =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        }
        final bool eventExists = await checkEventAvailability(name);

        CollectionReference locations = FirebaseFirestore.instance.collection('locationsUz');


        String nameToCheck = name;

        locations.where('nameRu', isEqualTo: nameToCheck).get().then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            events.where('nameRu', isEqualTo: nameToCheck).get().then((eventQuerySnapshot) {
              if (eventQuerySnapshot.docs.isNotEmpty) {
                print('Олег лох');
              }
            }).catchError((error) {
              print('Ошибка при выполнении запроса к коллекции events: $error');
            });
          }
        }).catchError((error) {
          print('Ошибка при выполнении запроса к коллекции locations: $error');
        });




        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(coordinates.latitude, coordinates.longitude),
          icon: markerColor,
          infoWindow: InfoWindow(
            title: name,
            snippet: address,
            anchor: Offset(0.5, 0.5),
          ),
          onTap: () async {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(name),
                  content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('events').snapshots(),
                    builder: (context, snapshot) {
                  // Your builder logic here

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Произошла ошибка: ${snapshot.error}');
                            } else {

                              return SingleChildScrollView(
                                child: Column(
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => EventCreationForm(
                                            organizer: firstName.toString(),
                                            activityType: type,
                                            userId: widget.userId,
                                            type: type,
                                            typeEn: typeEn,
                                            address: address,
                                            name: name,
                                            phoneNumber: phoneNumber, firstName: firstName,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text('Создать событие'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black38,
                                      textStyle: const TextStyle(
                                        fontSize: 22.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Text('Все ивенты', style: TextStyle(color: Colors.black, fontSize: 18)),

                                  const Text('Ивенты отмеченные красным цветом уже завершены,присоединиться невозможно\n', style: TextStyle(color: Colors.red, fontSize: 12)),
                                  const Text('Прошедшие ивенты отображаются за последние 3 дня', style: TextStyle(color: Colors.red, fontSize: 12)),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Вызовите метод для обновления данных
                                      _refreshData();
                                      setState(() {
                                      });
                                    },
                                    child: Text('Обновить данные'),
                                  ),

                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance.collection('events').doc(name).get(),
                                    builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> eventSnapshot) {
                                      if (eventSnapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (eventSnapshot.hasError) {
                                        return Text('Произошла ошибка: ${eventSnapshot.error}');
                                      } else if (eventSnapshot.hasData) {
                                        final eventData = eventSnapshot.data!.data();
                                        if (eventData == null || eventData is! Map<String, dynamic>) {
                                          return Text('Событий не найдено');
                                        }

                                        const Text('Доступные мероприятия на', style: TextStyle(color: Colors.black, fontSize: 18));
                                        Text(
                                          selectedDate != null
                                              ? ' ${DateFormat('dd.MM.yyyy').format(selectedDate!)}'
                                              : 'Выберите дату', // Отобразить "Выберите дату", если дата не выбрана
                                          style: TextStyle(color: Colors.black, fontSize: 18),
                                        );
                                        final eventsList = (eventData['events'] as List<dynamic>?) ?? [];

                                        // Создайте список виджетов для отображения данных о событиях
                                        List<Widget> eventWidgets = [];

                                        eventsList.forEach((event) {
                                          final type = event['type'];
                                          final markerName = event['eventName'];
                                          final dateEvent = event['dateEvent'];
                                          final startTimeEvent = event['startTimeEvent'];
                                          final isRegistered = event['isRegistered'];
                                          final organizer = event['organizer'];
                                          final organizerUid = event['uid'];
                                           List<dynamic> participantsData = (event['participants'] as List<dynamic>?) ?? [];
                                           List<Map<String, String>> participants = participantsData.map((participant) {
                                             Map<String, dynamic> participantData = participant as Map<String, dynamic>;

                                            // Извлекаем uid и firstName из данных участника
                                            final String uid = participantData['uid'] as String;
                                            final String firstName = participantData['firstName'] as String;

                                            return {'uid': uid, 'firstName': firstName};
                                          }).toList();
                                          DateTime currentDate = DateTime.now();
                                          DateTime twentyFourHoursAgo = currentDate.subtract(Duration(hours: 24));
                                          DateTime eventDate = DateFormat('dd.MM.yyyy').parse(dateEvent);
                                          String currentDateFormatted = DateFormat('dd.MM.yyyy').format(currentDate);
                                          String eventDateFormatted = DateFormat('dd.MM.yyyy').format(eventDate);

                                          bool isSameDate = currentDateFormatted == eventDateFormatted; // проверка на день
                                          final eventTime = TimeOfDay.fromDateTime(DateTime.parse("2023-10-27 $startTimeEvent:00"));
                                          bool isWithinLast24Hours = eventDate.isAfter(twentyFourHoursAgo);
                                          Duration timeDifference = currentDate.difference(eventDate);


                                          final currentTime = TimeOfDay.now();


                                          print('$timeDifference.inDays $eventDate');


                                          if (!isSameDate && !isDateInFuture(dateEvent)) {
                                            if(!isDateInPast(dateEvent, 2)) {
                                              eventWidgets.add(
                                                InkWell(
                                                  child: Column(
                                                    children: [
                                                      SizedBox(height: 16.0),
                                                      Row(
                                                        children: [
                                                          Text('Тип события:'),
                                                          SizedBox(width: 8),
                                                          Text(type),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Имя организатора:'),
                                                          SizedBox(width: 8),
                                                          Text(organizer),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Участники:'),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            participants.map((
                                                                participant) => participant['firstName'])
                                                                .join(', '),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Дата события:'),
                                                          SizedBox(width: 8),
                                                          Text(dateEvent),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Время начала:'),
                                                          SizedBox(width: 8),
                                                          Text(startTimeEvent),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Статус:'),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            isRegistered ? 'Подтверждено' : 'Ожидает регистрации',
                                                            style: TextStyle(
                                                              color: isRegistered ? Colors.green : Colors.red,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          // Для размещения текста по центру
                                                          children: [
                                                            Text(
                                                              'Данное мероприятие закончено\n$eventDateFormatted\nРегистрация невозможна',
                                                              style: TextStyle(
                                                                color: Colors.red,
                                                                fontSize: 17.0,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }

                                          }else if(isDateInFuture(dateEvent) || isSameDate){
                                            if (isSameDate && isEventExpired(startTimeEvent)) {
                                              final eventHour = eventTime.hour;
                                              final eventMinute = eventTime.minute;
                                              final currentHour = currentTime.hour;
                                              final currentMinute = currentTime.minute;

                                              final hoursDiff =   currentHour - eventHour ;
                                              eventWidgets.add(
                                                InkWell(
                                                  child: Column(
                                                    children: [
                                                      SizedBox(height: 16.0),
                                                      Row(
                                                        children: [
                                                          Text('Тип события:'),
                                                          SizedBox(width: 8),
                                                          Text(type),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Имя организатора:'),
                                                          SizedBox(width: 8),
                                                          Text(organizer),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Участники:'),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            participants.map((participant) => participant['firstName']).join(', '),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Дата события:'),
                                                          SizedBox(width: 8),
                                                          Text(dateEvent),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Время начала:'),
                                                          SizedBox(width: 8),
                                                          Text(startTimeEvent),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Статус:'),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            isRegistered ? 'Подтверждено' : 'Ожидает регистрации',
                                                            style: TextStyle(
                                                              color: isRegistered ? Colors.green : Colors.red,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center, // Для размещения текста по центру
                                                          children: [
                                                            Text(
                                                              'Мероприятие уже идёт\n~ $hoursDiff часов\nНо вы всё еще можете присоединится',
                                                              style: TextStyle(
                                                                color: Colors.red,
                                                                fontSize: 14.0,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center, // Для размещения кнопок в начале и в конце строки
                                                          children: [
                                                            Visibility(
                                                              visible: !isCurrentUserParticipant(participants, widget.userId),
                                                              // Промежуток между кнопками
                                                              child: ElevatedButton.icon(
                                                                onPressed: () {
                                                                  String currentUserId = widget.userId;
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
                                                                    String? firstNameParticipant = prefs.getString('firstName');
                                                                    // Создайте нового участника
                                                                    Map<String, String> newParticipant = {'uid': currentUserId, 'firstName': firstNameParticipant as String};

                                                                    // Добавьте нового участника в список
                                                                    participants.add(newParticipant);

                                                                    // Вызовите функцию для присоединения к мероприятию
                                                                    joinEvent(markerName, dateEvent, startTimeEvent, currentUserId, firstNameParticipant, organizerUid,event['eventId']);
                                                                  }
                                                                },

                                                                icon: Icon(Icons.add), // Иконка "плюс"
                                                                label: Text('Присоединиться 11'),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.green,
                                                                  textStyle: const TextStyle(
                                                                    fontSize: 25.0,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              );
                                            } else {
                                              eventWidgets.add(
                                                InkWell(
                                                  child: Column(
                                                    children: [
                                                      SizedBox(height: 16.0),
                                                      Row(
                                                        children: [
                                                          Text('Тип события:'),
                                                          SizedBox(width: 8),
                                                          Text(type),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Имя организатора:'),
                                                          SizedBox(width: 8),
                                                          Text(organizer),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Участники:'),
                                                          SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              participants.map((participant) => participant['firstName']).join(', '),
                                                              overflow: TextOverflow.ellipsis, // Add ellipsis for better visual indication of overflow
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      Row(
                                                        children: [
                                                          Text('Дата события:'),
                                                          SizedBox(width: 8),
                                                          Text(dateEvent),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Время начала:'),
                                                          SizedBox(width: 8),
                                                          Text(startTimeEvent),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('Статус:'),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            isRegistered ? 'Подтверждено' : 'Ожидает регистрации',
                                                            style: TextStyle(
                                                              color: isRegistered ? Colors.green : Colors.red,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center, // Для размещения кнопок в начале и в конце строки
                                                          children: [
                                                            ElevatedButton.icon(
                                                              onPressed: () {
                                                                showDialog(
                                                                  context: context,
                                                                  builder: (context) => ParticipantsDialog(
                                                                    participants: participants,
                                                                    organizerUid: organizerUid, currentUserUid: widget.userId, // Передайте UID организатора
                                                                  ),
                                                                );
                                                              },
                                                              icon: Icon(Icons.group),
                                                              label: Text('Посмотреть участников'),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: Colors.indigo,
                                                                textStyle: const TextStyle(
                                                                  fontSize: 15.0,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),



                                                      SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Visibility(
                                                              visible: isCurrentUserParticipant(participants, widget.userId),
                                                              child: FutureBuilder<String>(
                                                                future: getUnreadMessageCount(event, widget.userId),
                                                                builder: (context, snapshot) {
                                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                                    return CircularProgressIndicator(); // Или другой индикатор загрузки
                                                                  } else if (snapshot.hasError) {
                                                                    return Text('Ошибка: ${snapshot.error}');
                                                                  } else {
                                                                    String unreadMessageCount = snapshot.data ?? "";
                                                                    return ElevatedButton.icon(
                                                                      onPressed: isJoinButtonVisible
                                                                          ? () {
                                                                        showDialog(
                                                                          context: context,
                                                                          builder: (context) => EventConversation(
                                                                            eventId: event['eventId'], // Передайте UID организатора
                                                                          ),
                                                                        );
                                                                      }
                                                                          : null,
                                                                      icon: Icon(Icons.add),
                                                                      label: Text('Открыть чат$unreadMessageCount'),
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor: Colors.green,
                                                                        textStyle: const TextStyle(
                                                                          fontSize: 25.0,
                                                                          fontWeight: FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Visibility(
                                                              visible: !isCurrentUserParticipant(participants, widget.userId),
                                                              child: ElevatedButton.icon(
                                                                onPressed: isJoinButtonVisible ? () async {
                                                                  // Получите UID текущего пользователя (замените на фактический способ получения UID текущего пользователя)
                                                                  String currentUserId = widget.userId;
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
                                                                    String? firstNameParticipant = prefs.getString('firstName');
                                                                    // Создайте нового участника
                                                                    Map<String, String> newParticipant = {'uid': currentUserId, 'firstName': firstNameParticipant as String};

                                                                    // Добавьте нового участника в список
                                                                    participants.add(newParticipant);

                                                                    // Вызовите функцию для присоединения к мероприятию
                                                                      await joinEvent(markerName, dateEvent, startTimeEvent, currentUserId, firstNameParticipant, organizerUid,event['eventId']);
                                                                    setState(() {
                                                                    });
                                                                    // sendPrepare(token!);
                                                                    List<dynamic>? currentEventTypes = [];
                                                                    List<dynamic>? usersId = [];
                                                                    print('UID NOTIFICATION SENDER $widget.userId');
                                                                    String uid = widget.userId;

                                                                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                                                      'fcmToken': token,
                                                                    });

                                                                    bool doesExist = await doesUserDocExist(typeEn);
                                                                    if (doesExist) {
                                                                      print('eventType exists.');
                                                                      usersId = await getUsersId(typeEn);
                                                                      print(usersId);
                                                                    } else {
                                                                      DocumentReference userDocRef = FirebaseFirestore.instance.collection('subscriptions').doc(typeEn);
                                                                      usersId.add(uid);
                                                                      // Добавляем информацию о пользователе в документ
                                                                      await userDocRef.set({
                                                                        'userId': usersId
                                                                      });
                                                                      print('User added to subscriptions successfully.');
                                                                    }




                                                                    print('Старый');
                                                                    print(usersId);
                                                                    if (!usersId!.contains(uid)) {
                                                                      usersId?.add(uid);
                                                                      print('Обновленный');
                                                                      print(usersId);
                                                                      await FirebaseFirestore.instance.collection('subscriptions').doc(typeEn).update({
                                                                        'userId': usersId,
                                                                      });
                                                                    }


//// Получаю список подписчиков данного спорта

                                                                    String place = name.toString().toUpperCase();
                                                                    String game = type.toString().toUpperCase();
                                                                    sendNotificationToSubscribers(organizerUid,'Ура!Пользователь $firstName присоединился!','Игрок готов к игре в $place');

                                                                  }
                                                                } : null,
                                                                icon: Icon(Icons.add),
                                                                label: Text('Присоединиться'),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.green,
                                                                  textStyle: const TextStyle(
                                                                    fontSize: 25.0,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                      // Другие данные о событии
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }
                                          }

                                        });

                                        // Отобразите все виджеты событий в столбце
                                        return Column(
                                          children: eventWidgets,
                                        );
                                      } else {
                                        return Text('Событие не найдено');
                                      }
                                    },
                                  ),

                                ],
                              ),
                              );
                            }
                          },



                );
                  }
                ));
              },
            );
          },
        );




        setState(() {
          _markers.add(marker);

          _textMarkers.add(TextMarker(
            position: LatLng(coordinates.latitude,coordinates.longitude),
            text: name,
          ));

          _addTextMarkersToMap();
        });
      });
    });
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

  Future<List<dynamic>?> getUsersId(String eventType) async {
    print('ПОЛУЧЕНННННННЫЙ UID EVENT TYPES $eventType');
    try {
      // Получение документа пользователя из коллекции subscriptions
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('subscriptions').doc(eventType).get();

      print('snapshot prowel');
      print('eventType $eventType');
      // Извлечение массива userId из документа пользователя
      List<dynamic>? usersId = (userDoc.data() as Map<String, dynamic>?)?['userId'];
      print('USERS ID -> $usersId');


      return usersId;
    } catch (e) {
      print('Error getting usersId: $e');
      return null;
    }
  }

  Future<void> sendNotificationToSubscribers(String organizerUid, String title, String body) async {

      try {
        // Получаем документ пользователя из коллекции 'users'
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(organizerUid).get();

        // Извлекаем токен пользователя
        String? userToken = (userDoc.data() as Map<String, dynamic>?)?['fcmToken'];


        print('userToken $userToken');
        // Проверяем, есть ли токен
        if (userToken != null) {
          String swipe = "audio/swipe.mp3";
          // Отправляем уведомление с использованием полученного токена


          await sendNotification(userToken, title, body, organizerUid,swipe);
        } else {
          print('Токен пользователя не найден для пользователя с UID $organizerUid');
        }
      } catch (e) {
        print('Ошибка при отправке уведомления пользователю с UID $organizerUid: $e');
      }

  }

  Future<void> sendNotification(String token, String title, String body, String sender,String sound) async {
    final HttpsCallable sendNotificationCallable =
    FirebaseFunctions.instance.httpsCallable('sendNotification');

    print(token);

    // Создаем объект payload
    final payload = {
      'token': token,
      'title': title,
      'body': body,
      'sender': sender,
      'sound':sound

    };

    try {
      final result = await sendNotificationCallable.call(payload);
      // здесь вы можете обработать результат вызова
    } catch (e) {
      print('Error calling sendNotification: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print('Пользователь подписан на топик: $topic');
  }












  Future<void> updateEventParticipants(String markerName, List<Map<String, String>> participants, String dateEvent, String startTimeEvent) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance.collection('events').doc(markerName);
      print(docRef);

      // Получите данные документа "Black Pool"
      DocumentSnapshot docSnapshot = await docRef.get();

      Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

      if (data != null) {
        // Извлеките поле "events" (которое является массивом)
        List<dynamic> events = (data['events'] as List<dynamic>);
        print(events);

        // Найдите событие по dateEvent и startTimeEvent
        for (int i = 0; i < events.length; i++) {
          Map<String, dynamic> event = events[i];
          if (event['dateEvent'] == dateEvent && event['startTimeEvent'] == startTimeEvent) {
            // Если событие найдено, обновите его "participants"
            events[i]['participants'] = FieldValue.arrayUnion(participants);
            break;
          }
        }

        // Обновите документ с обновленным массивом "events"
        await docRef.update({'events': events});

        print('Данные успешно обновлены');
      } else {
        print('Документ не найден');
      }
    } catch (error) {
      print('Произошла ошибка: $error');
    }
  }

  bool isCurrentUserParticipant(List<dynamic> participants, String currentUserId) {
    for (var participant in participants) {
      if (participant['uid'] == currentUserId) {
        return true;
      }
    }
    return false;
  }

  Future<void> joinEvent(String markerName, String dateEvent, String startTimeEvent, String currentUserId, String firstNameParticipant,String organizerUid,String eventId) async {
    try {
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


















  Future<bool> checkEventAvailability(String nameToCheck) async {
    try {
      final locations = FirebaseFirestore.instance.collection('locationsUz');
      final events = FirebaseFirestore.instance.collection('events');

      final locationQuerySnapshot = await locations.where('name', isEqualTo: nameToCheck).get();

      if (locationQuerySnapshot.docs.isNotEmpty) {
        // Получите документ, который содержит информацию о событиях
        final eventDocument = await events.doc(nameToCheck).get();

        if (eventDocument.exists) {
          // Проверьте поле 'events' на наличие объектов с полем 'name'
          final eventsList = eventDocument['events'] as List<dynamic>;

          final hasName = eventsList.any((event) => event['name'] == nameToCheck);

          return hasName;
        }
      }

      return false;
    } catch (error) {
      print('Ошибка при выполнении запроса: $error');
      return false;
    }
  }


  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    token = await messaging.getToken();
    print('FCM Device Token: $token');

    if (user != null) {
      final userSnapshot = await FirebaseFirestore.instance.collection('userProfiles').doc(user.uid).get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        final userFirstName = userData['firstName'];

        if (userFirstName != null) {
          setState(() {
            firstName = userFirstName;
          });
        } else {
          print('loooooooh');
        }
      }
    }
  }

  Future<void> _getPlaceId(LatLng position) async {
    final lat = position.latitude;
    final lng = position.longitude;
    final geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';

    final geocodeResponse = await http.get(Uri.parse(geocodeUrl));

    if (geocodeResponse.statusCode == 200) {
      final geocodeData = json.decode(geocodeResponse.body);
      final results = geocodeData['results'] as List<dynamic>;
      if (results.isNotEmpty) {
        final placeId = results[0]['place_id'];
        await getPlaceDetails(placeId);
      } else {
        print('Местоположение не найдено.');
      }
    } else {
      print('Не удалось выполнить запрос к API.');
    }
  }

  Future<void> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_address,formatted_phone_number&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final result = data['result'];

        if (result.containsKey('name')) {
          final name = result['name'];
          print('Название: $name');
        } else {
          print('Название отсутствует в ответе');
        }

        if (result.containsKey('formatted_address')) {
          final address = result['formatted_address'];
          print('Адрес: $address');
        } else {
          print('Адрес отсутствует в ответе');
        }

        if (result.containsKey('formatted_phone_number')) {
          final phoneNumber = result['formatted_phone_number'];
          print('Телефон: $phoneNumber');
        } else {
          print('Телефон отсутствует в ответе');
        }
      } else {
        print('Ошибка от Google Places API: ${data['error_message']}');
      }
    } else {
      print('Ошибка при запросе: ${response.reasonPhrase}');
    }
  }

  Future<void> _createMarkerWidgetsList() async {
    final markerWidgets = await createMarkerWidgetsList();
    setState(() {
      _markerWidgets = markerWidgets;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              DefaultAssetBundle.of(context).loadString('assets/map/map_style.json').then((style) {
                controller.setMapStyle(style);
              });
              _controller = controller;
              _addTextMarkersToMap();
            },
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: LatLng(41.3111, 69.2797),
              zoom: 17.0,
            ),
            myLocationButtonEnabled: true,
            markers: _markers,
            onTap: (LatLng position) {
              print("Нажато по координатам: ${position.latitude}, ${position.longitude}");
              _getPlaceId(position);
            },
          ),
          ..._markerWidgets,
          LegendOverlay(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Карта',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'События',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (int index) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String userId = prefs.getString('uid').toString();
          print('My user $userId');
          if (index == 0) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: userId),
              ),
            );
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MapsPage(userId: userId),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventsList(userId: userId),
              ),
            );
          }
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
  Future<List<Widget>> createMarkerWidgetsList() async {
    List<Widget> markerWidgets = [];
    print('Сюда попало');
    print(_markers);
    for (final marker in _markers) {

      final screenCoordinate = await _controller?.getScreenCoordinate(marker.position);
      final left = screenCoordinate?.x;
      final top = screenCoordinate?.y;


      print('testssss');
      if (left != null && top != null) {
        markerWidgets.add(
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      }
    }

    return markerWidgets;
  }
}



class ParticipantsDialog extends StatelessWidget {
  CollectionReference<Map<String, dynamic>> events =
  FirebaseFirestore.instance.collection('events');
  final List<Map<String, String>> participants;
  final String organizerUid;
  final String currentUserUid; // UID текущего пользователя

  ParticipantsDialog({
    required this.participants,
    required this.organizerUid,
    required this.currentUserUid,
  });

  @override
  Widget build(BuildContext context) {
    // Подсчитываем высоту контейнера в зависимости от количества участников
    final containerHeight = participants.length * 100.0;

    return AlertDialog(
      title: Text('Список участников'),
      content: Container(
        width: double.maxFinite,
        height: containerHeight > 400.0 ? 400.0 : containerHeight,
        // Используем SingleChildScrollView для прокрутки, если участников много
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  final uid = participant['uid'];
                  final firstName = participant['firstName'];
                  final isOrganizer = (uid == organizerUid);

                  // Проверка, является ли текущий пользователь организатором
                  final isCurrentUserOrganizer = (uid == currentUserUid);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOrganizer ? Colors.green : Colors.grey,
                      child: Text(
                        firstName!.substring(0, 1),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(firstName),
                    subtitle: isOrganizer ? Text('Организатор') : Text('Участник'),
                    // Добавляем PopupMenuItem для "Посмотреть профиль"
                    trailing: isCurrentUserOrganizer
                        ? null
                        : PopupMenuButton<String>(
                      onSelected: (String choice) {
                        if (choice == 'viewProfile') {
                          // Вызов функции для просмотра профиля участника
                          print('test');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => ViewProfileScreen(userId: uid as String)),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'viewProfile',
                            child: ListTile(
                              title: Text('Посмотреть профиль'),
                              subtitle: Text(firstName),
                            ),
                          ),
                        ];
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Закрыть'),
        ),
      ],
    );
  }

}






class LegendOverlay extends StatefulWidget {
  @override
  _LegendOverlayState createState() => _LegendOverlayState();
}

class _LegendOverlayState extends State<LegendOverlay> {
  bool _isLegendVisible = true; // Начальное состояние - легенда видима

  void _toggleLegendVisibility() {
    setState(() {
      _isLegendVisible = !_isLegendVisible;
    });
  }

  late Offset _tapPosition;

  // Обработка касания на вашем виджете
  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _tapPosition = details.globalPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 100.0),
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_isLegendVisible)
              ListView(
                shrinkWrap: true, // Позволяет списку занимать только необходимое пространство
                children: [
                  LegendItem(color: Colors.blue, label: 'Метки с синим цветом - бильярд'),
                  Divider(height: 8.0, color: Colors.black),
                  LegendItem(color: Colors.red, label: 'Метки с красным цветом - настольный теннис'),
                  Divider(height: 8.0, color: Colors.black),
                  LegendItem(color: Colors.green, label: 'Метки с красным цветом - большой теннис'),
                  Divider(height: 8.0, color: Colors.black),
                  LegendItem(color: Colors.purple, label: 'Метки с красным цветом - пэйнтболл'),
                  Divider(height: 8.0, color: Colors.black),
                  LegendItem(color: Colors.orange, label: 'Метки с красным цветом - страйкболл'),
                ],
              ),
            ElevatedButton(
              onPressed: _toggleLegendVisibility,
              child: Text(_isLegendVisible ? 'Скрыть легенду' : 'Показать легенду'),
            ),
          ],
        ),
      ),
    );
  }
}

void main(userId) {
  runApp(MaterialApp(
    home: MapsPage(userId: userId),
  ));
}