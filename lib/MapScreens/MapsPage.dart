import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:placeandplay/MapScreens/EventCreationForm.dart';
import '../EmptyScreen.dart';
import '../ProfileScreens/ProfileScreen.dart';

class MapsPage extends StatefulWidget {
  final String userId;

  MapsPage({required this.userId});

  @override
  MapsPageState createState() => MapsPageState();
}

class LegendOverlay extends StatelessWidget {
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
            LegendItem(color: Colors.blue, label: 'Метки с синим цветом - бильярд'),
            Divider(height: 8.0, color: Colors.black),
            LegendItem(color: Colors.red, label: 'Метки с красным цветом - настольный теннис'),
          ],
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class MapsPageState extends State<MapsPage> {
  DocumentSnapshot? userDataSnapshot;
  String? firstName;
  int _currentIndex = 1;
  GoogleMapController? _controller;
  Set<Marker> _markers = Set();
  final apiKey = 'AIzaSyC5PFLVPT3FuPCUYKEcbccwGFaP11r-wUA'; // Замените на свой ключ API

  @override
  void initState() {
    super.initState();
    _fetchLocationsFromFirestore();
    _fetchUserData();
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

    FirebaseFirestore.instance.collection('locations').get().then((querySnapshot) {
      querySnapshot.docs.forEach((doc) async {
        var markerColor;
        var data = doc.data();
        var name = data['name'];
        var coordinates = data['coordinates'] as GeoPoint;
        var address = data['address'];
        var phoneNumber = data['phoneNumber'];
        var type = data['type_ru'];

        if (type == 'Бильярд') {
          markerColor =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        } else if (type == 'Настольный теннис') {
          markerColor =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        } else {
          markerColor =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
        }
        final bool eventExists = await checkEventAvailability(name);

        CollectionReference locations = FirebaseFirestore.instance.collection('locations');
        CollectionReference events = FirebaseFirestore.instance.collection('events');

        String nameToCheck = name;

        locations.where('name', isEqualTo: nameToCheck).get().then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            events.where('name', isEqualTo: nameToCheck).get().then((eventQuerySnapshot) {
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

        var marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(coordinates.latitude, coordinates.longitude),
          icon: markerColor,
          infoWindow: InfoWindow(
            anchor: Offset(1.0, 1.0),
            title: name,
            snippet: address,
          ),
          onTap: () async {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(name),
                  content: FutureBuilder<bool>(
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
                            Text('Доступные ивенты на сегодня'),
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
                                    return Text('Событие не найдено');
                                  }

                                  final eventsList = eventData['events'] as List<dynamic>;




                                  // Создайте список виджетов для отображения данных о событиях
                                  List<Widget> eventWidgets = [];

                                  eventsList.forEach((event) {
                                    final type = event['type'];
                                    final firstName = event['first_name'];
                                    final dateEvent = event['date_event'];
                                    final startTimeEvent = event['start_time_event'];
                                    final organizer = event['organizer'];

                                    // Создайте виджет для отдельного события и добавьте его в список

                                    eventWidgets.add(
                                      Column(
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
                                          SizedBox(height: 16.0),
                                          // Другие данные о событии
                                        ],
                                      ),
                                    );
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
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EventCreationForm(
                                      organizer: firstName.toString(),
                                      activityType: type,
                                      userId: widget.userId,
                                      type: type,
                                      address: address,
                                      name: name,
                                    ),
                                  ),
                                );
                              },
                              child: Text('Создать событие'),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        );


        setState(() {
          _markers.add(marker);
        });
      });
    });
  }

  Future<bool> checkEventAvailability(String nameToCheck) async {
    try {
      final locations = FirebaseFirestore.instance.collection('locations');
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
        final userFirstName = userData['first_name'];

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
}

void main(userId) {
  runApp(MaterialApp(
    home: MapsPage(userId: userId),
  ));
}
