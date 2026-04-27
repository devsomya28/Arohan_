import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'viewmodels/guest_viewmodel.dart';
import 'viewmodels/staff_viewmodel.dart';
import 'views/staff_home_view.dart';
import 'views/login_view.dart';
import 'views/guest_home_view.dart';
import 'views/analytics_view.dart';
import 'services/sos_capture_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase Initialization (Web-Safe)
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAt8JlqmYdfHOQIGyzIbMex7Gdhe4OcbaE",
        appId: "1:337987572890:web:74b210a78640d42ce8fb23",
        messagingSenderId: "337987572890",
        projectId: "aarohan-new",
        databaseURL: "https://aarohan-new-default-rtdb.firebaseio.com",
        storageBucket: "aarohan-new.firebasestorage.app",
      ),
    );
    print("Firebase Initialized Successfully");
    
  } catch (e) {
    print("Firebase Initialization Failed: $e");
    // App will continue with demo data
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GuestViewModel()),
        ChangeNotifierProvider(create: (_) => StaffViewModel()),
      ],
      child: const CrisisApp(),
    ),
  );
}

class CrisisApp extends StatelessWidget {
  const CrisisApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AAROHAN AI AOCC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        fontFamily: 'Inter',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginView(),
        '/guest': (context) => GuestHomeView(),
        '/staff': (context) => StaffHomeView(),
        '/analytics': (context) => AnalyticsView(),
      },
    );
  }
}
