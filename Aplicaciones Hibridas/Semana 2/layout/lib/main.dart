// ignore_for_file: avoid_unnecessary_containers

import 'package:flutter/material.dart';

void main() {
  runApp(const Interface2());
}

class Interface extends StatelessWidget {
  const Interface({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(Icons.call),
                    Container(
                      child: const Text("CALL"),
                    )
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.route),
                    Container(
                      child: const Text("ROUTE"),
                    )
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.share),
                    Container(
                      child: const Text("SHARE"),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Interface2 extends StatelessWidget {
  const Interface2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  width: 225,
                  height: 400,
                  color: Colors.amber,
                  child: Column(
                    children: [
                      Container(
                        width: 220,
                        height: 50,
                        color: Colors.black12,
                        child: const Center(
                          child: Text(
                            "Strawbarry Pavlova",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      ),
                      Container(
                        width: 220,
                        height: 200,
                        color: Colors.black26,
                        child: const Center(
                          child: Text(
                            "Se llama Pavlova en honor a la bailarina de ballet "
                            "Anna Pavlova. Según escribe el biógrafo de la bailarina, "
                            "cuando ésta se encontraba en su gira mundial de 1926, "
                            "durante su estadía en Nueva Zelanda, el chef del hotel "
                            "donde Ana Pavlova se hospedaba inventó este postre para "
                            "sorprender a la bailarina.",
                            style: TextStyle(fontSize: 15),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ),
                      Container(
                        width: 220,
                        height: 40,
                        color: Colors.black38,
                        child: Center(
                            child: Row(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 15,
                                ),
                                const Icon(
                                  Icons.star,
                                  size: 15,
                                ),
                                const Icon(
                                  Icons.star,
                                  size: 15,
                                ),
                                const Icon(
                                  Icons.star,
                                  size: 15,
                                ),
                                const Icon(
                                  Icons.star,
                                  size: 15,
                                ),
                                Container(
                                    padding: const EdgeInsets.only(left: 60),
                                    child: const Text("170 Reviews"))
                              ],
                            )
                          ],
                        )),
                      ),
                      Container(
                        width: 220,
                        height: 70,
                        color: Colors.black45,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: const[
                                Icon(Icons.ac_unit),
                                Text("PREP."),
                                Text("25 min")
                              ],
                            ),
                            Column(
                              children: const[
                                Icon(Icons.abc_outlined),
                                Text("PREP."),
                                Text("12 min")
                              ],
                            ),
                            Column(
                              children: const[
                                Icon(Icons.access_alarm_outlined),
                                Text("PREP."),
                                Text("09 min")
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  width: 505,
                  height: 400,
                  color: Colors.blue,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
