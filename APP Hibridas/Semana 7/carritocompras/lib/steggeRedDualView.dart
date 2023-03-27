import 'package:flutter/material.dart';

class StaggeRedDualView extends StatelessWidget {
  const StaggeRedDualView({
    Key? key,
    required this.itemBuilder,
    required this.itemCount,
  }) : super(key: key);

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemBuilder: itemBuilder,
    );
  }
}