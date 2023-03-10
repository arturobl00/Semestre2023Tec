import 'package:flutter/material.dart';
import 'package:widgetcollection/pages/wColumRow.dart';
import 'package:widgetcollection/pages/wContainer.dart';
import 'package:widgetcollection/pages/wExpanded.dart';
import 'package:widgetcollection/pages/wListBContainer.dart';
import 'package:widgetcollection/pages/wListBuilder.dart';
import 'package:widgetcollection/pages/wListView.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: WListViewBC());
  }
}
