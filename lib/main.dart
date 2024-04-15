import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:placeandplay/WelcomeScreens/LoginPage.dart';
import 'package:placeandplay/RegistrationScreens/RegistrationPage.dart';
import 'package:permission_handler/permission_handler.dart';

import 'EmptyScreen.dart';
import 'PresenceService.dart';
import 'Services/FirebaseMessagingService.dart';
import 'WelcomeScreens/HelloLayout.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:audioplayers/audioplayers.dart';


final audioCache = AudioCache();
const audioFilePath = 'audio/swipe.mp3';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  print('Тут по любому пришло что-нибудь');
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');

    print("Received message: ${message.notification?.title}");
    // if(message.notification?.tit)
    // Отобразите уведомление
    displayNotification(message);
    String? messageBody = message.notification?.body.toString();
    String? messageTitle = message.notification?.title.toString();
    print('message title $messageTitle');
    print('message body $messageBody');
  });

  FirebaseMessaging.onBackgroundMessage((message) async {
    print("Handling background message: ${message.notification?.title}");
    String? messageBody = message.notification?.body.toString();
    String? messageTitle = message.notification?.title.toString();
    print('Сообщение в фоне message title $messageTitle');
    print('Сообщение в фоне message body $messageBody');

    // Вызов функции для обработки уведомления в фоновом режиме
    // await showNotificationOrPerformActionInBackground(message);
  });



  // Инициализация FlutterLocalNotificationsPlugin
  const AndroidInitializationSettings androidInitializationSettings =
  AndroidInitializationSettings('app_icon');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
  );
  print('Может быть тут?');
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  try {
    await FirebaseAppCheck.instance.activate(webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.appAttest);
  }catch (e) {
    print('Error activating App Check: $e');
  }
  runApp(MyApp());
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();



void displayNotification(RemoteMessage message) async {
  String sound = message.data['sound'];
  print('Sound $sound');
  playNotificationSound(sound); // Кастомный звук из параметра 'audioFilePath'
  //
  var android = AndroidNotificationDetails(
    'default_channel_id',
    'Default Chanel',
    importance: Importance.max,
    priority: Priority.high,
    playSound: false,
  );
  //
  //

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title,
    message.notification?.body,
    NotificationDetails(android: android),
    payload: 'Custom_Sound',
  );


}

Future<void> playNotificationSound(String sound) async {
  await audioCache.play(sound);
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {


    return MaterialApp(
      title: 'Place and Play',
      home: HelloLayout(),
      routes: {
        '/LoginPage': (context) => LoginPage(),
        '/Hello': (context) => HelloLayout(),
        '/forgot_password': (context) => EmptyScreen(),
        '/Registration': (context) => RegistrationPage(),
      },
      builder: (context, child) {
        return _AppStateTracker(child: child!);
      },
    );
  }
}

class _AppStateTracker extends StatefulWidget {
  final Widget child;

  const _AppStateTracker({Key? key, required this.child}) : super(key: key);

  @override
  _AppStateTrackerState createState() => _AppStateTrackerState();
}

class _AppStateTrackerState extends State<_AppStateTracker> with WidgetsBindingObserver {
  bool _isOnline = true; // Начальный статус "онлайн"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);

  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        setOnlineStatus(true);
        print('COME BACKKKKKKKKKKKKKKKKKK');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        setOnlineStatus(false);
        print('FALL ASLEEP');
        break;
    }
  }




  Future<void> setOnlineStatus(bool isOnline) async {
    setState(() {
      _isOnline = isOnline;
    });

    // Обновите статус "онлайн" с использованием вашего сервиса онлайн-присутствия
    // Пример: updateOnlineStatus(isOnline);

    // Обновление значка приложения, используя flutter_app_badger
    PresenceService presenceService = PresenceService();
    String userId = getUserId();


    if(_isOnline){
      await PresenceService.setUserOnline(userId);
    }else{
      await PresenceService.setUserOfflineAndUpdateLastOnline(userId);
    }


    FlutterAppBadger.updateBadgeCount(1); // Просто пример, вы можете использовать свою логику для обновления значка
  }

  static String getUserId() {
    // Здесь вы должны вернуть текущий userId, возможно, из вашего сервиса аутентификации
    // Например, используя FirebaseAuth.instance.currentUser?.uid
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
