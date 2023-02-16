import 'package:flutter/material.dart';
import 'package:interfaces3/pages/acercaDe.dart';
import 'package:interfaces3/pages/direccion.dart';
import 'package:interfaces3/pages/nosotros.dart';
import 'package:interfaces3/pages/promociones.dart';

class MyDrawer1 extends StatefulWidget {
  const MyDrawer1({super.key});

  @override
  State<MyDrawer1> createState() => _MyDrawer1State();
}

class _MyDrawer1State extends State<MyDrawer1> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Text("Hola mi APP"),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 5.0, right: 2.0, top: 10.0, bottom: 10.0),
          child: Row(
            children: [
              Icon(Icons.people_rounded),
              SizedBox(
                width: 10,
              ),
              //Usar la Navegacion
              GestureDetector(
                onTap: () {
                  //Codigo para navegar entre paginas
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) {
                    return const Nosotros();
                  }));
                },
                child: const Text(
                  "Nosotros",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 5.0, right: 2.0, top: 10.0, bottom: 10.0),
          child: Row(
            children: [
              Icon(Icons.ads_click_rounded),
              SizedBox(
                width: 10,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) {
                    return const Promociones();
                  }));
                },
                child: Text(
                  "Promociones",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 5.0, right: 2.0, top: 10.0, bottom: 10.0),
          child: Row(
            children: [
              Icon(Icons.assignment_ind_rounded),
              SizedBox(
                width: 10,
              ),
              GestureDetector(
                onTap: (() {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) {
                    return const AcercaDe();
                  }));
                }),
                child: Text(
                  "Acerca de",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 5.0, right: 2.0, top: 10.0, bottom: 10.0),
          child: Row(
            children: [
              Icon(Icons.map_rounded),
              SizedBox(
                width: 10,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) {
                    return const Direccion();
                  }));
                },
                child: Text(
                  "Dirección",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
