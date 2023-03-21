import 'package:carritocompras/grocery_product.dart';
import 'package:flutter/material.dart';

enum GroceryState {
  normal,
  details,
  cart,
}

class GroceryStoreBloc with ChangeNotifier {
  GroceryState groceryState = GroceryState.normal;
  List<GroceryProduct> catalog = List.unmodifiable(grpceryProducts);


  void changeToNormal() {
    groceryState = GroceryState.normal;
    notifyListeners();
  }

  void changeToCart() {
    groceryState = GroceryState.cart;
    notifyListeners();
  }
}
