import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import '../EmptyScreen.dart';
import '../ProfileScreens/ProfileScreen.dart';
import 'package:geocoding/geocoding.dart';



class MapsPage extends StatefulWidget {
  final String userId;

  MapsPage({required this.userId});

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  int _currentIndex = 1;
  GoogleMapController? _controller;
  Set<Marker> _markers = Set();
  final apiKey = 'AIzaSyC5PFLVPT3FuPCUYKEcbccwGFaP11r-wUA'; // Замените на свой ключ API

  @override
  void initState() {
    super.initState();
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
      appBar: AppBar(
        title: Text('Карта'),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          _controller = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(41.3111, 69.2797),
          zoom: 16.0,
        ),
        myLocationButtonEnabled: true,
        markers: _markers,
        onTap: (LatLng position) {
          // Handle the map tap event here
          print("Нажато по координатам: ${position.latitude}, ${position.longitude}");
          _getPlaceId(position);
        },
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
            label: 'Избранное',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (int index) {
          if (index == 0) {
            // Пользователь выбрал вкладку "Профиль", перенаправляем его на профиль
          } else if (index == 2) {
            // Пользователь выбрал вкладку "Избранное", перенаправляем его на EmptyScreen
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