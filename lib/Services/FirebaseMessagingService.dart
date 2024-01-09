import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> setupFirebaseMessaging(String userId, Function(RemoteMessage) onMessageReceived) async {
    await _firebaseMessaging.subscribeToTopic(userId);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Получено уведомление: $message');
      onMessageReceived(message);
    });

    FirebaseMessaging.instance.getToken().then((token) async {
      // Сохраните FirebaseID устройства
      SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.setString("token", token!);

      String? token2 = preferences.getString('token');
      print('token2');
      print(token2);
    });
  }

  @override
  void onNewToken(String token) {
    // Получите FirebaseID устройства с помощью FirebaseMessaging.instance.getToken()
    FirebaseMessaging.instance.getToken().then((deviceToken) async {
      // Сохраните FirebaseID устройства
      SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.setString("token", deviceToken!);
    });
  }
}
