import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:placeandplay/MapScreens/EventCreationForm.dart';
import '../EmptyScreen.dart';
import '../ProfileScreens/ProfileScreen.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:intl/intl.dart';



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
  String markerName = "";
  DocumentSnapshot? userDataSnapshot;
  String firstName = "";
  int _currentIndex = 1;
  GoogleMapController? _controller;
  Set<Marker> _markers = Set();
  List<Widget> _markerWidgets = [];
  List<TextMarker> _textMarkers = [];

  final apiKey = 'AIzaSyC5PFLVPT3FuPCUYKEcbccwGFaP11r-wUA'; // Замените на свой ключ API

  @override
  void initState() {
    super.initState();
    _fetchLocationsFromFirestore();
    _fetchUserData();
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

  Future<void> _fetchLocationsFromFirestore() async {


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
        CollectionReference events = FirebaseFirestore.instance.collection('events');

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
                content: Container(
                color: Colors.white.withOpacity(0.5),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                    child: FutureBuilder<bool>(
                      future: checkEventAvailability(name),
                      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Произошла ошибка: ${snapshot.error}');
                        } else {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              Text('Мероприятия на сегодня',
                                style: TextStyle(color: Colors.black, fontSize: 18)),
                              SizedBox(height: 8.0),
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

                                    final eventsList = eventData['events'] as List<dynamic>;

                                    // Создайте список виджетов для отображения данных о событиях
                                    List<Widget> eventWidgets = [];

                                    eventsList.forEach((event) {
                                      final type = event['type'];
                                      final firstName = event['firstName'];
                                      final dateEvent = event['dateEvent'];
                                      final startTimeEvent = event['startTimeEvent'];
                                      final organizer = event['organizer'];
                                      final List<dynamic> participantsData = event['participants'];
                                      final List<Map<String, String>> participants = participantsData.map((participant) {
                                        final Map<String, dynamic> participantData = participant as Map<String, dynamic>;

                                        // Извлекаем uid и firstName из данных участника
                                        final String uid = participantData['uid'] as String;
                                        final String firstName = participantData['firstName'] as String;

                                        return {'uid': uid, 'firstName': firstName};
                                      }).toList();
                                      DateTime currentDate = DateTime.now();
                                      DateTime eventDate = DateFormat('dd.MM.yyyy').parse(dateEvent);
                                      String currentDateFormatted = DateFormat('dd.MM.yyyy').format(currentDate);
                                      String eventDateFormatted = DateFormat('dd.MM.yyyy').format(eventDate);

                                      bool isSameDate = currentDateFormatted == eventDateFormatted; // проверка на день
                                      final eventTime = TimeOfDay.fromDateTime(DateTime.parse("2023-10-27 $startTimeEvent:00"));

                                      final currentTime = TimeOfDay.now();



                if (!isSameDate) {
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center, // Для размещения текста по центру
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
                }else if(isSameDate){
                  if (isEventExpired(startTimeEvent)) {
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
                                  // Промежуток между кнопками
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Действия при нажатии на кнопку "Присоединиться"
                                    },
                                    icon: Icon(Icons.add), // Иконка "плюс"
                                    label: Text('Присоединиться'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        textStyle: const TextStyle(
                                          fontSize: 25.0,
                                          fontWeight: FontWeight.bold,
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center, // Для размещения кнопок в начале и в конце строки
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Действия при нажатии на кнопку "Посмотреть участников"
                                  },
                                  icon: Icon(Icons.group), // Иконка "группа пользователей"
                                  label: Text('Посмотреть участников'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
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
                              mainAxisAlignment: MainAxisAlignment.center, // Для размещения кнопок в начале и в конце строки
                              children: [
                                // Промежуток между кнопками
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Действия при нажатии на кнопку "Присоединиться"
                                  },
                                  icon: Icon(Icons.add), // Иконка "плюс"
                                  label: Text('Присоединиться'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    textStyle: const TextStyle(
                                      fontSize: 25.0,
                                      fontWeight: FontWeight.bold,
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
                                          address: address,
                                          name: name,
                                          phoneNumber: phoneNumber, firstName: firstName,
                                      ),
                                    ),
                                  );
                                },
                                child: Text('Создать событие')
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    ),
                  ),
                ),
                );
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







  Future<bool> checkEventAvailability(String nameToCheck) async {
    try {
      final locations = FirebaseFirestore.instance.collection('locationsUz');
      final events = FirebaseFirestore.instance.collection('events');

      final locationQuerySnapshot = await locations.where('name', isEqualTo: nameToCheck).get();

      if (locationQuerySnapshot.docs.isNotEmpty) {
        // Получите документ, который содержит информацию о событиях
        final eventDocument = await events.doc('Black Pool').get();

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
        onTap: (int index) {
          if (index == 0) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: widget.userId),
              ),
            );
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MapsPage(userId: widget.userId),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EmptyScreen(),
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

class Event {

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
