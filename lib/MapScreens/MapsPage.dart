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
  _MapsPageState createState() => _MapsPageState();
}


class LegendOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft, // Отображаем легенду в нижнем левом углу
      child: Container(
        margin: EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 100.0), // Добавляем отступ снизу
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8), // Делаем фон более прозрачным
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LegendItem(color: Colors.blue, label: 'Метки с синим цветом - бильярд'),
            Divider(height: 8.0, color: Colors.black), // Добавляем разделитель
            LegendItem(color: Colors.red, label: 'Метки с красным цветом - настольный теннис'),
            // Добавьте другие LegendItem и разделители по необходимости
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

class _MapsPageState extends State<MapsPage> {
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
      querySnapshot.docs.forEach((doc) {
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


        // Создайте метку на карте
        var marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(coordinates.latitude, coordinates.longitude),
          icon: markerColor,
          infoWindow: InfoWindow(anchor: Offset(1.0, 1.0),
            title: name, // Отображаем название объекта
            snippet: address, // Отображаем адрес
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(name), // Отображаем название объекта
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Адрес: $address'),
                      // Отображаем адрес
                      Text('Телефон: $phoneNumber'),
                      // Отображаем номер телефона
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  EventCreationForm(organizer: firstName.toString(),
                                      activityType: type,userId: widget.userId,type: type,address:address,name:name),
                            ),
                          );
                        },
                        child: Text(
                            'Создать ивент'), // Пример кнопки "Создать ивент"
                      ),
                    ],
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


  Future<void> _fetchUserData()  async {
    print('Запустилась хуйня');
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(user.uid)
          .get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        final userFirstName = userData['first_name'];

        if (userFirstName != null) {
          setState(() {
            firstName = userFirstName; // Устанавливайте имя пользователя в переменной состояния
          });
        }else{
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
    final apiKey = 'AIzaSyC5PFLVPT3FuPCUYKEcbccwGFaP11r-wUA';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_address,formatted_phone_number&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final result = data['result'];

        // Проверить, есть ли 'name' в ответе
        if (result.containsKey('name')) {
          final name = result['name'];
          print('Название: $name');
        } else {
          print('Название отсутствует в ответе');
        }

        // Проверить, есть ли 'formatted_address' в ответе
        if (result.containsKey('formatted_address')) {
          final address = result['formatted_address'];
          print('Адрес: $address');
        } else {
          print('Адрес отсутствует в ответе');
        }

        // Проверить, есть ли 'formatted_phone_number' в ответе
        if (result.containsKey('formatted_phone_number')) {
          final phoneNumber = result['formatted_phone_number'];
          print('Телефон: $phoneNumber');
        } else {
          print('Телефон отсутствует в ответе');
        }
      } else {
        // Обработка ошибки от API
        print('Ошибка от Google Places API: ${data['error_message']}');
      }
    } else {
      // Обработка ошибки запроса
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
          // Чтение JSON-файла со стилями карты
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
          ]
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
            // Пользователь выбрал вкладку "Карта", перенаправляем его на пустую страницу
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: widget.userId),
              ),
            );
          } else if(index == 1){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MapsPage(userId: widget.userId),
              ),
            );
          }else if(index == 2){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EmptyScreen(),
              ),
            );
          }
          // Для других вкладок обновляем индекс
          setState(() {
            _currentIndex = index;
          });
        }
      ),
    );
  }
}

void main(userId) {
  runApp(MaterialApp(
    home: MapsPage(userId: userId),
  ));
}
