import 'package:flutter/material.dart';

class DonutTitle extends StatelessWidget {
  final String donutFlavor;
  final String donutPrice;
  final donutColor;
  final String imageName;

  DonutTitle(
      {super.key,
      required this.donutFlavor,
      required this.donutPrice,
      required this.donutColor,
      required this.imageName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(
            color: donutColor[50], borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            //Price
            Container(
              decoration: ,
              child: Text(donutPrice)
            ),
            //Picture
            Image.asset(
              imageName,
              height: 120,
            ),
            //Flavor
            Text(donutFlavor),
            Text(
              "Dunkin's",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            )
            //Love icon + add button
          ],
        ),
      ),
    );
  }
}
