import 'package:flutter/material.dart';
import 'package:interfaces3/modules/myDrawer.dart';

class Direccion extends StatelessWidget {
  const Direccion({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My APP Drawer"),
      ),
      drawer: Drawer(child: MyDrawer1()),
      body: Center(
        child: Text("Direccion"),
      ),
    );
  }
}