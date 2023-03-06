import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyGrid(),
    );
  }
}

class MyGrid extends StatelessWidget {
  const MyGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Usando GRID"),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          MiCuadro(),
          MiCuadro(),
        ],
      ),
    );
  }
}

class MiCuadro extends StatelessWidget {
  const MiCuadro({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Wartortle",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
            Image.asset(
              "assets/008.png",
              height: 100,
              width: 100,
            ),
            Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // ignore: prefer_const_literals_to_create_immutables
                  children: [
                    const Text(
                      "Altura",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text("1,0 m")
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      "Categoria",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("Tortuga")
                  ],
                )
              ],
            ),
            Row(
              children: [
                Column(
                  children: const [
                    Text(
                      "Peso",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("22.5 kg")
                  ],
                ),
                Column(
                  children: const [
                    Text(
                      "Habilidad",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("Torrente")
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
