import 'package:flutter/material.dart';

import '../util/donut_title.dart';

// ignore: must_be_immutable
class TabDonut extends StatelessWidget {
  List donutsOnSale = [
    ["Ice Cream", "36", Colors.blue, "lib/images/icecream_donut.png"],
    ["Strawberry", "45", Colors.red, "lib/images/strawberry_donut.png"],
    ["Grape", "84", Colors.purple, "lib/images/grape_donut.png"],
    ["Chocolate", "95", Colors.brown, "lib/images/chocolate_donut.png"],
  ];

  TabDonut({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: donutsOnSale.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemBuilder: (context, index) {
        return DonutTitle(
          donutFlavor: donutsOnSale[index][0],
          donutPrice: donutsOnSale[index][1],
          donutColor: donutsOnSale[index][2],
          imageName: donutsOnSale[index][3],
        );
      },
    );
  }
}
