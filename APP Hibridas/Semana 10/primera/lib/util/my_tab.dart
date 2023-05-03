import 'package:flutter/material.dart';

class MyTap extends StatelessWidget {
  final String iconPath;
  final String nameIcon;

  const MyTap({super.key, required this.iconPath, required this.nameIcon});
  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 80,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(width: 1.0, color: Colors.black)),
            child: Image.asset(
              iconPath,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            nameIcon,
            style: TextStyle(color: Colors.black, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
