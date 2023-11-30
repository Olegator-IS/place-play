import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> setupFirebaseMessaging(String userId, Function(RemoteMessage) onMessageReceived) async {
    await _firebaseMessaging.subscribeToTopic(userId);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Получено уведомление: $message');
      onMessageReceived(message);
    });
  }
}
