import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize(BuildContext context, Function(RemoteMessage) onMessageReceived) async {
    // Note: Firebase.initializeApp() must be called in main.dart before this
    
    // Request permission for iOS/Android
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // Get the token and print it (or send to backend)
      String? token = await _firebaseMessaging.getToken();
      print("FCM Token: $token");
      // In production, send this token to FastAPI backend so it knows where to route alerts

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          onMessageReceived(message);
        }
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // Efficiently listen to the "incidents" node in Realtime DB
  Stream<DatabaseEvent> getIncidentsStream() {
    return FirebaseDatabase.instance.ref().child('incidents').onValue;
  }
}

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}
