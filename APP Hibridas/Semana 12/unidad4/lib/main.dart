import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:unidad4/firebase_options.dart';
import 'package:unidad4/helper/helper_funtion.dart';
import 'package:unidad4/pages/auth/login_page.dart';
import 'package:unidad4/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSignedIn = false;
  @override
  void initState() {
    super.initState();
    getUserLoggetInStatus();
  }

  getUserLoggetInStatus() async {
    await HelperFunction.getUserLoggedInStatus().then((value) {
      if (value != null) {
        _isSignedIn = value;
      }
    });
  }
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _isSignedIn ? HomePage() : LoginPage(),
    );
  }
}

