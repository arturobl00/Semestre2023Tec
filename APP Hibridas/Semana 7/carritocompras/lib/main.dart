import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GroceryStoreHome(),
    );
  }
}

class GroceryStoreHome extends StatelessWidget {
  const GroceryStoreHome({super.key});

  final _backgroundColor = const Color(0XFFF6F5F2);
  final _cartBarHeight = 120.0;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _AppBarGrocery(),
            Expanded(
                child: Stack(
              children: [
                Positioned(
                    left: 0,
                    right: 0,
                    top: -_cartBarHeight,
                    height: size.height - kToolbarHeight,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                    ))
              ],
            ))
          ],
        ),
      ),
    );
  }
}

class _AppBarGrocery extends StatelessWidget {
  const _AppBarGrocery({super.key});
  final _backgroundColor = const Color(0XFFF6F5F2);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      color: _backgroundColor,
      child: Row(
        children: [
          const BackButton(
            color: Colors.black,
          ),
          const SizedBox(
            width: 10.0,
          ),
          const Expanded(
              child: Text(
            "Fruits and Vegetables",
            style: TextStyle(color: Colors.black),
          )),
          IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.settings,
                color: Colors.black,
              )),
        ],
      ),
    );
  }
}
