import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //obtener los valores del form
  final formkey = GlobalKey<FormState>();
  String email = "";
  String password = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: formkey,
            child: Center(
                child: Column(
              children: [
                const SizedBox(
                  height: 50,
                ),
                Image.asset(
                  "assets/Logo.jpg",
                  height: 150,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Logeate para saber de que estan hablando",
                  style: TextStyle(fontSize: 15),
                ),
                Image.asset(
                  "assets/Login.jpg",
                  height: 150,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    
                  ),
                )
              ],
            )),
          ),
        ),
      ),
    );
  }
}
