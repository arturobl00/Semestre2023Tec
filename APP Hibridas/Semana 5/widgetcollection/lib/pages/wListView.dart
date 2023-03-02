import 'package:flutter/material.dart';

class WListView extends StatefulWidget {
  const WListView({super.key});

  @override
  State<WListView> createState() => _WListViewState();
}

class _WListViewState extends State<WListView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("List View"),
      ),
      body: ListView(
        // ignore: prefer_const_literals_to_create_immutables
        children: [
          const MyBlock(),
          const MyBlock(),
          const MyBlock(),
          const MyBlock(),
          const MyBlock(),
          const MyBlock(),
          const MyBlock(),
          const MyBlock(),
          const MyBlock(),
          const MyBlock(),
          const MyBlock(),
        ],
      ),
    );
  }
}

class MyBlock extends StatelessWidget {
  const MyBlock({super.key});

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
      ),
    );
  }
}
