import 'package:flutter/material.dart';
import 'package:chatflutter/screens/home_screen.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isAnimate = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 1,
        title: const Text("Welcome to My Messenger"),
      ),
      body: Stack(
        children: [
          AnimatedPositioned(
            top: _isAnimate ? mq.height * 0.10 : 0,
            left: mq.width * .25,
            duration: const Duration(seconds: 1),
            child: Image.asset('images/speak.png'),
            width: 200,
          ),
          Positioned(
              bottom: mq.height * 0.20,
              left: mq.width * 0.1,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()));
                },
                child: Container(
                  height: 70,
                  width: 330,
                  decoration: BoxDecoration(
                      color: Color.fromARGB(230, 117, 222, 121),
                      borderRadius: BorderRadius.circular(40)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('images/google.png'),
                        SizedBox(
                          width: 20,
                        ),
                        Text(
                          "Signin with Google",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        )
                      ],
                    ),
                  ),
                ),
              ))
        ],
      ),
    );
  }
}