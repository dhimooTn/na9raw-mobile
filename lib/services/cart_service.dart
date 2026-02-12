// services/cart_service.dart
import 'package:flutter/foundation.dart';
import '/models/course_model.dart';

class CartService extends ChangeNotifier {
  // Singleton pattern
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CourseModel> _cartItems = [];

  List<CourseModel> get cartItems => List.unmodifiable(_cartItems);

  int get itemCount => _cartItems.length;

  double get totalPrice {
    return _cartItems.fold(0, (sum, item) => sum + item.price);
  }

  bool isInCart(String courseId) {
    return _cartItems.any((item) => item.id == courseId);
  }

  void addToCart(CourseModel course) {
    if (!isInCart(course.id)) {
      _cartItems.add(course);
      notifyListeners();
    }
  }

  void removeFromCart(String courseId) {
    _cartItems.removeWhere((item) => item.id == courseId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}