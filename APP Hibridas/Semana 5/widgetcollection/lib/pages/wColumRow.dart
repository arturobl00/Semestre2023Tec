import 'package:flutter/material.dart';

class WColumRow extends StatelessWidget {
  const WColumRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Columns and Rows"),
      ),
      body: Column(
        children: [
          Column(
            //Alinea de forma vertical
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 500,
                height: 100,
                color: Colors.purple,
              ),
              Container(
                width: 300,
                height: 100,
                color: Colors.purple[400],
              ),
              Container(
                width: 200,
                height: 100,
                color: Colors.purple[200],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 100,
                height: 200,
                color: Colors.purple[600],
              ),
              Container(
                width: 100,
                height: 200,
                color: Colors.purple[400],
              ),
              Container(
                width: 100,
                height: 200,
                color: Colors.purple[200],
              ),
            ],
          )
        ],
      ),
    );
  }
}
