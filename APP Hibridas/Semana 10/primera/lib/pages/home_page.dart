import 'package:flutter/material.dart';
import 'package:primera/tabs/tabBurger.dart';
import 'package:primera/tabs/tabPizza.dart';
import 'package:primera/tabs/tabSmoothie.dart';
import 'package:primera/tabs/tabdonut.dart';
import 'package:primera/tabs/tabpancakes.dart';
import 'package:primera/util/my_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Widget> myTabs = const [
    //Donas
    MyTap(
      iconPath: 'lib/icons/donut.png',
      nameIcon: "Donut",
    ),
    //Burgers
    MyTap(
      iconPath: 'lib/icons/burger.png',
      nameIcon: "Burger",
    ),
    //Smoties
    MyTap(
      iconPath: 'lib/icons/smoothie.png',
      nameIcon: "Smoothie",
    ),
    //PanCake
    MyTap(
      iconPath: 'lib/icons/pancakes.png',
      nameIcon: "PanCakes",
    ),
    //Pizza
    MyTap(
      iconPath: 'lib/icons/pizza.png',
      nameIcon: "Pizza",
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: myTabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: IconButton(
              icon: Icon(
                Icons.menu,
                color: Colors.grey[800],
                size: 36,
              ),
              onPressed: () {},
            ),
          ),
          actions: [
            Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    Icons.person,
                    color: Colors.grey[800],
                    size: 36,
                  ),
                  onPressed: () {},
                )),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: Row(
                children: [
                  Text(
                    "I want to ",
                    style: TextStyle(fontSize: 30),
                  ),
                  Text(
                    "Eat",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            //TabBar creada elementos horizontales este se creo
            TabBar(tabs: myTabs),
            const SizedBox(
              height: 20,
            ),
            //TabBarView este es del api y es para cambiar entre pantallas
            //Muy Facil solo creas los archivos e importas
            Expanded(
                child: TabBarView(
              children: [
                //Donut
                TabDonut(),
                //Burger
                TabBurger(),
                //Smoothie
                TabSmoothies(),
                //PanCakes
                TabPanCakes(),
                //Pizza
                TabPizza(),
              ],
            ))
          ],
        ),
      ),
    );
  }
}
