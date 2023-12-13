import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  static final CollectionReference _presenceCollection = FirebaseFirestore.instance.collection('presence');

  static Future<void> setUserOnline(String userId) async {
    await _presenceCollection.doc(userId).set({'online': true});
  }

  static Future<void> setUserOfflineAndUpdateLastOnline(String userId) async {
    try {
      // Получите текущее время
      DateTime now = DateTime.now();

      // Обновите поля в базе данных
      await _presenceCollection.doc(userId).set({
        'online': false,
        'lastOnline': now,
      });
    } catch (e) {
      print('Ошибка при обновлении времени последнего онлайна: $e');
      // Обработайте ошибку по вашему усмотрению
    }
  }

  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot snapshot = await _presenceCollection.doc(userId).get();
      return snapshot.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Ошибка при получении данных пользователя: $e');
      return null;
    }
  }

  static Stream<DocumentSnapshot> streamUserPresence(String userId) {
    return _presenceCollection.doc(userId).snapshots();
  }
}
