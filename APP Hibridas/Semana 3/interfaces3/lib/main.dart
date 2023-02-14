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
        home: MyDrawer());
  }
}

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My APP Drawer"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text("Hola mi APP"),
            ),
            Container(
              color: Colors.amber,
              child: Text("Nosotros"),
            ),
            Container(
              color: Colors.blue,
              child: Text("Ustedes"),
            ),
            Container(
              color: Colors.cyan,
              child: Text("Ellos"),
            ),
            ListTile(
              title: Container(
                  height: 50,
                  color: Colors.deepOrange,
                  child: const Text('Item 1')),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: Container(
                  height: 50,
                  color: Colors.blueAccent,
                  child: const Text('Item 2')),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            Container(
              color: Colors.amber,
              child: Text("Nosotros"),
            ),
            Container(
              color: Colors.blue,
              child: Text("Ustedes"),
            ),
            Container(
              color: Colors.cyan,
              child: Text("Ellos"),
            ),
            ListTile(
              title: Container(
                  height: 50,
                  color: Colors.deepOrange,
                  child: const Text('Item 1')),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: Container(
                  height: 50,
                  color: Colors.blueAccent,
                  child: const Text('Item 2')),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            Container(
              color: Colors.amber,
              child: Text("Nosotros"),
            ),
            Container(
              color: Colors.blue,
              child: Text("Ustedes"),
            ),
            Container(
              color: Colors.cyan,
              child: Text("Ellos"),
            ),
            ListTile(
              title: Container(
                  height: 50,
                  color: Colors.deepOrange,
                  child: const Text('Item 1')),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: Container(
                  height: 50,
                  color: Colors.blueAccent,
                  child: const Text('Item 2')),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            Container(
              color: Colors.amber,
              child: Text("Nosotros"),
            ),
            Container(
              color: Colors.blue,
              child: Text("Ustedes"),
            ),
            Container(
              color: Colors.cyan,
              child: Text("Ellos"),
            ),
            ListTile(
              title: Container(
                  height: 50,
                  color: Colors.deepOrange,
                  child: const Text('Item 1')),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: Container(
                  height: 50,
                  color: Colors.blueAccent,
                  child: const Text('Item 2')),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            Container(
              color: Colors.amber,
              child: Text("Nosotros"),
            ),
            Container(
              color: Colors.blue,
              child: Text("Ustedes"),
            ),
            Container(
              color: Colors.cyan,
              child: Text("Ellos"),
            ),
            ListTile(
              title: Container(
                  height: 50, color: Colors.green, child: const Text('Item 1')),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: Container(
                  height: 50, color: Colors.green, child: const Text('Item 2')),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
          ],
        ),
      ),
      body: MyContent(),
    );
  }
}

class MyContent extends StatefulWidget {
  const MyContent({super.key});

  @override
  State<MyContent> createState() => _MyContentState();
}

class _MyContentState extends State<MyContent> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Cualquier Cosa"),
          Text("Mientras se me ocurre algo"),
          Text("y espero a que pase"),
        ],
      ),
    );
  }
}
