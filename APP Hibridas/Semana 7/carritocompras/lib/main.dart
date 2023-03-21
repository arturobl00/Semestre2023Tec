import 'package:carritocompras/grocery_store_bloc.dart';
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

class GroceryStoreHome extends StatefulWidget {
  GroceryStoreHome({super.key});

  @override
  State<GroceryStoreHome> createState() => _GroceryStoreHomeState();
}

class _GroceryStoreHomeState extends State<GroceryStoreHome> {
  final _backgroundColor = Color.fromARGB(255, 206, 192, 150);

  final _cartBarHeight = 100.0;
  final _panelTransition = Duration(milliseconds: 500);

  final bloc = GroceryStoreBloc();
  void _onVerticalGesture(DragUpdateDetails details) {
    print(details.primaryDelta);
    if (details.primaryDelta! < -7) {
      bloc.changeToCart();
    } else if (details.primaryDelta! > 12) {
      bloc.changeToNormal();
    }
  }

  _getTopForWhitePanel(GroceryState state, Size size) {
    if (state == GroceryState.normal) {
      return -_cartBarHeight;
    } else if (state == GroceryState.cart) {
      return -(size.height - kToolbarHeight - _cartBarHeight / 2);
    }
  }

  _getTopForBlackPanel(GroceryState state, Size size) {
    if (state == GroceryState.normal) {
      return size.height - kToolbarHeight - _cartBarHeight;
    } else if (state == GroceryState.cart) {
      return _cartBarHeight / 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: bloc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                _AppBarGrocery(),
                Expanded(
                    child: Stack(
                  children: [
                    //White panel
                    AnimatedPositioned(
                      duration: _panelTransition,
                        left: 0,
                        right: 0,
                        top: _getTopForWhitePanel(bloc.groceryState, size),
                        height: size.height - kToolbarHeight,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                        )),
                    //Black panel
                    AnimatedPositioned(
                      duration: _panelTransition,
                        left: 0,
                        right: 0,
                        top: _getTopForBlackPanel(bloc.groceryState, size),
                        height: size.height - kToolbarHeight,
                        child: GestureDetector(
                          onVerticalDragUpdate: _onVerticalGesture,
                          child: Container(
                            color: Colors.black,
                          ),
                        ))
                  ],
                ))
              ],
            ),
          ),
        );
      },
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
