import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:placeandplay/ProfileScreens/ViewProfileScreen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../PresenceService.dart';



class EventConversation extends StatefulWidget {
  final String eventId;

  EventConversation({required this.eventId});

  @override
  _EventConversationState createState() => _EventConversationState();
}
TextEditingController messageController = TextEditingController();
bool isEditing = false;
String messageIdForEdit = '';
String docIdForDelete = '';
String eventIdForDelete = '';
class _EventConversationState extends State<EventConversation> {
  bool _isOnline = false;
  late StreamSubscription<DocumentSnapshot> _presenceSubscription;
  String get eventId => widget.eventId;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  String? previousSender;
  int consecutiveMessageCount = 0;
  User? user = FirebaseAuth.instance.currentUser;

  CollectionReference messagesCollection =
  FirebaseFirestore.instance.collection('eventMessages');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    eventIdForDelete = widget.eventId;
    String? sender = user?.uid;
    _presenceSubscription = PresenceService.streamUserPresence(sender!).listen((DocumentSnapshot snapshot) {
      if (mounted && snapshot.exists) {
        setState(() {
          _isOnline = (snapshot.data() as Map<String, dynamic>?)?['online'] ?? false;
        });
      }
    });
    // Добавляем слушатель при создании виджета
    // _initPlatformState();
    // _registerBroadcastReceiver();
  }
  // Инициализация канала для платформенных вызовов
  // Future<void> _initPlatformState() async {
  //   const platform = MethodChannel('example.com/broadcast');
  //
  //   try {
  //     await platform.invokeMethod('initBroadcastReceiver');
  //   } on PlatformException catch (e) {
  //     print("Failed to invoke platform method: '${e.message}'.");
  //   }
  // }

  // Регистрация локального широковещательного приемника
  // Future<void> _registerBroadcastReceiver() async {
  //   const platform = MethodChannel('example.com/broadcast');
  //
  //   // Используем EventChannel для прослушивания событий от Android
  //   EventChannel('example.com/broadcast_receiver')
  //       .receiveBroadcastStream()
  //       .listen((dynamic event) {
  //     // Обработка данных, которые вы передаете из MyFirebaseMessagingService
  //     print('Received broadcast event: $event');
  //     // Возможно, здесь вы хотите обновить ваш интерфейс с новыми данными
  //   });
  // }

  // @override
  // void dispose() {
  //   // Отменяем регистрацию локального широковещательного приемника при уничтожении виджета
  //   const platform = MethodChannel('example.com/broadcast');
  //   platform.invokeMethod('disposeBroadcastReceiver');
  //   super.dispose();
  // }

  Future<String?> getSenderFirstName(String senderId) async {
    try {
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

  @override
  Widget build(BuildContext context) {
    // _initPlatformState();
    // _registerBroadcastReceiver();
    return Scaffold(
      appBar: AppBar(
        title: Text('Чат для события ${widget.eventId}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: messagesCollection
                  .doc(widget.eventId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SpinKitFadingCircle(
                    color: Colors.blue, // Цвет анимации
                    size: 20.0, // Размер анимации
                  );
                }

                List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

                return ListView.builder(
                  key: ValueKey(widget.eventId),
                  reverse: true,
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    var messageData = documents[index].data() as Map<String, dynamic>;
                    var isMyMessage = messageData['senderId'] == user?.uid;
                    String? sender = user?.uid;
                    // Кто прочитал сообшение
                    messagesCollection
                        .doc(widget.eventId)
                        .collection('messages')
                        .doc(documents[index].id)
                        .update({
                      'readBy': FieldValue.arrayUnion([user?.uid]),
                    });
                    return FutureBuilder<String?>(
                      initialData: 'Аноним',
                      future: getSenderFirstName(sender!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          String senderName = snapshot.data ?? 'Аноним';
                          print('senderName $senderName');

                          bool showSenderInfo = true;
                          if (senderName == previousSender) {
                            consecutiveMessageCount++;
                            if (consecutiveMessageCount > 1) {
                              showSenderInfo = false;
                            }
                          } else {
                            previousSender = messageData['senderName'];
                            consecutiveMessageCount = 1;
                          }

                          return MessageBubble(
                            message: messageData['message'],
                            senderName: messageData['senderName'],
                            isMyMessage: isMyMessage,
                            senderId: messageData['senderId'],
                            timestamp: messageData['timestamp'] is Timestamp
                                ? (messageData['timestamp'] as Timestamp).toDate()
                                : DateTime.now(),
                              readBy: [],
                            isChanged: messageData['isChanged'],
                            messageId: messageData['messageId'],
                            docId: messageData['docId'],
                            isOnline: _isOnline,
                          );
                        }else{
                          return const SpinKitFadingCircle(
                            color: Colors.blue, // Цвет анимации
                            size: 20.0, // Размер анимации
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: messageController,
                        maxLines: null, // Установите null, чтобы позволить несколько строк
                        keyboardType: TextInputType.multiline, // Используйте TextInputType.multiline
                        decoration: const InputDecoration(
                          hintText: 'Введите сообщение...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void sendMessage() async {
    String newMessage = messageController.text;
    String? sender = user?.uid;
print(isEditing);
print(newMessage);
print(messageIdForEdit);

    if (isEditing) {
      // Если мы находимся в режиме редактирования
      if (messageIdForEdit.isNotEmpty) {
        // Проверяем, что у нас есть messageId
        await messagesCollection
            .doc(widget.eventId)
            .collection('messages')
            .doc(messageIdForEdit)
            .update({
          'message': newMessage,
          'isChanged': true,
        });

        // Очищаем messageId и переходим из режима редактирования
        messageIdForEdit = '';
        isEditing = false;
        messageController.clear();
      }
    } else {
      String senderName = await getSenderFirstName(sender!) ?? 'Аноним';

      // Если мы не в режиме редактирования, добавляем новое сообщение
      DocumentReference<Map<String, dynamic>> newMessageRef =
      await messagesCollection
          .doc(widget.eventId)
          .collection('messages')
          .add({
        'message': newMessage,
        'senderId': user?.uid,
        'senderName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [user?.uid],
        'isChanged': false,
        'messageId': '',
        'docId': '',// Пустой идентификатор, так как он будет обновлен
      });

      String messageId = newMessageRef.id;
      String docId = eventId;

      // Обновляем messageId в добавленном сообщении
      await newMessageRef.update({'messageId': messageId});
      await newMessageRef.update({'docId': docId});

      initializeNotifications();
      sendTestNotification();

      messageController.clear();
    }
  }



  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;




  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> sendTestNotification() async {
    await _firebaseMessaging.subscribeToTopic('test'); // Подписываемся на тему

    // Создаем уведомление
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your channel id', // id канала
      'your channel name', // имя канала
      importance: Importance.max,
      priority: Priority.high,
    );

    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Заголовок уведомления',
      'Текст уведомления',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    // Обработка данных из уведомления, пришедшего в фоновом режиме
  }







}





class MessageBubble extends StatelessWidget {
  final String message;
  final String senderName;
  final bool isMyMessage;
  final String senderId;
  final DateTime timestamp; // Используйте Timestamp вместо String
  final List<dynamic> readBy;
  final bool isChanged;
  final String messageId;
  final String docId;
  final bool isOnline;

  MessageBubble({
    required this.message,
    required this.senderName,
    required this.isMyMessage,
    required this.senderId,
    required this.timestamp,
    required this.readBy,
    required this.isChanged,
    required this.messageId,
    required this.docId,
    required this.isOnline,
  });





  void showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        if (isMyMessage) {
          return MessageContextMenu(
            onDelete: () {
              // Обработка удаления сообщения
              deleteMessage();
              Navigator.pop(context); // Закрыть контекстное меню
            },
            onEdit: () {
              print('ti loh 123');
              print(message);
              Navigator.pop(context);
              messageController.text = message;
              String newMessage = message;
              isEditing = true;
              if (newMessage.isNotEmpty) {
                CollectionReference messagesCollection =
                FirebaseFirestore.instance.collection('eventMessages');
                // Обновите сообщение в базе данных
                messagesCollection.doc(docId)
                    .collection('messages')
                    .doc(messageId) // messageId - уникальный идентификатор сообщения
                    .update({
                  'message': newMessage,
                  'isChanged': true, // Добавьте флаг isChanged
                });
              }
            },
          );
        } else {
          return const SizedBox(); // Не отображать контекстное меню для чужих сообщений
        }
      },
    );
  }

  Future<void> showEditDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Редактировать сообщение'),
          content: TextField(
            controller: messageController,
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Закрыть диалоговое окно
              },
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                // Обработка редактирования сообщения
                editMessage();
                Navigator.pop(context); // Закрыть диалоговое окно
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }



  Future<void> deleteMessage() async {
    try {
      CollectionReference messagesCollection =
      FirebaseFirestore.instance.collection('eventMessages');
      await messagesCollection
          .doc(docId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print('Ошибка при удалении сообщения: $e');
      // Обработайте ошибку по вашему усмотрению
    }
  }

  void editMessage() {
    print('ti loh2');
    // Логика изменения сообщения
  }

  void navigateToUserProfile(BuildContext context, String userId) {
    print('clickOn$userId');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViewProfileScreen(userId: userId),
      ),
    );
    // Здесь добавьте код для перехода на профиль пользователя
    // Вы можете использовать Navigator.push и MaterialPageRoute
    // или любой другой способ, который вы обычно используете для переходов в приложении.
  }


  @override
  Widget build(BuildContext context) {
    if (senderId == '12345' && senderName == 'system') {
      // Отображение системного сообщения в центре чата
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.red[300],
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Text(
                message.toUpperCase(),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ));
    }
    return GestureDetector(
        onLongPress: () {
      showContextMenu(context);
      messageIdForEdit = messageId;
      print('TESTTTTTT$eventIdForDelete');


    },
    child:Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMyMessage)
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: GestureDetector(
              onTap: () {
                // Переход на профиль пользователя при нажатии на senderName
                navigateToUserProfile(context, senderId);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0), // Отступ справа
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8.0), // Расстояние между сообщениями
        Row(
          mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMyMessage)
              GestureDetector(
                onTap: () {
                  // Переход на профиль пользователя при нажатии на CircleAvatar
                  navigateToUserProfile(context, senderId);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0), // Отступ слева
                  child: CircleAvatar(
                    child: Text(
                      senderName.isNotEmpty ? senderName[0] : 'A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.blue, // Цвет круга для входящих сообщений
                  ),
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: 300.0, // Установите максимальную ширину по вашему усмотрению
              ),
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMyMessage ? Colors.blue : Colors.green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                  bottomLeft: isMyMessage ? Radius.circular(15) : Radius.circular(0),
                  bottomRight: isMyMessage ? Radius.circular(0) : Radius.circular(15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    softWrap: true, // Разрешить перенос текста
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    _formatTimestamp(timestamp), // Отображение времени
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                  if (isChanged)
                    Text(
                      'редактировано',
                      style: TextStyle(
                        color: Colors.black, // Любой цвет, который вам подходит
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (isMyMessage)
              GestureDetector(
                onTap: () {
                  // Переход на профиль пользователя при нажатии на CircleAvatar
                  navigateToUserProfile(context, senderId);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0), // Отступ справа
                  child: CircleAvatar(
                    child: Text(
                      senderName.isNotEmpty ? senderName[0] : 'A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.blue, // Цвет круга для исходящих сообщений
                  ),
                ),
              ),
          ],
        ),
      ],
     ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat.yMMMd().add_jm().format(timestamp);
  }
}

class MessageContextMenu extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  MessageContextMenu({
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text('Удалить'),
          onTap: onDelete,
        ),
        ListTile(
          title: Text('Изменить'),
          onTap: onEdit,
        ),
      ],
    );
  }
}

