import 'package:flutter/material.dart';

class WListViewB extends StatelessWidget {
  WListViewB({super.key});

  final List _post = [
    'Mi Contenido 1',
    'Mi Contenido 2',
    'Mi Contenido 3',
    'Mi Contenido 4',
    'Mi Contenido 5',
    'Mi Contenido 6',
    'Mi Contenido 7',
    'Mi Contenido 8',
    'Mi Contenido 9',
    'Mi Contenido 10',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("List View"),
        ),
        body: ListView.builder(
            itemCount: _post.length,
            itemBuilder: (context, index) {
              return MyBlock1(
                child: _post[index],
              );
            }));
  }
}

class MyBlock1 extends StatelessWidget {
  final String child;
  const MyBlock1({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.deepPurple,
        ),
        child: Center(
            child: Text(
          child,
          style: TextStyle(fontSize: 20),
        )),
      ),
    );
  }
}
