import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:placeandplay/ProfileScreens/ViewProfileScreen.dart';
import 'package:intl/intl.dart';


class EventConversation extends StatefulWidget {
  final String eventId;

  EventConversation({required this.eventId});

  @override
  _EventConversationState createState() => _EventConversationState();
}

class _EventConversationState extends State<EventConversation> {
  String? previousSender;
  int consecutiveMessageCount = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;
  TextEditingController messageController = TextEditingController();
  CollectionReference messagesCollection =
  FirebaseFirestore.instance.collection('eventMessages');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


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
                  return CircularProgressIndicator();
                }

                List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    var messageData = documents[index].data() as Map<String, dynamic>;
                    var isMyMessage = messageData['senderId'] == user?.uid;
                    String? sender = user?.uid;

                    return FutureBuilder<String?>(
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
                            timestamp: messageData['timestamp'], // Передайте время
                          );
                        } else {
                          print("Загрузка??");
                          // Возвращайте заглушку, пока Future не завершится
                          return Container(
                            // Здесь можете использовать, например, CircularProgressIndicator,
                            child: CircularProgressIndicator(),
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
                        decoration: InputDecoration(
                          hintText: 'Введите сообщение...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
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

    if (newMessage.isNotEmpty) {
      String senderName = await getSenderFirstName(sender!) ?? 'Аноним';

      await messagesCollection.doc(widget.eventId).collection('messages').add({
        'message': newMessage,
        'senderId': user?.uid,
        'senderName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      messageController.clear();
    }
  }
}


class MessageBubble extends StatelessWidget {
  final String message;
  final String senderName;
  final bool isMyMessage;
  final String senderId;
  final Timestamp timestamp; // Используйте Timestamp вместо String

  MessageBubble({
    required this.message,
    required this.senderName,
    required this.isMyMessage,
    required this.senderId,
    required this.timestamp,
  });

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
    return Column(
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
        SizedBox(height: 8.0), // Расстояние между сообщениями
        Row(
          mainAxisAlignment:
          isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
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
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMyMessage ? Colors.blue : Colors.green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                  bottomLeft:
                  isMyMessage ? Radius.circular(15) : Radius.circular(0),
                  bottomRight:
                  isMyMessage ? Radius.circular(0) : Radius.circular(15),
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
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    _formatTimestamp(timestamp.toDate()), // Отображение времени
                    style: TextStyle(
                      color: Colors.black,
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
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    // Реализуйте форматирование времени по вашему желанию
    // Например, можно использовать intl пакет: https://pub.dev/packages/intl
    // или другие подходящие методы для форматирования времени
    return DateFormat.yMMMd().add_jm().format(timestamp);
  }

}


