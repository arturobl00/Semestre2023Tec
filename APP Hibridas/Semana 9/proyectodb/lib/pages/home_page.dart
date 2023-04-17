import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Hi Luisiño!",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "29/03/2023, Ajalpan Pue.",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 25,
            ),
            //Barra de Busqueda
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: const [
                  Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Search",
                    style: TextStyle(color: Colors.white),
                  )
                ],
              ),
            ),
            //How do you feel
            const SizedBox(
              height: 25,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "How do yo feel?",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white),
                ),
                Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                )
              ],
            ),
            //Emoticons
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Emoticons(myIcono: "😔", myTexto: "Badly"),
                Emoticons(myIcono: "☺️", myTexto: "Fine"),
                Emoticons(myIcono: "😁", myTexto: "Well"),
                Emoticons(myIcono: "🤩", myTexto: "Excellent"),
              ],
            ),
          ],
        ),
      )),
    );
  }
}

class Emoticons extends StatelessWidget {
  final String myIcono;
  final String myTexto;
  const Emoticons({super.key, required this.myIcono, required this.myTexto});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          color: Colors.blue[600],
          child: Text(myIcono),
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          myTexto,
          style: TextStyle(color: Colors.white),
        )
      ],
    );
  }
}
