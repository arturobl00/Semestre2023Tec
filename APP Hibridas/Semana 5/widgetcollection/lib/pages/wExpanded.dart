import 'package:flutter/material.dart';

class WExpanded extends StatelessWidget {
  const WExpanded({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Widget Expanded"),
      ),
      body: Column(
        children: [
          //El container se visualiza con height no con width
          Expanded(
            child: Container(
              color: Colors.purple,
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.red,
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
