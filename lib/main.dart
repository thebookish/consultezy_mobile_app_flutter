// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:consultezy/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

FutureOr<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      name: 'consultezy',
      options: FirebaseOptions(
        apiKey: 'AIzaSyAreHE1SyIj3t0ZYNSKhxNT2LV02oBeOfs',
        appId: '1:971948215829:android:2f24fb60634a907114c81c',
        messagingSenderId: '971948215829',
        projectId: 'consultezy-4703c',
      ));
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  } else {}
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primaryColor: Colors.blue, // example primary color
          // other theme configurations
        ),
        debugShowCheckedModeBanner: false,
        title: 'My App',
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(),
        });
  }
}
