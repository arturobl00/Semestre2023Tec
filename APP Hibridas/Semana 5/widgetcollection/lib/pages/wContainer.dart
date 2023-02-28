import 'package:flutter/material.dart';

class WContainer extends StatelessWidget {
  const WContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tipos de Container"),
      ),
      body: Center(
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.only(
                  top: 20, left: 100, right: 100, bottom: 20),
              //Cuando usamos la propiedad decoration el color lo debemos
              //bajar al BoxDecoration y el Container se debe quedar sin
              //esa propiedad
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.deepPurple,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.cyan,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 5,
                    color: Colors.black,
                  )),
              child: const CircleAvatar(
                backgroundImage: AssetImage('assets/imagen.jpg'),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(
                  top: 20, left: 100, right: 100, bottom: 20),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 5,
                  color: Colors.red,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Text(
                  "MiTexto",
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(
                  top: 20, left: 100, right: 100, bottom: 20),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade500,
                      offset: const Offset(4.0, 4.0),
                      blurRadius: 15.0,
                      spreadRadius: 1.0),
                  const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-4.0, -4.0),
                      blurRadius: 15.0,
                      spreadRadius: 1.0)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}