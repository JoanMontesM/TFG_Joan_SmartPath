import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smartpath_app/firebase_options.dart';
import 'package:smartpath_app/screens/start_screen.dart';
import 'package:smartpath_app/screens/login_screen.dart';
import 'package:smartpath_app/screens/sign_screen.dart';
import 'package:smartpath_app/screens/student_home_screen.dart';
import 'package:smartpath_app/screens/teacher_home_screen.dart';
import 'package:smartpath_app/screens/add_content.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Application root
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => StartScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignScreen(),
        '/studenthome': (context) => StudentHomeScreen(),
        '/teacherhome': (context) => TeacherHomeScreen(),
        '/addcontent': (context) => AddContent(),
      },
    );
  }
}