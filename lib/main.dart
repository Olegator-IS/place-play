import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:placeandplay/WelcomeScreens/LoginPage.dart';
import 'package:placeandplay/RegistrationScreens/RegistrationPage.dart';
import 'EmptyScreen.dart';
import 'PresenceService.dart';
import 'Services/FirebaseMessagingService.dart';
import 'WelcomeScreens/HelloLayout.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
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
